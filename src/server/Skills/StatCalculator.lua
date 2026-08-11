--!strict
-- Point central de calcul des bonus — tous les services lisent leurs multiplicateurs ici.
-- Brancher l'arbre prestige : passer treePrestige et ajouter les formules dans getStats.

export type Stats = {
	damageMult:        number,  -- multiplicateur sur les dégâts des pets
	goldsMult:         number,  -- multiplicateur sur les golds reçus (skill uniquement, hors pets)
	luck:              number,  -- divise les odds des raretés Rare+  (1 = pas de bonus)
	maxEquipped:       number,  -- nombre max de pets équipés
	rollDelay:         number,  -- délai en secondes entre chaque roll auto
	autoRollUnlocked:  boolean,
	multiRollUnlocked: boolean,
	fusionRequired:    number,  -- pets requis pour fusionner (5 → 4 → 3 via FusionExperte)
}

local StatCalculator = {}

function StatCalculator.getStats(
	treeGolds:    { [string]: number },
	treePrestige: { [string]: number }
): Stats
	local g  = treeGolds    or {}
	local _p = treePrestige or {} -- réservé pour l'arbre prestige

	local degatsI        = (g["DegatsI"]       or 0) :: number
	local degatsII       = (g["DegatsII"]      or 0) :: number
	local gainsI         = (g["GainsI"]        or 0) :: number
	local gainsII        = (g["GainsII"]       or 0) :: number
	local luckI          = (g["LuckI"]         or 0) :: number
	local luckII         = (g["LuckII"]        or 0) :: number
	local equipe         = (g["EquipeBonus"]   or 0) :: number
	local rollRap        = (g["RollRapide"]    or 0) :: number
	local autoR          = (g["AutoRoll"]      or 0) :: number
	local multiR         = (g["MultiRollX3"]   or 0) :: number
	local fusionExperte  = (_p["FusionExperte"] or 0) :: number

	return {
		damageMult        = (1 + degatsI * 0.05) * (1 + degatsII * 0.08),
		goldsMult         = (1 + gainsI  * 0.05) * (1 + gainsII  * 0.08),
		luck              = 1 + luckI * 0.10 + luckII * 0.15,
		maxEquipped       = 3 + equipe,
		rollDelay         = math.max(0.3, 1.0 - rollRap * 0.10),
		autoRollUnlocked  = autoR  >= 1,
		multiRollUnlocked = multiR >= 1,
		fusionRequired    = math.max(3, 5 - fusionExperte),
	}
end

return StatCalculator
