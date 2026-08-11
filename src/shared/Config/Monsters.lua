--!strict
-- Ratio cible : pets moyens de la zone tuent un Standard en 3-8 s.
-- Les BOSS demandent 30-60 s et/ou plusieurs joueurs, drop x3 golds.
return {
	Prairie = {
		{
			name = "Slime",
			hp = 100,
			xp = 5,
			golds = 12,
			isBoss = false,
		},
		{
			name = "Champi Grognon",
			hp = 300,
			xp = 12,
			golds = 30,
			isBoss = false,
		},
		{
			name = "Golem d'Herbe",
			hp = 1200,
			xp = 40,
			golds = 110,
			isBoss = false,
		},
		{
			name = "Roi Slime",
			hp = 15000,
			xp = 350,
			golds = 1200,
			isBoss = true,
			respawnSeconds = 300, -- 5 min
			dropMultiplier = 3,
		},
	},
	ForetSombre = {
		{
			name = "Chauve-Sournoise",
			hp = 900,
			xp = 35,
			golds = 95,
			isBoss = false,
		},
		{
			name = "Araignélia",
			hp = 2600,
			xp = 90,
			golds = 260,
			isBoss = false,
		},
		{
			name = "Ent Maudit",
			hp = 9500,
			xp = 280,
			golds = 900,
			isBoss = false,
		},
		{
			name = "Alpha Lycan",
			hp = 120000,
			xp = 2500,
			golds = 9500,
			isBoss = true,
			respawnSeconds = 600, -- 10 min
			dropMultiplier = 3,
		},
	},
	Volcan = {
		{
			name = "Magmalin",
			hp = 7000,
			xp = 260,
			golds = 800,
			isBoss = false,
		},
		{
			name = "Salamandre Ardente",
			hp = 21000,
			xp = 700,
			golds = 2300,
			isBoss = false,
		},
		{
			name = "Golem de Lave",
			hp = 80000,
			xp = 2400,
			golds = 8200,
			isBoss = false,
		},
		{
			name = "Seigneur Magma",
			hp = 950000,
			xp = 22000,
			golds = 80000,
			isBoss = true,
			respawnSeconds = 900, -- 15 min
			dropMultiplier = 3,
		},
	},
}
