--!strict
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Doit exister avant le chargement des services qui y ajoutent des Remotes
local Remotes        = Instance.new("Folder")
Remotes.Name         = "Remotes"
Remotes.Parent       = ReplicatedStorage

local PlayerData       = require(script.Data.PlayerData)
local PetService       = require(script.Pets.PetService)
local MonsterService   = require(script.Combat.MonsterService)
local SkillTreeService = require(script.Skills.SkillTreeService)
local ZoneService      = require(script.Zones.ZoneService)
require(script.Rolling.RollService)
require(script.Pets.FusionService)

local playerConns: { [number]: RBXScriptConnection } = {}

local function createLeaderstats(player: Player)
	local ls = Instance.new("Folder")
	ls.Name   = "leaderstats"
	ls.Parent = player

	local golds = Instance.new("IntValue")
	golds.Name   = "Golds"
	golds.Value  = 0
	golds.Parent = ls

	local niveau = Instance.new("IntValue")
	niveau.Name   = "Niveau"
	niveau.Value  = 1
	niveau.Parent = ls
end

local function onPlayerAdded(player: Player)
	createLeaderstats(player)
	PlayerData.LoadProfile(player)

	local profile = PlayerData.GetProfile(player)
	if not profile then return end

	PetService.OnPlayerAdded(player)
	MonsterService.OnPlayerAdded(player)
	SkillTreeService.OnPlayerAdded(player)
	ZoneService.OnPlayerAdded(player)

	local ls      = player.leaderstats
	local goldsV  = ls.Golds  :: IntValue
	local niveauV = ls.Niveau :: IntValue

	playerConns[player.UserId] = RunService.Heartbeat:Connect(function()
		if not profile:IsActive() then return end
		goldsV.Value  = math.floor(profile.Data.golds)
		niveauV.Value = profile.Data.level
	end)
end

local function onPlayerRemoving(player: Player)
	local conn = playerConns[player.UserId]
	if conn then
		conn:Disconnect()
		playerConns[player.UserId] = nil
	end
	PlayerData.ReleaseProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
