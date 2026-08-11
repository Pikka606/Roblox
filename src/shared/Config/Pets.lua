--!strict
-- Dégâts finaux = baseDamage × damageMult(rarity) × starsMult × shinyMult × treeMult
-- TODO_ = placeholder à renommer et équilibrer avant la V1
return {
	-- ==================== Zone 1 : Prairie ====================
	Lapinou = {
		zone = "Prairie", rarity = "Common",
		baseDamage = 1, goldsMult = 1,
		description = "Lapin blanc tout simple",
	},
	Souricette = {
		zone = "Prairie", rarity = "Common",
		baseDamage = 1, goldsMult = 1.05,
		description = "Petite souris grise",
	},
	Pioupiou = {
		zone = "Prairie", rarity = "Common",
		baseDamage = 2, goldsMult = 1,
		description = "Poussin jaune",
	},
	Grenouyo = {
		zone = "Prairie", rarity = "Common",
		baseDamage = 2, goldsMult = 1.1,
		description = "Grenouille verte",
	},
	Renardin = {
		zone = "Prairie", rarity = "Uncommon",
		baseDamage = 4, goldsMult = 1.2,
		description = "Renard roux malicieux",
	},
	Herissonic = {
		zone = "Prairie", rarity = "Uncommon",
		baseDamage = 5, goldsMult = 1.15,
		description = "Hérisson rapide",
	},
	Chouquette = {
		zone = "Prairie", rarity = "Uncommon",
		baseDamage = 4, goldsMult = 1.3,
		description = "Chouette curieuse",
	},
	Sanglibou = {
		zone = "Prairie", rarity = "Rare",
		baseDamage = 12, goldsMult = 1.5,
		description = "Sanglier costaud",
	},
	Cerfelin = {
		zone = "Prairie", rarity = "Rare",
		baseDamage = 14, goldsMult = 1.4,
		description = "Cerf élégant aux bois lumineux",
	},
	Loupio = {
		zone = "Prairie", rarity = "Rare",
		baseDamage = 15, goldsMult = 1.5,
		description = "Loup au regard perçant",
	},
	Aiglor = {
		zone = "Prairie", rarity = "Epic",
		baseDamage = 40, goldsMult = 2,
		description = "Aigle royal doré",
	},
	Oursagon = {
		zone = "Prairie", rarity = "Epic",
		baseDamage = 48, goldsMult = 1.8,
		description = "Ours massif aux griffes de pierre",
	},
	Carberix = {
		zone = "Prairie", rarity = "Legendary",
		baseDamage = 170, goldsMult = 3,
		description = "Chien à trois têtes flamboyant",
	},
	Feniximo = {
		zone = "Prairie", rarity = "Mythic",
		baseDamage = 650, goldsMult = 5.5,
		description = "Phénix de feu immortel",
	},
	Prismalys = {
		zone = "Prairie", rarity = "Secret",
		baseDamage = 3200, goldsMult = 11,
		description = "Entité prismatique légendaire de la Prairie",
	},

	-- ==================== Zone 2 : Forêt Sombre (×8) ====================
	TODO_FS_Lapinou = {
		zone = "ForetSombre", rarity = "Common",
		baseDamage = 8, goldsMult = 1,
		description = "TODO",
	},
	TODO_FS_Souricette = {
		zone = "ForetSombre", rarity = "Common",
		baseDamage = 8, goldsMult = 1.05,
		description = "TODO",
	},
	TODO_FS_Pioupiou = {
		zone = "ForetSombre", rarity = "Common",
		baseDamage = 16, goldsMult = 1,
		description = "TODO",
	},
	TODO_FS_Grenouyo = {
		zone = "ForetSombre", rarity = "Common",
		baseDamage = 16, goldsMult = 1.1,
		description = "TODO",
	},
	TODO_FS_Renardin = {
		zone = "ForetSombre", rarity = "Uncommon",
		baseDamage = 32, goldsMult = 1.2,
		description = "TODO",
	},
	TODO_FS_Herissonic = {
		zone = "ForetSombre", rarity = "Uncommon",
		baseDamage = 40, goldsMult = 1.15,
		description = "TODO",
	},
	TODO_FS_Chouquette = {
		zone = "ForetSombre", rarity = "Uncommon",
		baseDamage = 32, goldsMult = 1.3,
		description = "TODO",
	},
	TODO_FS_Sanglibou = {
		zone = "ForetSombre", rarity = "Rare",
		baseDamage = 96, goldsMult = 1.5,
		description = "TODO",
	},
	TODO_FS_Cerfelin = {
		zone = "ForetSombre", rarity = "Rare",
		baseDamage = 112, goldsMult = 1.4,
		description = "TODO",
	},
	TODO_FS_Loupio = {
		zone = "ForetSombre", rarity = "Rare",
		baseDamage = 120, goldsMult = 1.5,
		description = "TODO",
	},
	TODO_FS_Aiglor = {
		zone = "ForetSombre", rarity = "Epic",
		baseDamage = 320, goldsMult = 2,
		description = "TODO",
	},
	TODO_FS_Oursagon = {
		zone = "ForetSombre", rarity = "Epic",
		baseDamage = 384, goldsMult = 1.8,
		description = "TODO",
	},
	TODO_FS_Carberix = {
		zone = "ForetSombre", rarity = "Legendary",
		baseDamage = 1360, goldsMult = 3,
		description = "TODO",
	},
	TODO_FS_Feniximo = {
		zone = "ForetSombre", rarity = "Mythic",
		baseDamage = 5200, goldsMult = 5.5,
		description = "TODO",
	},
	TODO_FS_Prismalys = {
		zone = "ForetSombre", rarity = "Secret",
		baseDamage = 25600, goldsMult = 11,
		description = "TODO",
	},

	-- ==================== Zone 3 : Volcan (×60) ====================
	TODO_V_Lapinou = {
		zone = "Volcan", rarity = "Common",
		baseDamage = 60, goldsMult = 1,
		description = "TODO",
	},
	TODO_V_Souricette = {
		zone = "Volcan", rarity = "Common",
		baseDamage = 60, goldsMult = 1.05,
		description = "TODO",
	},
	TODO_V_Pioupiou = {
		zone = "Volcan", rarity = "Common",
		baseDamage = 120, goldsMult = 1,
		description = "TODO",
	},
	TODO_V_Grenouyo = {
		zone = "Volcan", rarity = "Common",
		baseDamage = 120, goldsMult = 1.1,
		description = "TODO",
	},
	TODO_V_Renardin = {
		zone = "Volcan", rarity = "Uncommon",
		baseDamage = 240, goldsMult = 1.2,
		description = "TODO",
	},
	TODO_V_Herissonic = {
		zone = "Volcan", rarity = "Uncommon",
		baseDamage = 300, goldsMult = 1.15,
		description = "TODO",
	},
	TODO_V_Chouquette = {
		zone = "Volcan", rarity = "Uncommon",
		baseDamage = 240, goldsMult = 1.3,
		description = "TODO",
	},
	TODO_V_Sanglibou = {
		zone = "Volcan", rarity = "Rare",
		baseDamage = 720, goldsMult = 1.5,
		description = "TODO",
	},
	TODO_V_Cerfelin = {
		zone = "Volcan", rarity = "Rare",
		baseDamage = 840, goldsMult = 1.4,
		description = "TODO",
	},
	TODO_V_Loupio = {
		zone = "Volcan", rarity = "Rare",
		baseDamage = 900, goldsMult = 1.5,
		description = "TODO",
	},
	TODO_V_Aiglor = {
		zone = "Volcan", rarity = "Epic",
		baseDamage = 2400, goldsMult = 2,
		description = "TODO",
	},
	TODO_V_Oursagon = {
		zone = "Volcan", rarity = "Epic",
		baseDamage = 2880, goldsMult = 1.8,
		description = "TODO",
	},
	TODO_V_Carberix = {
		zone = "Volcan", rarity = "Legendary",
		baseDamage = 10200, goldsMult = 3,
		description = "TODO",
	},
	TODO_V_Feniximo = {
		zone = "Volcan", rarity = "Mythic",
		baseDamage = 39000, goldsMult = 5.5,
		description = "TODO",
	},
	TODO_V_Prismalys = {
		zone = "Volcan", rarity = "Secret",
		baseDamage = 192000, goldsMult = 11,
		description = "TODO",
	},
}
