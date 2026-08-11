--!strict
local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData     = require(script.Parent.Parent.Data.PlayerData)
local PetService     = require(script.Parent.Parent.Pets.PetService)
local StatCalculator = require(script.Parent.Parent.Skills.StatCalculator)
local Rarities       = require(ReplicatedStorage.Shared.Config.Rarities)
local Pets           = require(ReplicatedStorage.Shared.Config.Pets)

local ROLL_COST        = 25
local STATION_MAX_DIST = 40  -- studs max pour auto-roll via RemoteFunction

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- RollEgg : pour l'auto-roll (client envoie zoneName, serveur valide position)
local RollEgg = Instance.new("RemoteFunction")
RollEgg.Name   = "RollEgg"
RollEgg.Parent = Remotes

-- RollResult : résultat d'un roll déclenché par ProximityPrompt
local RollResult = Instance.new("RemoteEvent")
RollResult.Name   = "RollResult"
RollResult.Parent = Remotes

-- Utilitaires ---------------------------------------------------------------

local function pickRarity(luck: number): string
	local r = math.random()
	local L = math.max(1, luck)
	if     r < Rarities.Secret.probability    * L then return "Secret"
	elseif r < Rarities.Mythic.probability    * L then return "Mythic"
	elseif r < Rarities.Legendary.probability * L then return "Legendary"
	elseif r < Rarities.Epic.probability      * L then return "Epic"
	elseif r < Rarities.Rare.probability      * L then return "Rare"
	elseif r < Rarities.Uncommon.probability     then return "Uncommon"
	else return "Common" end
end

local function pickPet(rarity: string, zone: string): string?
	local pool: { string } = {}
	for id, pet in Pets do
		if pet.rarity == rarity and pet.zone == zone then
			pool[#pool + 1] = id
		end
	end
	return if #pool > 0 then pool[math.random(#pool)] else nil
end

local function isZoneUnlocked(player: Player, zoneName: string): boolean
	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	for _, z in profile.Data.unlockedZones do
		if z == zoneName then return true end
	end
	return false
end

local function getStation(zoneName: string): BasePart?
	local zonesFolder = workspace:FindFirstChild("Zones") :: Folder?
	if not zonesFolder then return nil end
	local zoneFolder = zonesFolder:FindFirstChild(zoneName) :: Folder?
	if not zoneFolder then return nil end
	local s = zoneFolder:FindFirstChild("RollStation")
	return if s and s:IsA("BasePart") then (s :: BasePart) else nil
end

local function isNearStation(player: Player, zoneName: string): boolean
	local char = player.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end
	local station = getStation(zoneName)
	if not station then return false end
	return (hrp.Position - station.Position).Magnitude <= STATION_MAX_DIST
end

-- Logique de roll -----------------------------------------------------------
-- skipPositionCheck = true uniquement depuis ProximityPrompt (déjà validé par Roblox)
local function Roll(player: Player, zoneName: string, skipPositionCheck: boolean?): { any }?
	if not isZoneUnlocked(player, zoneName) then return nil end
	if not skipPositionCheck and not isNearStation(player, zoneName) then return nil end

	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return nil end

	local data       = profile.Data
	local stats      = StatCalculator.getStats(data.skillTreeGolds, data.skillTreePrestige)
	local rollCount  = if stats.multiRollUnlocked then 3 else 1
	local totalCost  = ROLL_COST * rollCount

	if data.golds < totalCost then return nil end

	data.golds      -= totalCost
	data.totalRolls += rollCount

	local results: { any } = {}

	for _ = 1, rollCount do
		local rarity = pickRarity(stats.luck)
		local petId  = pickPet(rarity, zoneName)

		if not petId then
			data.golds      += ROLL_COST
			data.totalRolls -= 1
			continue
		end

		local shiny = math.random() < Rarities.SHINY_CHANCE
		local entry = {
			uuid   = HttpService:GenerateGUID(false),
			id     = petId,
			rarity = rarity,
			stars  = 0,
			shiny  = shiny,
		}
		table.insert(data.inventory, entry)
		table.insert(results, entry)
	end

	if #results == 0 then return nil end

	PetService.Sync(player)
	return results
end

-- Auto-roll via RemoteFunction ----------------------------------------------
RollEgg.OnServerInvoke = function(player: Player, zoneName: unknown): { any }?
	if typeof(zoneName) ~= "string" then return nil end
	return Roll(player, zoneName :: string, false)
end

-- ProximityPrompts sur les RollStations -------------------------------------
local rollCooldowns: { [number]: boolean } = {}

task.spawn(function()
	local zonesFolder = workspace:WaitForChild("Zones", 10) :: Folder?
	if not zonesFolder then
		warn("[RollService] Workspace.Zones introuvable.")
		return
	end

	-- Scan initial + écoute les ajouts futurs (au cas où un dossier se crée après)
	local function setupStation(zoneFolder: Folder)
		local zoneName = zoneFolder.Name
		local station  = zoneFolder:WaitForChild("RollStation", 5) :: Instance?
		if not station or not station:IsA("BasePart") then
			warn("[RollService] RollStation manquant dans Workspace.Zones." .. zoneName .. " (BasePart attendu).")
			return
		end
		local stationPart = station :: BasePart

		local existingPP = stationPart:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt?
		if existingPP then existingPP:Destroy() end

		local prompt               = Instance.new("ProximityPrompt")
		prompt.ActionText          = "Rouler"
		prompt.ObjectText          = "Œuf " .. zoneName .. " — " .. ROLL_COST .. " g"
		prompt.MaxActivationDistance = 8
		prompt.HoldDuration        = 0.2
		prompt.Parent              = stationPart

		prompt.Triggered:Connect(function(player: Player)
			if rollCooldowns[player.UserId] then return end
			rollCooldowns[player.UserId] = true

			local results = Roll(player, zoneName, true)
			if results then
				RollResult:FireClient(player, results)
			end

			task.delay(0.4, function()
				rollCooldowns[player.UserId] = nil
			end)
		end)
	end

	for _, child in zonesFolder:GetChildren() do
		if child:IsA("Folder") then
			task.spawn(setupStation, child :: Folder)
		end
	end
	zonesFolder.ChildAdded:Connect(function(child)
		if child:IsA("Folder") then
			task.spawn(setupStation, child :: Folder)
		end
	end)
end)

return {}
