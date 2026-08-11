--!strict
-- 5 pets identiques au même niveau d'étoile → 1 pet à l'étoile suivante
-- Un pet 5★ demande 5^5 = 3 125 exemplaires du pet de base
-- Les Shiny fusionnent séparément (5 Shiny → 1 Shiny étoilé)
return {
	BASE_PETS_REQUIRED = 5,

	-- [étoile de départ] = bonus
	Stars = {
		[0] = { statsMult = 1.5,      cumulative = 1.5,      visual = "Doré ★" },
		[1] = { statsMult = 1.5,      cumulative = 2.25,     visual = "Doré ★★" },
		[2] = { statsMult = 1.5,      cumulative = 3.375,    visual = "Doré ★★★ + aura" },
		[3] = { statsMult = 1.5,      cumulative = 5.0625,   visual = "Arc-en-ciel + aura" },
		[4] = { statsMult = 1.5,      cumulative = 7.59375,  visual = "Arc-en-ciel animé — MAX" },
	},

	MAX_STARS = 5,

	SHINY_FUSE_SEPARATE = true,
}
