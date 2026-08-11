--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData     = require(script.Parent.Parent.Data.PlayerData)
local SkillTreeGolds = require(ReplicatedStorage.Shared.Config.SkillTreeGolds)
local StatCalculator = require(script.Parent.StatCalculator)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local BuySkill = Instance.new("RemoteFunction")
BuySkill.Name   = "BuySkill"
BuySkill.Parent = Remotes

local SyncSkillTree = Instance.new("RemoteEvent")
SyncSkillTree.Name   = "SyncSkillTree"
SyncSkillTree.Parent = Remotes

local SkillTreeService = {}

-- Coût du nœud pour passer du niveau `currentLevel` à `currentLevel+1`
local function nodeCost(nodeName: string, currentLevel: number): number
	local node = SkillTreeGolds[nodeName]
	if not node then return math.huge end
	return math.round(node.costLevel1 * (node.costMult ^ currentLevel))
end

local function prereqsMet(nodeName: string, treeGolds: { [string]: number }): boolean
	local node = SkillTreeGolds[nodeName]
	if not node then return false end
	local req = node.requires
	if not req then return true end
	return ((treeGolds[req.node] or 0) :: number) >= (req.level :: number)
end

local function doSync(player: Player)
	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return end
	local data  = profile.Data
	local stats = StatCalculator.getStats(data.skillTreeGolds, data.skillTreePrestige)
	SyncSkillTree:FireClient(player, {
		skillTreeGolds = data.skillTreeGolds,
		golds          = data.golds,
		stats          = stats,
	})
end

BuySkill.OnServerInvoke = function(player: Player, nodeName: unknown): (boolean, string)
	if typeof(nodeName) ~= "string" then return false, "invalide" end

	local name = nodeName :: string
	local node = SkillTreeGolds[name]
	if not node then return false, "nœud inconnu" end

	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return false, "profil indisponible" end

	local data         = profile.Data
	local tree         = data.skillTreeGolds
	local currentLevel = (tree[name] or 0) :: number

	if currentLevel >= (node.maxLevel :: number) then
		return false, "niveau maximum atteint"
	end
	if not prereqsMet(name, tree) then
		return false, "prérequis non remplis"
	end

	local cost = nodeCost(name, currentLevel)
	if data.golds < cost then
		return false, "golds insuffisants"
	end

	data.golds -= cost
	tree[name]  = currentLevel + 1

	doSync(player)
	return true, ""
end

function SkillTreeService.OnPlayerAdded(player: Player)
	task.delay(0.8, function()
		doSync(player)
	end)
end

-- Appelé par d'autres services quand les golds changent significativement
-- (ex : après un kill) — permet au client de mettre à jour l'affordabilité
function SkillTreeService.NotifyGoldsChanged(player: Player)
	doSync(player)
end

return SkillTreeService
