--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData     = require(script.Parent.Parent.Data.PlayerData)
local StatCalculator = require(script.Parent.Parent.Skills.StatCalculator)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EquipPet      = Instance.new("RemoteFunction")
EquipPet.Name       = "EquipPet"
EquipPet.Parent     = Remotes

local SyncData      = Instance.new("RemoteEvent")
SyncData.Name       = "SyncData"
SyncData.Parent     = Remotes

local PetService = {}

local function getMaxSlots(player: Player): number
	local profile = PlayerData.GetProfile(player)
	if not profile then return 3 end
	local data  = profile.Data
	local stats = StatCalculator.getStats(data.skillTreeGolds, data.skillTreePrestige)
	return stats.maxEquipped
end

function PetService.Sync(player: Player)
	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return end
	local data  = profile.Data
	local stats = StatCalculator.getStats(data.skillTreeGolds, data.skillTreePrestige)
	SyncData:FireClient(player, {
		inventory      = data.inventory,
		equippedPets   = data.equippedPets,
		maxSlots       = getMaxSlots(player),
		fusionRequired = stats.fusionRequired,
	})
end

function PetService.OnPlayerAdded(player: Player)
	task.delay(0.5, function()
		PetService.Sync(player)
	end)
end

EquipPet.OnServerInvoke = function(player: Player, uuid: unknown): boolean
	if typeof(uuid) ~= "string" then return false end

	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	local data = profile.Data

	local found = false
	for _, pet in data.inventory do
		if pet.uuid == uuid then found = true; break end
	end
	if not found then return false end

	for i, eq in data.equippedPets do
		if eq == uuid then
			table.remove(data.equippedPets, i)
			PetService.Sync(player)
			return true
		end
	end

	if #data.equippedPets >= getMaxSlots(player) then return false end
	table.insert(data.equippedPets, uuid)
	PetService.Sync(player)
	return true
end

return PetService
