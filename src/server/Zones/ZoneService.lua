--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Zones      = require(ReplicatedStorage.Shared.Config.Zones)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SyncZones = Instance.new("RemoteEvent")
SyncZones.Name   = "SyncZones"
SyncZones.Parent = Remotes

-- Notification textuelle courte (erreur déblocage, confirmation, etc.)
local SystemMessage = Instance.new("RemoteEvent")
SystemMessage.Name   = "SystemMessage"
SystemMessage.Parent = Remotes

local ZoneService = {}

-- Utilitaires ---------------------------------------------------------------

local function isZoneUnlocked(player: Player, zoneName: string): boolean
	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	for _, z in profile.Data.unlockedZones do
		if z == zoneName then return true end
	end
	return false
end

local function doSync(player: Player)
	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return end
	SyncZones:FireClient(player, profile.Data.unlockedZones)
end

-- Création des portes -------------------------------------------------------

local touchCooldowns: { [number]: boolean } = {}

local function setupGate(zoneName: string, zoneCfg: any, zoneFolder: Folder)
	local gate = zoneFolder:FindFirstChild("Gate")
	if not gate or not gate:IsA("BasePart") then
		warn("[ZoneService] Workspace.Zones." .. zoneName .. ".Gate introuvable (BasePart attendu).")
		return
	end
	local gatePart = gate :: BasePart
	gatePart.Anchored    = true
	gatePart.CanCollide  = true
	gatePart.Transparency = 0
	gatePart.Material    = Enum.Material.SmoothPlastic
	gatePart.Color       = Color3.fromRGB(60, 20, 90)

	-- BillboardGui -------------------------------------------------------
	local existingGui = gatePart:FindFirstChildWhichIsA("BillboardGui") :: BillboardGui?
	if existingGui then existingGui:Destroy() end

	local gui           = Instance.new("BillboardGui")
	gui.Size            = UDim2.new(0, 280, 0, 110)
	gui.StudsOffset     = Vector3.new(0, gatePart.Size.Y * 0.5 + 2, 0)
	gui.AlwaysOnTop     = false
	gui.MaxDistance     = 60
	gui.Parent          = gatePart

	local zoneLbl                   = Instance.new("TextLabel")
	zoneLbl.Size                    = UDim2.new(1, 0, 0.36, 0)
	zoneLbl.BackgroundTransparency  = 1
	zoneLbl.TextColor3              = Color3.fromRGB(255, 200, 50)
	zoneLbl.TextScaled              = true
	zoneLbl.Font                    = Enum.Font.GothamBold
	zoneLbl.Text                    = "🔒 " .. zoneCfg.displayName
	zoneLbl.Parent                  = gui

	local costLbl                   = Instance.new("TextLabel")
	costLbl.Size                    = UDim2.new(1, 0, 0.27, 0)
	costLbl.Position                = UDim2.new(0, 0, 0.37, 0)
	costLbl.BackgroundTransparency  = 1
	costLbl.TextColor3              = Color3.fromRGB(255, 220, 100)
	costLbl.TextScaled              = true
	costLbl.Font                    = Enum.Font.Gotham
	costLbl.Text                    = zoneCfg.goldsCost .. " golds"
	costLbl.Parent                  = gui

	local levelLbl                  = Instance.new("TextLabel")
	levelLbl.Size                   = UDim2.new(1, 0, 0.27, 0)
	levelLbl.Position               = UDim2.new(0, 0, 0.70, 0)
	levelLbl.BackgroundTransparency = 1
	levelLbl.TextColor3             = Color3.fromRGB(180, 180, 255)
	levelLbl.TextScaled             = true
	levelLbl.Font                   = Enum.Font.Gotham
	levelLbl.Text                   = "Niv. " .. zoneCfg.levelRequired .. " requis"
	levelLbl.Parent                 = gui

	-- ProximityPrompt (déblocage) ----------------------------------------
	local existingPP = gatePart:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt?
	if existingPP then existingPP:Destroy() end

	local prompt               = Instance.new("ProximityPrompt")
	prompt.ActionText          = "Débloquer"
	prompt.ObjectText          = zoneCfg.displayName .. " — " .. zoneCfg.goldsCost .. " g / Niv." .. zoneCfg.levelRequired
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration        = 0.6
	prompt.Parent              = gatePart

	prompt.Triggered:Connect(function(player: Player)
		local profile = PlayerData.GetProfile(player)
		if not profile or not profile:IsActive() then return end
		local data = profile.Data

		-- Déjà débloqué
		for _, z in data.unlockedZones do
			if z == zoneName then return end
		end

		-- Vérifications
		if data.level < (zoneCfg.levelRequired :: number) then
			SystemMessage:FireClient(player,
				"❌ Niveau " .. zoneCfg.levelRequired .. " requis (tu es niv. " .. data.level .. ")")
			return
		end
		if data.golds < (zoneCfg.goldsCost :: number) then
			SystemMessage:FireClient(player,
				"❌ " .. zoneCfg.goldsCost .. " golds requis (tu as " .. math.floor(data.golds) .. " g)")
			return
		end

		data.golds -= zoneCfg.goldsCost :: number
		table.insert(data.unlockedZones, zoneName)
		doSync(player)
		SystemMessage:FireClient(player, "✅ " .. zoneCfg.displayName .. " débloquée !")
	end)

	-- Anti-cheat : Touched -----------------------------------------------
	-- Détermine le côté "sûr" : opposé à la direction du RollStation de la zone.
	-- L'utilisateur doit orienter le RollStation à l'INTÉRIEUR de la zone.
	local function kickPlayer(player: Player)
		if touchCooldowns[player.UserId] then return end
		touchCooldowns[player.UserId] = true

		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local station = zoneFolder:FindFirstChild("RollStation") :: BasePart?
				local dirToZone: Vector3
				if station and station:IsA("BasePart") then
					dirToZone = (station.Position - gatePart.Position).Unit
				else
					dirToZone = gatePart.CFrame.LookVector
				end
				-- Côté sûr = opposé à la zone
				local safePos = gatePart.Position - dirToZone * (gatePart.Size.Z * 0.5 + 5)
				hrp.CFrame = CFrame.new(safePos + Vector3.new(0, 4, 0))
			end
		end

		task.delay(1.2, function()
			touchCooldowns[player.UserId] = nil
		end)
	end

	gatePart.Touched:Connect(function(hit: BasePart)
		local char = hit.Parent
		if not char then return end
		local player = Players:GetPlayerFromCharacter(char :: Model)
		if not player then return end
		if isZoneUnlocked(player, zoneName) then return end
		kickPlayer(player)
	end)
end

-- Initialisation ------------------------------------------------------------

task.spawn(function()
	local zonesFolder = workspace:WaitForChild("Zones", 10) :: Folder?
	if not zonesFolder then
		warn("[ZoneService] Workspace.Zones introuvable.")
		return
	end

	for zoneName, zoneCfg in Zones do
		if (zoneCfg.goldsCost :: number) == 0 then continue end -- Prairie, pas de porte
		local zoneFolder = zonesFolder:FindFirstChild(zoneName) :: Folder?
		if not zoneFolder then
			warn("[ZoneService] Workspace.Zones." .. zoneName .. " introuvable — ajoute le dossier dans Studio.")
			continue
		end
		setupGate(zoneName, zoneCfg, zoneFolder)
	end
end)

-- API -----------------------------------------------------------------------

function ZoneService.IsUnlocked(player: Player, zoneName: string): boolean
	return isZoneUnlocked(player, zoneName)
end

function ZoneService.OnPlayerAdded(player: Player)
	task.delay(0.7, function()
		doSync(player)
	end)
end

return ZoneService
