--!strict
-- Prestige : sacrifice golds/niveau/arbre golds pour des Points de Prestige (PP) permanents
-- Niveau requis : 50 au premier, +25 par prestige suivant (75, 100, 125…)
-- PP gagnés = 1 + (niveau au moment du prestige - niveau requis) // 10
return {
	FIRST_LEVEL_REQUIRED = 50,
	LEVEL_INCREMENT = 25, -- chaque prestige augmente le seuil de 25

	PP_BASE = 1,
	PP_PER_10_BONUS_LEVELS = 1, -- +1 PP par tranche de 10 niveaux au-dessus du seuil

	-- Bonus permanent par prestige effectué (se cumule avec tout)
	DAMAGE_BONUS_PER_PRESTIGE = 0.05, -- +5%
	GOLDS_BONUS_PER_PRESTIGE = 0.05,  -- +5%

	-- Ce qui est PERDU au prestige
	LOST = {
		"golds",
		"level",
		"xp",
		"skillTreeGolds",
		"unlockedZones", -- reset à Prairie
	},

	-- Ce qui est GARDÉ au prestige
	KEPT = {
		"inventory",     -- pets et étoiles
		"equippedPets",
		"petIndex",      -- collection/index
		"skillTreePrestige",
		"lifetimeStats",
		"guild",
	},
}
