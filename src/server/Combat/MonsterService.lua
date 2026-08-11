--!strict
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData     = require(script.Parent.Parent.Data.PlayerData)
local StatCalculator = require(script.Parent.Parent.Skills.StatCalculator)
local Monsters       = require(ReplicatedStorage.Shared.Config.Monsters)
local Pets           = require(ReplicatedStorage.Shared.Config.Pets)
local Rarities       = require(ReplicatedStorage.Shared.Config.Rarities)
local Fusion         = require(ReplicatedStorage.Shared.Config.Fusion)
local Leveling       = require(ReplicatedStorage.Shared.Config.Leveling)

local COMBAT_RANGE   = 15
local ATTACK_RATE    = 1
local RESPAWN_NORMAL = 5
local NORMAL_SIZE    = Vector3.new(4, 4, 4)
local BOSS_SIZE      = Vector3.new(8, 8, 8)

-- Remotes -------------------------------------------------------------------
local Remotes     = ReplicatedStorage:WaitForChild("Remotes")

local ShowDamage  = Instance.new("RemoteEvent")
ShowDamage.Name   = "ShowDamage"
ShowDamage.Parent = Remotes

local PetAttack   = Instance.new("RemoteEvent")
PetAttack.Name    = "PetAttack"
PetAttack.Parent  = Remotes

local SyncStats   = Instance.new("RemoteEvent")
SyncStats.Name    = "SyncStats"
SyncStats.Parent  = Remotes

-- Types ---------------------------------------------------------------------
type MonsterData = {
	part:         BasePart,
	hp:           number,
	maxHp:        number,
	cfg:          any,
	zone:         string,
	spawnPart:    BasePart,
	contributors: { [number]: number },
	dead:         boolean,
}

local activeMonsters: { MonsterData } = {}

-- Helpers -------------------------------------------------------------------
local function xpForLevel(level: number): number
	return math.max(1, math.round(Leveling.XP_BASE * (level ^ Leveling.XP_EXPONENT)))
end

local function findPet(inventory: { any }, uuid: string): any?
	for _, pet in inventory do
		if pet.uuid == uuid then return pet end
	end
	return nil
end

local function calcPetDamage(entry: any): number
	local petCfg    = Pets[entry.id]
	local rarityCfg = Rarities[entry.rarity]
	if not petCfg or not rarityCfg then return 0 end
	local base        = petCfg.baseDamage * rarityCfg.damageMult
	local fusionEntry = if entry.stars > 0 then Fusion.Stars[entry.stars - 1] else nil
	local starsMult   = if fusionEntry then fusionEntry.cumulative else 1
	local shinyMult   = if entry.shiny then (Rarities.SHINY_STATS_MULT :: number) else 1
	return math.floor(base * starsMult * shinyMult)
end

local function getGoldsMult(data: any): number
	local mult = 0
	for _, uuid in data.equippedPets do
		local entry = findPet(data.inventory, uuid)
		if entry then
			local petCfg = Pets[entry.id]
			if petCfg then mult += petCfg.goldsMult end
		end
	end
	return math.max(1, mult)
end

