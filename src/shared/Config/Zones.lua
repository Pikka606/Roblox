--!strict
-- Dictionnaire zoneName → config. Prairie = starter (gratuite, toujours dans unlockedZones).
-- goldsCost = 0 → aucune porte physique créée par ZoneService.
return {
	Prairie = {
		displayName   = "Prairie",
		goldsCost     = 0,
		levelRequired = 1,
		order         = 1,
	},
	ForetSombre = {
		displayName   = "Forêt Sombre",
		goldsCost     = 250000,
		levelRequired = 10,
		order         = 2,
	},
	Volcan = {
		displayName   = "Volcan",
		goldsCost     = 15000000,
		levelRequired = 25,
		order         = 3,
	},
}
