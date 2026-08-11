--!strict
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData     = require(script.Parent.Parent.Data.PlayerData)
local PetService     = require(script.Parent.PetService)
local StatCalculator = require(script.Parent.Parent.Skills.StatCalculator)
local Fusion         = require(ReplicatedStorage.Shared.Config.Fusion)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local FusePets = Instance.new("RemoteFunction")
FusePets.Name   = "FusePets"
FusePets.Parent = Remotes

local FuseAll = Instance.new("RemoteFunction")
FuseAll.Name   = "FuseAll"
FuseAll.Parent = Remotes

-- Logique de fusion (appelée depuis FusePets et FuseAll) --------------------
-- Modifie directement `data` ; ne fait pas de Sync.
local function doFuse(
	data:     any,
	petId:    string,
	rarity:   string,
	stars:    number,
	shiny:    boolean,
	required: number
): (boolean, string, any?)

	if stars >= (Fusion.MAX_STARS :: number) then
		return false, "Niveau maximum atteint", nil
	end

	-- Trouver les exemplaires correspondants
	local matchIdx: { number } = {}
	for i, pet in data.inventory do
		if pet.id == petId and pet.rarity == rarity
			and pet.stars == stars and pet.shiny == shiny then
			table.insert(matchIdx, i)
			if #matchIdx >= required then break end
		end
	end

	if #matchIdx < required then
		return false, "Pas assez de pets (" .. #matchIdx .. "/" .. required .. ")", nil
	end

	-- Supprimer les `required` exemplaires (indices décroissants pour ne pas décaler)
	local consumedUuids: { [string]: boolean } = {}
	table.sort(matchIdx, function(a, b) return a > b end)
	for _, idx in matchIdx do
		consumedUuids[data.inventory[idx].uuid] = true
		table.remove(data.inventory, idx)
	end

	-- Déséquiper proprement les pets consommés
	local newEquipped: { string } = {}
	for _, uuid in data.equippedPets do
		if not consumedUuids[uuid] then
			table.insert(newEquipped, uuid)
		end
	end
	data.equippedPets = newEquipped

	-- Créer le pet fusionné
	local newPet = {
		uuid   = HttpService:GenerateGUID(false),
		id     = petId,
		rarity = rarity,
		stars  = stars + 1,
		shiny  = shiny,
	}
	table.insert(data.inventory, newPet)

	return true, "", newPet
end

-- RemoteFunctions -----------------------------------------------------------

FusePets.OnServerInvoke = function(
	player: Player,
	petId:  unknown,
	rarity: unknown,
	stars:  unknown,
	shiny:  unknown
): (boolean, string)
	if typeof(petId)  ~= "string"  then return false, "paramètre invalide (id)" end
	if typeof(rarity) ~= "string"  then return false, "paramètre invalide (rareté)" end
	if typeof(stars)  ~= "number"  then return false, "paramètre invalide (étoiles)" end
	if typeof(shiny)  ~= "boolean" then return false, "paramètre invalide (shiny)" end

	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return false, "profil indisponible" end

	local data     = profile.Data
	local stats    = StatCalculator.getStats(data.skillTreeGolds, data.skillTreePrestige)
	local required = stats.fusionRequired

	local ok, reason, _ = doFuse(data, petId :: string, rarity :: string, stars :: number, shiny :: boolean, required)
	if ok then PetService.Sync(player) end
	return ok, reason
end

-- Fusionne tout ce qui peut l'être en une série de passes.
-- Retourne la liste des pets créés (pour résumé client).
FuseAll.OnServerInvoke = function(player: Player): { any }
	local profile = PlayerData.GetProfile(player)
	if not profile or not profile:IsActive() then return {} end

	local data     = profile.Data
	local stats    = StatCalculator.getStats(data.skillTreeGolds, data.skillTreePrestige)
	local required = stats.fusionRequired

	local created: { any } = {}
	local anyFused = true
	local guard    = 0

	-- Répète jusqu'à ce qu'aucune fusion ne soit possible (ou limite de sécurité)
	while anyFused and guard < 50000 do
		anyFused = false
		guard   += 1

		-- Compter les exemplaires par groupe
		type GroupKey = string
		local counts:  { [GroupKey]: number } = {}
		local groupOf: { [GroupKey]: { petId: string, rarity: string, stars: number, shiny: boolean } } = {}

		for _, pet in data.inventory do
			if (pet.stars :: number) >= (Fusion.MAX_STARS :: number) then continue end
			local key = pet.id .. "|" .. pet.rarity .. "|" .. pet.stars .. "|" .. tostring(pet.shiny)
			counts[key]  = (counts[key] or 0) + 1
			groupOf[key] = { petId = pet.id, rarity = pet.rarity, stars = pet.stars, shiny = pet.shiny }
		end

		-- Tenter une fusion par groupe éligible
		for key, count in counts do
			if count < required then continue end
			local g = groupOf[key]
			local ok, _, newPet = doFuse(data, g.petId, g.rarity, g.stars, g.shiny, required)
			if ok and newPet then
				table.insert(created, newPet)
				anyFused = true
			end
		end
	end

	if #created > 0 then PetService.Sync(player) end
	return created
end

return {}
