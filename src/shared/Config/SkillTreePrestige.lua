--!strict
-- Arbre n°2 — payé en Points de Prestige (PP), PERMANENT (ne se réinitialise jamais)
-- Coût du niveau N = costLevel1 × costMult ^ (N - 1)
return {
	Heritage = {
		displayName = "Héritage",
		effect = "Dégâts ET golds +10% permanent par niveau",
		maxLevel = 10,
		costLevel1 = 1,
		costMult = 2,
		requires = nil,
	},
	ChanceEternelle = {
		displayName = "Chance Éternelle",
		effect = "Luck +25% permanent par niveau",
		maxLevel = 10,
		costLevel1 = 2,
		costMult = 2,
		requires = nil,
	},
	DemarrageEclair = {
		displayName = "Démarrage Éclair",
		effect = "Commence chaque prestige avec 10 000 golds × niveau",
		maxLevel = 5,
		costLevel1 = 3,
		costMult = 2,
		requires = { node = "Heritage", level = 2 },
	},
	MemoireArbre = {
		displayName = "Mémoire d'Arbre",
		effect = "Conserve 10% des niveaux de l'arbre golds au prestige par niveau (max 50%)",
		maxLevel = 5,
		costLevel1 = 5,
		costMult = 2.5,
		requires = { node = "Heritage", level = 5 },
	},
	XPBoost = {
		displayName = "XP Boost",
		effect = "XP +15% permanent par niveau",
		maxLevel = 10,
		costLevel1 = 2,
		costMult = 2,
		requires = nil,
	},
	FusionExperte = {
		displayName = "Fusion Experte",
		effect = "La fusion ne demande que 4 pets (niv.1) puis 3 pets (niv.2)",
		maxLevel = 2,
		costLevel1 = 10,
		costMult = 4,
		requires = { node = "ChanceEternelle", level = 5 },
	},
	GoldsHorsLigne = {
		displayName = "Golds Hors-ligne",
		effect = "Gains hors-ligne +10% du taux par niveau (max 50%)",
		maxLevel = 5,
		costLevel1 = 4,
		costMult = 2,
		requires = { node = "XPBoost", level = 3 },
	},
	EiveilSecret = {
		displayName = "Éveil Secret",
		effect = "Affiche les odds Secret et +50% luck sur Secret",
		maxLevel = 1,
		costLevel1 = 25,
		costMult = 1,
		requires = { node = "ChanceEternelle", level = 10 },
	},
}