local function updateHPBar(monster: MonsterData)
	local gui    = monster.part:FindFirstChildWhichIsA("BillboardGui") :: BillboardGui?
	if not gui then return end
	local hpBg   = gui:FindFirstChild("HPBg")   :: Frame?
	if not hpBg  then return end
	local hpFill = hpBg:FindFirstChild("HPFill") :: Frame?
	if not hpFill then return end

	local ratio = math.clamp(monster.hp / monster.maxHp, 0, 1)
	hpFill.Size = UDim2.new(ratio, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(
		math.floor((1 - ratio) * 230),
		math.floor(ratio * 200 + 20),
		0
	)
end

-- Spawn ---------------------------------------------------------------------
local function spawnMonster(cfg: any, spawnPart: BasePart, zoneName: string): MonsterData
	local size = if cfg.isBoss then BOSS_SIZE else NORMAL_SIZE

	local part          = Instance.new("Part")
	part.Name           = cfg.name
	part.Size           = size
	part.Anchored       = true
	part.CanCollide     = true
	part.Position       = spawnPart.Position + Vector3.new(0, size.Y * 0.5, 0)
	part.Color          = if cfg.isBoss then Color3.fromRGB(180, 30, 30) else Color3.fromRGB(70, 160, 70)
	part.Material       = Enum.Material.SmoothPlastic
	part.CastShadow     = true
	part.Parent         = workspace

	local gui           = Instance.new("BillboardGui")
	gui.Size            = UDim2.new(0, 180, 0, 56)
	gui.StudsOffset     = Vector3.new(0, size.Y * 0.5 + 1.2, 0)
	gui.AlwaysOnTop     = false
	gui.Parent          = part

	local nameLbl                   = Instance.new("TextLabel")
	nameLbl.Name                    = "NameLabel"
	nameLbl.Size                    = UDim2.new(1, 0, 0.48, 0)
	nameLbl.BackgroundTransparency  = 1
	nameLbl.TextColor3              = if cfg.isBoss
		then Color3.fromRGB(255, 130, 0)
		else Color3.fromRGB(255, 255, 255)
	nameLbl.TextScaled              = true
	nameLbl.Font                    = Enum.Font.GothamBold
	nameLbl.Text                    = (if cfg.isBoss then "⚡ " else "") .. cfg.name
	nameLbl.Parent                  = gui

	local hpBg              = Instance.new("Frame")
	hpBg.Name               = "HPBg"
	hpBg.Size               = UDim2.new(0.88, 0, 0.28, 0)
	hpBg.Position           = UDim2.new(0.06, 0, 0.62, 0)
	hpBg.BackgroundColor3   = Color3.fromRGB(50, 0, 0)
	hpBg.BorderSizePixel    = 0
	hpBg.Parent             = gui
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = hpBg end

	local hpFill             = Instance.new("Frame")
	hpFill.Name              = "HPFill"
	hpFill.Size              = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3  = Color3.fromRGB(20, 200, 20)
	hpFill.BorderSizePixel   = 0
	hpFill.Parent            = hpBg
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = hpFill end

	local monster: MonsterData = {
		part         = part,
		hp           = cfg.hp,
		maxHp        = cfg.hp,
		cfg          = cfg,
		zone         = zoneName,
		spawnPart    = spawnPart,
		contributors = {},
		dead         = false,
	}
	table.insert(activeMonsters, monster)
	return monster
end

-- XP & Niveaux --------------------------------------------------------------
local MonsterService = {}

local function doSyncStats(player: Player)
	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return end
	local data = profile.Data
	SyncStats:FireClient(player, {
		xp       = data.xp,
		level    = data.level,
		xpNeeded = xpForLevel(data.level),
	})
end

local function addXP(player: Player, profile: any, amount: number)
	local data = profile.Data
	data.xp   += amount
	while true do
		local needed = xpForLevel(data.level)
		if data.xp < needed then break end
		data.xp    -= needed
		data.level += 1
	end
	doSyncStats(player)
end

-- Mort du monstre -----------------------------------------------------------
local function onMonsterKilled(monster: MonsterData)
	monster.dead = true
	monster.hp   = 0

	local totalDmg = 0
	for _, dmg in monster.contributors do totalDmg += dmg end
	if totalDmg == 0 then totalDmg = 1 end

	local dropMult = (monster.cfg.dropMultiplier or 1) :: number

	for userId, damage in monster.contributors do
		local player = Players:GetPlayerByUserId(userId)
		if not player then continue end
		local profile = PlayerData.GetProfile(player)
		if not profile or not profile:IsActive() then continue end

		local ratio         = damage / totalDmg
		local xpGain        = math.max(1, math.round(monster.cfg.xp * ratio))
		local petGoldsMult  = getGoldsMult(profile.Data)
		local skillStats    = StatCalculator.getStats(profile.Data.skillTreeGolds, profile.Data.skillTreePrestige)
		local goldsGain     = math.max(0, math.floor(
			monster.cfg.golds * dropMult * petGoldsMult * skillStats.goldsMult * ratio
		))

		profile.Data.golds += goldsGain
		addXP(player, profile, xpGain)
	end

	monster.part.Transparency = 1
	monster.part.CanCollide   = false
	local gui = monster.part:FindFirstChildWhichIsA("BillboardGui") :: BillboardGui?
	if gui then gui.Enabled = false end

	local delay = if monster.cfg.isBoss
		then ((monster.cfg.respawnSeconds or 300) :: number)
		else RESPAWN_NORMAL

	task.delay(delay, function()
		for i, m in activeMonsters do
			if m == monster then table.remove(activeMonsters, i); break end
		end
		monster.part:Destroy()

		local newCfg = monster.cfg
		if not monster.cfg.isBoss then
			local pool: { any } = {}
			for _, cfg in (Monsters[monster.zone] or {}) do
				if not cfg.isBoss then table.insert(pool, cfg) end
			end
			if #pool > 0 then newCfg = pool[math.random(#pool)] end
		end
		spawnMonster(newCfg, monster.spawnPart, monster.zone)
	end)
end

-- Boucle de combat ----------------------------------------------------------
local accumulator = 0
RunService.Heartbeat:Connect(function(dt: number)
	accumulator += dt
	if accumulator < ATTACK_RATE then return end
	accumulator -= ATTACK_RATE

	for _, monster in activeMonsters do
		if monster.dead then continue end

		for _, player in Players:GetPlayers() do
			local char = player.Character
			if not char then continue end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then continue end
			if (hrp.Position - monster.part.Position).Magnitude > COMBAT_RANGE then continue end

			local profile = PlayerData.GetProfile(player)
			if not profile or not profile:IsActive() then continue end

			local data        = profile.Data
			local stats       = StatCalculator.getStats(data.skillTreeGolds, data.skillTreePrestige)
			local rawDmg      = 0
			local attackUUIDs: { string } = {}

			for _, uuid in data.equippedPets do
				local entry = findPet(data.inventory, uuid)
				if entry then
					rawDmg += calcPetDamage(entry)
					table.insert(attackUUIDs, uuid)
				end
			end

			if rawDmg <= 0 then continue end

			local totalDmg = math.floor(rawDmg * stats.damageMult)

			monster.hp -= totalDmg
			monster.contributors[player.UserId] = (monster.contributors[player.UserId] or 0) + totalDmg
			updateHPBar(monster)

			local hitPos = monster.part.Position + Vector3.new(0, monster.part.Size.Y * 0.5 + 1.5, 0)
			ShowDamage:FireClient(player, hitPos, totalDmg)
			for _, uuid in attackUUIDs do
				PetAttack:FireClient(player, uuid, monster.part.Position)
			end

			if monster.hp <= 0 then
				onMonsterKilled(monster)
				break
			end
		end
	end
end)

-- Initialisation spawn (toutes les zones) -----------------------------------
local function setupZoneSpawns(zoneName: string, zoneMonsters: { any }, spawns: Folder)
	local bossConfig: any = nil
	local normalPool: { any } = {}
	for _, cfg in zoneMonsters do
		if cfg.isBoss then bossConfig = cfg
		else table.insert(normalPool, cfg) end
	end

	for _, child in spawns:GetChildren() do
		if not child:IsA("BasePart") then continue end
		local spawnPart = child :: BasePart

		if spawnPart.Name == "Boss" then
			if bossConfig then spawnMonster(bossConfig, spawnPart, zoneName) end
		else
			local cfg: any = nil
			for _, c in normalPool do
				if c.name == spawnPart.Name then cfg = c; break end
			end
			if not cfg and #normalPool > 0 then cfg = normalPool[math.random(#normalPool)] end
			if cfg then spawnMonster(cfg, spawnPart, zoneName) end
		end
	end
end

task.spawn(function()
	local zonesFolder = workspace:WaitForChild("Zones", 10) :: Folder?
	if not zonesFolder then
		warn("[MonsterService] Workspace.Zones introuvable.")
		return
	end

	for zoneName, zoneMonsters in Monsters do
		local zoneFolder = zonesFolder:FindFirstChild(zoneName) :: Folder?
		if not zoneFolder then
			warn("[MonsterService] Zone manquante : Workspace.Zones." .. zoneName)
			continue
		end
		local spawns = zoneFolder:FindFirstChild("Spawns") :: Folder?
		if not spawns then
			warn("[MonsterService] Spawns manquants : Workspace.Zones." .. zoneName .. ".Spawns")
			continue
		end
		setupZoneSpawns(zoneName, zoneMonsters, spawns)
	end
end)

function MonsterService.OnPlayerAdded(player: Player)
	task.delay(0.6, function()
		doSyncStats(player)
	end)
end

return MonsterService
