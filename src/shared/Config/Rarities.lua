--!strict
return {
	Common = {
		displayName = "Common",
		oddsDisplay = "1 sur 2",
		probability = 0.5,
		damageMult = 1,
		goldsMult = 1,
		color = "Grey",
	},
	Uncommon = {
		displayName = "Uncommon",
		oddsDisplay = "1 sur 10",
		probability = 0.1,
		damageMult = 3,
		goldsMult = 1.2,
		color = "Green",
	},
	Rare = {
		displayName = "Rare",
		oddsDisplay = "1 sur 100",
		probability = 0.01,
		damageMult = 10,
		goldsMult = 1.5,
		color = "Blue",
	},
	Epic = {
		displayName = "Epic",
		oddsDisplay = "1 sur 1 000",
		probability = 0.001,
		damageMult = 35,
		goldsMult = 2,
		color = "Purple",
	},
	Legendary = {
		displayName = "Legendary",
		oddsDisplay = "1 sur 50 000",
		probability = 0.00002,
		damageMult = 150,
		goldsMult = 3,
		color = "Gold",
	},
	Mythic = {
		displayName = "Mythic",
		oddsDisplay = "1 sur 1 000 000",
		probability = 0.000001,
		damageMult = 600,
		goldsMult = 5,
		color = "Red-Orange",
	},
	Secret = {
		displayName = "Secret",
		oddsDisplay = "1 sur 50 000 000",
		probability = 0.00000002,
		damageMult = 3000,
		goldsMult = 10,
		color = "Black-Rainbow",
	},

	-- Variante Shiny : 1/40 sur n'importe quel roll, stats x2
	SHINY_CHANCE = 1 / 40,
	SHINY_STATS_MULT = 2,

	-- La stat Luck divise les odds des raretés Rare et au-dessus
	LUCK_THRESHOLD = "Rare",

	-- Ordre croissant pour comparaisons/affichage
	ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
}
