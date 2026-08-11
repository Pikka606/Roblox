--!strict
-- XP requise pour passer du niveau N au niveau N+1 : round(XP_BASE * N ^ XP_EXPONENT)
-- Niveau 1→2  :     100 XP
-- Niveau 5→6  :     559 XP
-- Niveau 10→11:   3 162 XP
-- Niveau 25→26:  31 498 XP
-- Niveau 50→51: 353 553 XP
return {
	XP_BASE     = 100,
	XP_EXPONENT = 1.5,
}
