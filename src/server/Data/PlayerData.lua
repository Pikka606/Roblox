--!strict
local Players = game:GetService("Players")

-- ProfileStore est dans src/server/Data/ aux côtés de ce module
local ProfileStore = require(script.Parent.ProfileStore)

local DEFAULT_PROFILE = {
	golds = 0,
	level = 1,
	xp = 0,
	prestigePoints = 0,
	prestigeCount = 0,
	totalRolls = 0,
	inventory = {},        -- { { id: string, rarity: string, stars: number, shiny: boolean, uuid: string } }
	equippedPets = {},     -- { string } — UUIDs, 3 slots de base
	skillTreeGolds = {},   -- { [nodeName: string]: number } — niveau de chaque nœud
	skillTreePrestige = {},-- { [nodeName: string]: number }
	unlockedZones = { "Prairie" },
}

local Store = ProfileStore.New("PlayerData_v1", DEFAULT_PROFILE)

local Profiles: { [number]: any } = {}

local PlayerData = {}

function PlayerData.LoadProfile(player: Player)
	local profile = Store:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick("Impossible de charger tes données. Réessaie dans quelques secondes.")
		return
	end

	profile:AddUserId(player.UserId)
	Profiles[player.UserId] = profile

	profile.OnSessionEnd:Connect(function()
		Profiles[player.UserId] = nil
		player:Kick("Ta session de données a été fermée. Reconnecte-toi.")
	end)
end

function PlayerData.GetProfile(player: Player)
	return Profiles[player.UserId]
end

function PlayerData.ReleaseProfile(player: Player)
	local profile = Profiles[player.UserId]
	if profile then
		profile:EndSession()
	end
end

return PlayerData
