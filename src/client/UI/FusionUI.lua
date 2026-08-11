--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Pets     = require(ReplicatedStorage.Shared.Config.Pets)
local Fusion   = require(ReplicatedStorage.Shared.Config.Fusion)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local SyncData  = Remotes:WaitForChild("SyncData",  15) :: RemoteEvent
local FusePets  = Remotes:WaitForChild("FusePets",  15) :: RemoteFunction
local FuseAll   = Remotes:WaitForChild("FuseAll",   15) :: RemoteFunction

local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(160, 160, 160),
	Uncommon  = Color3.fromRGB(80,  200, 80 ),
	Rare      = Color3.fromRGB(60,  130, 255),
	Epic      = Color3.fromRGB(160, 50,  255),
	Legendary = Color3.fromRGB(255, 185, 0  ),
	Mythic    = Color3.fromRGB(255, 70,  20 ),
	Secret    = Color3.fromRGB(30,  30,  30 ),
}

local currentInventory:  { any }   = {}
local currentRequired:   number    = 5
local isOpen    = false
local isBusy    = false  -- animation / appel serveur en cours

-- Helpers -------------------------------------------------------------------

local function calcDamage(petId: string, rarity: string, stars: number, shiny: boolean): number
	local petCfg    = Pets[petId]
	local rarityCfg = Rarities[rarity]
	if not petCfg or not rarityCfg then return 0 end
	local base      = petCfg.baseDamage * rarityCfg.damageMult
	local fusEntry  = if stars > 0 then Fusion.Stars[stars - 1] else nil
	local starsMult = if fusEntry then fusEntry.cumulative else 1
	local shinyMult = if shiny then (Rarities.SHINY_STATS_MULT :: number) else 1
	return math.floor(base * starsMult * shinyMult)
end

local function starsStr(n: number): string
	return if n > 0 then string.rep("★", n) else ""
end

local function starsColor(n: number): Color3
	return if n >= 4 then Color3.fromRGB(255, 100, 255)
		elseif n >= 1 then Color3.fromRGB(255, 210, 50)
		else Color3.fromRGB(255, 255, 255)
end

-- ScreenGui -----------------------------------------------------------------

local Gui            = Instance.new("ScreenGui")
Gui.Name             = "FusionGui"
Gui.ResetOnSpawn     = false
Gui.IgnoreGuiInset   = true
Gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
Gui.Parent           = PlayerGui

-- Bouton d'ouverture --------------------------------------------------------

local OpenBtn              = Instance.new("TextButton")
OpenBtn.Size               = UDim2.new(0.12, 0, 0.09, 0)
OpenBtn.AnchorPoint        = Vector2.new(0, 0.5)
OpenBtn.Position           = UDim2.new(0.01, 0, 0.74, 0)
OpenBtn.BackgroundColor3   = Color3.fromRGB(80, 30, 30)
OpenBtn.BorderSizePixel    = 0
OpenBtn.Text               = "Fusion"
OpenBtn.TextColor3         = Color3.fromRGB(255, 180, 100)
OpenBtn.TextScaled         = true
OpenBtn.Font               = Enum.Font.GothamBold
OpenBtn.AutoButtonColor    = false
OpenBtn.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = OpenBtn
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(200, 100, 50); s.Thickness = 2; s.Parent = OpenBtn
	local sc = Instance.new("UISizeConstraint"); sc.MaxSize = Vector2.new(130, 56); sc.Parent = OpenBtn
end

-- Panneau principal ---------------------------------------------------------

local Panel              = Instance.new("Frame")
Panel.Name               = "FusionPanel"
Panel.Size               = UDim2.new(0.55, 0, 0.88, 0)
Panel.AnchorPoint        = Vector2.new(0.5, 0.5)
Panel.Position           = UDim2.new(0.5, 0, 0.5, 0)
Panel.BackgroundColor3   = Color3.fromRGB(16, 10, 10)
Panel.BorderSizePixel    = 0
Panel.Visible            = false
Panel.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Panel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(160, 80, 30); s.Thickness = 2; s.Parent = Panel
	local sc = Instance.new("UISizeConstraint")
	sc.MaxSize = Vector2.new(480, 560)
	sc.Parent  = Panel
end

local contentScale       = Instance.new("UIScale")
contentScale.Scale       = 1
contentScale.Parent      = Panel
Panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	contentScale.Scale = math.clamp(Panel.AbsoluteSize.Y / 480, 0.5, 1.1)
end)
task.defer(function() contentScale.Scale = math.clamp(Panel.AbsoluteSize.Y / 480, 0.5, 1.1) end)

-- Header --------------------------------------------------------------------

local Header             = Instance.new("Frame")
Header.Size              = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3  = Color3.fromRGB(36, 18, 10)
Header.BorderSizePixel   = 0
Header.Parent            = Panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Header end

local TitleLbl                  = Instance.new("TextLabel")
TitleLbl.Size                   = UDim2.new(0.38, 0, 1, 0)
TitleLbl.Position               = UDim2.new(0.03, 0, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.TextColor3             = Color3.fromRGB(255, 180, 100)
TitleLbl.TextScaled             = true
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.Text                   = "FUSION"
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.Parent                 = Header

local FuseAllBtn              = Instance.new("TextButton")
FuseAllBtn.Size               = UDim2.new(0.36, 0, 0.72, 0)
FuseAllBtn.AnchorPoint        = Vector2.new(0, 0.5)
FuseAllBtn.Position           = UDim2.new(0.38, 0, 0.5, 0)
FuseAllBtn.BackgroundColor3   = Color3.fromRGB(180, 80, 20)
FuseAllBtn.BorderSizePixel    = 0
FuseAllBtn.Text               = "Fusionner tout"
FuseAllBtn.TextColor3         = Color3.fromRGB(255, 240, 200)
FuseAllBtn.TextScaled         = true
FuseAllBtn.Font               = Enum.Font.GothamBold
FuseAllBtn.AutoButtonColor    = false
FuseAllBtn.Parent             = Header
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = FuseAllBtn
end

local CloseBtn              = Instance.new("TextButton")
CloseBtn.Size               = UDim2.new(0, 34, 0, 34)
CloseBtn.Position           = UDim2.new(1, -44, 0, 9)
CloseBtn.BackgroundColor3   = Color3.fromRGB(180, 45, 45)
CloseBtn.BorderSizePixel    = 0
CloseBtn.Text               = "✕"
CloseBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
CloseBtn.TextScaled         = true
CloseBtn.Font               = Enum.Font.GothamBold
CloseBtn.AutoButtonColor    = false
CloseBtn.Parent             = Header
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = CloseBtn end

-- Zone résumé "Fusionner tout" (sous le header) ----------------------------

local SummaryLbl                  = Instance.new("TextLabel")
SummaryLbl.Name                   = "SummaryLbl"
SummaryLbl.Size                   = UDim2.new(1, -12, 0, 28)
SummaryLbl.Position               = UDim2.new(0, 6, 0, 52)
SummaryLbl.BackgroundTransparency = 1
SummaryLbl.TextColor3             = Color3.fromRGB(180, 220, 180)
SummaryLbl.TextScaled             = true
SummaryLbl.Font                   = Enum.Font.Gotham
SummaryLbl.Text                   = ""
SummaryLbl.Visible                = false
SummaryLbl.Parent                 = Panel

-- Scroll --------------------------------------------------------------------

local Scroll                      = Instance.new("ScrollingFrame")
Scroll.Size                       = UDim2.new(1, -12, 1, -62)
Scroll.Position                   = UDim2.new(0, 6, 0, 58)
Scroll.BackgroundTransparency     = 1
Scroll.BorderSizePixel            = 0
Scroll.ScrollBarThickness         = 5
Scroll.ScrollBarImageColor3       = Color3.fromRGB(160, 80, 30)
Scroll.AutomaticCanvasSize        = Enum.AutomaticSize.Y
Scroll.CanvasSize                 = UDim2.new(0, 0, 0, 0)
Scroll.Parent                     = Panel

local ListLayout        = Instance.new("UIListLayout")
ListLayout.SortOrder    = Enum.SortOrder.LayoutOrder
ListLayout.Padding      = UDim.new(0, 5)
ListLayout.Parent       = Scroll

local ListPadding              = Instance.new("UIPadding")
ListPadding.PaddingTop         = UDim.new(0, 4)
ListPadding.PaddingBottom      = UDim.new(0, 6)
ListPadding.PaddingLeft        = UDim.new(0, 5)
ListPadding.PaddingRight       = UDim.new(0, 5)
ListPadding.Parent             = Scroll

-- Animation de fusion -------------------------------------------------------

local AnimOverlay              = Instance.new("Frame")
AnimOverlay.Name               = "AnimOverlay"
AnimOverlay.Size               = UDim2.new(1, 0, 1, 0)
AnimOverlay.Position           = UDim2.new(0, 0, 0, 52) -- sous le header
AnimOverlay.BackgroundColor3   = Color3.fromRGB(5, 3, 8)
AnimOverlay.BackgroundTransparency = 0.15
AnimOverlay.BorderSizePixel    = 0
AnimOverlay.Visible            = false
AnimOverlay.ZIndex             = 20
AnimOverlay.Parent             = Panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = AnimOverlay end

local function playFusionAnimation(color: Color3, newStars: number, petName: string, shiny: boolean, required: number)
	if isBusy then return end
	isBusy = true

	-- Nettoyer les anciens enfants de l'overlay
	for _, child in AnimOverlay:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end

	AnimOverlay.Visible = true

	-- Créer `required` icônes en cercle
	local icons: { Frame } = {}
	for i = 1, required do
		local angle = (2 * math.pi * (i - 1) / required) - math.pi / 2
		local ix    = 0.5 + math.cos(angle) * 0.30
		local iy    = 0.5 + math.sin(angle) * 0.30

		local icon              = Instance.new("Frame")
		icon.Size               = UDim2.new(0.10, 0, 0.10, 0)
		icon.AnchorPoint        = Vector2.new(0.5, 0.5)
		icon.Position           = UDim2.new(ix, 0, iy, 0)
		icon.BackgroundColor3   = color
		icon.BorderSizePixel    = 0
		icon.ZIndex             = 21
		icon.Parent             = AnimOverlay
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.3, 0); c.Parent = icon
			local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255); s.Thickness = 2; s.Parent = icon
		end
		table.insert(icons, icon)
	end

	-- Convergence vers le centre
	local TWEEN_CONV = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for _, icon in icons do
		TweenService:Create(icon, TWEEN_CONV, {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size     = UDim2.new(0.04, 0, 0.04, 0),
		}):Play()
	end
	task.wait(0.40)

	-- Flash blanc
	local flash              = Instance.new("Frame")
	flash.Size               = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel    = 0
	flash.ZIndex             = 22
	flash.Parent             = AnimOverlay

	TweenService:Create(flash, TweenInfo.new(0.08), { BackgroundTransparency = 0 }):Play()
	task.wait(0.09)
	TweenService:Create(flash, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()

	-- Résultat
	local starsNum  = newStars
	local resultLbl                  = Instance.new("TextLabel")
	resultLbl.Size                   = UDim2.new(0.8, 0, 0.28, 0)
	resultLbl.AnchorPoint            = Vector2.new(0.5, 0.5)
	resultLbl.Position               = UDim2.new(0.5, 0, 0.48, 0)
	resultLbl.BackgroundTransparency = 1
	resultLbl.TextColor3             = starsColor(starsNum)
	resultLbl.TextStrokeTransparency = 0.3
	resultLbl.TextScaled             = true
	resultLbl.Font                   = Enum.Font.GothamBold
	resultLbl.Text                   = petName
		.. (if shiny then " ✨" else "")
		.. "\n" .. starsStr(starsNum)
	resultLbl.ZIndex                 = 23
	resultLbl.Parent                 = AnimOverlay

	local rs = Instance.new("UIScale"); rs.Scale = 0; rs.Parent = resultLbl
	TweenService:Create(rs,
		TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()

	task.wait(1.4)
	AnimOverlay.Visible = false
	isBusy = false
end

-- Reconstruction de la liste ------------------------------------------------

local function rebuild()
	for _, child in Scroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
	end

	-- Grouper l'inventaire
	type Group = {
		petId: string, rarity: string, stars: number, shiny: boolean,
		count: number, damage: number,
	}

	local groups: { [string]: Group } = {}
	local order:  { string }          = {}

	for _, pet in currentInventory do
		if (pet.stars :: number) >= (Fusion.MAX_STARS :: number) then continue end
		local key = pet.id .. "|" .. pet.rarity .. "|" .. pet.stars .. "|" .. tostring(pet.shiny)
		if not groups[key] then
			groups[key] = {
				petId  = pet.id,
				rarity = pet.rarity,
				stars  = pet.stars,
				shiny  = pet.shiny,
				count  = 0,
				damage = calcDamage(pet.id, pet.rarity, pet.stars, pet.shiny),
			}
			table.insert(order, key)
		end
		groups[key].count += 1
	end

	-- Trier : fusionnable d'abord, puis par dégâts décroissants
	table.sort(order, function(a, b)
		local ga, gb = groups[a], groups[b]
		local ca = ga.count >= currentRequired
		local cb = gb.count >= currentRequired
		if ca ~= cb then return ca end
		return ga.damage > gb.damage
	end)

	-- Ne montrer que les groupes avec au moins 1 exemplaire
	local layoutIdx = 0
	for _, key in order do
		local grp    = groups[key]
		local color  = RARITY_COLORS[grp.rarity] or Color3.fromRGB(200, 200, 200)
		local canFuse = grp.count >= currentRequired
		local newDmg  = calcDamage(grp.petId, grp.rarity, grp.stars + 1, grp.shiny)
		layoutIdx    += 1

		local Row              = Instance.new("Frame")
		Row.Size               = UDim2.new(1, 0, 0, 64)
		Row.BackgroundColor3   = if canFuse
			then color:Lerp(Color3.fromRGB(8, 5, 5), 0.78)
			else Color3.fromRGB(22, 16, 16)
		Row.BorderSizePixel    = 0
		Row.LayoutOrder        = layoutIdx
		Row.Parent             = Scroll
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = Row
			if canFuse then
				local s = Instance.new("UIStroke")
				s.Color = color; s.Thickness = 1.5; s.Parent = Row
			end
		end

		-- Carré couleur rareté
		local Badge            = Instance.new("Frame")
		Badge.Size             = UDim2.new(0, 8, 0.65, 0)
		Badge.Position         = UDim2.new(0, 7, 0.175, 0)
		Badge.BackgroundColor3 = color
		Badge.BorderSizePixel  = 0
		Badge.Parent           = Row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = Badge end

		-- Nom + étoiles actuelles
		local NameLbl                   = Instance.new("TextLabel")
		NameLbl.Size                    = UDim2.new(0.40, 0, 0.5, 0)
		NameLbl.Position                = UDim2.new(0.055, 0, 0.06, 0)
		NameLbl.BackgroundTransparency  = 1
		NameLbl.TextColor3              = Color3.fromRGB(255, 255, 255)
		NameLbl.TextScaled              = true
		NameLbl.Font                    = Enum.Font.GothamBold
		NameLbl.TextXAlignment          = Enum.TextXAlignment.Left
		NameLbl.Text                    = grp.petId .. (if grp.shiny then " ✨" else "")
		NameLbl.Parent                  = Row

		-- Progression étoiles : "★★ → ★★★"
		local StarsLbl                  = Instance.new("TextLabel")
		StarsLbl.Size                   = UDim2.new(0.40, 0, 0.42, 0)
		StarsLbl.Position               = UDim2.new(0.055, 0, 0.53, 0)
		StarsLbl.BackgroundTransparency = 1
		StarsLbl.TextColor3             = starsColor(grp.stars + 1)
		StarsLbl.TextScaled             = true
		StarsLbl.Font                   = Enum.Font.GothamBold
		StarsLbl.TextXAlignment         = Enum.TextXAlignment.Left
		StarsLbl.Text                   = (if grp.stars > 0 then starsStr(grp.stars) else "0★")
			.. " → " .. starsStr(grp.stars + 1)
		StarsLbl.Parent                 = Row

		-- Compteur (x/5)
		local CountLbl                  = Instance.new("TextLabel")
		CountLbl.Size                   = UDim2.new(0.22, 0, 0.5, 0)
		CountLbl.Position               = UDim2.new(0.45, 0, 0.04, 0)
		CountLbl.BackgroundTransparency = 1
		CountLbl.TextColor3             = if canFuse
			then Color3.fromRGB(100, 220, 120)
			else Color3.fromRGB(160, 110, 110)
		CountLbl.TextScaled             = true
		CountLbl.Font                   = Enum.Font.GothamBold
		CountLbl.TextXAlignment         = Enum.TextXAlignment.Center
		CountLbl.Text                   = grp.count .. "/" .. currentRequired
		CountLbl.Parent                 = Row

		-- Dégâts → nouveaux dégâts
		local DmgLbl                    = Instance.new("TextLabel")
		DmgLbl.Size                     = UDim2.new(0.22, 0, 0.42, 0)
		DmgLbl.Position                 = UDim2.new(0.45, 0, 0.54, 0)
		DmgLbl.BackgroundTransparency   = 1
		DmgLbl.TextColor3               = Color3.fromRGB(200, 150, 255)
		DmgLbl.TextScaled               = true
		DmgLbl.Font                     = Enum.Font.Gotham
		DmgLbl.TextXAlignment           = Enum.TextXAlignment.Center
		DmgLbl.Text                     = "→ " .. newDmg .. " dmg"
		DmgLbl.Parent                   = Row

		-- Bouton Fusionner
		local FuseBtn              = Instance.new("TextButton")
		FuseBtn.Size               = UDim2.new(0.25, 0, 0.72, 0)
		FuseBtn.AnchorPoint        = Vector2.new(1, 0.5)
		FuseBtn.Position           = UDim2.new(0.97, 0, 0.5, 0)
		FuseBtn.BackgroundColor3   = if canFuse
			then Color3.fromRGB(160, 70, 20)
			else Color3.fromRGB(60, 40, 30)
		FuseBtn.BorderSizePixel    = 0
		FuseBtn.Text               = if canFuse then "Fusionner" else "—"
		FuseBtn.TextColor3         = if canFuse
			then Color3.fromRGB(255, 220, 160)
			else Color3.fromRGB(100, 80, 70)
		FuseBtn.TextScaled         = true
		FuseBtn.Font               = Enum.Font.GothamBold
		FuseBtn.AutoButtonColor    = false
		FuseBtn.Active             = canFuse
		FuseBtn.Parent             = Row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = FuseBtn end

		if canFuse then
			local debounce = false
			FuseBtn.Activated:Connect(function()
				if debounce or isBusy then return end
				debounce = true

				local petId  = grp.petId
				local rarity = grp.rarity
				local stars  = grp.stars
				local shiny  = grp.shiny

				-- Lance l'animation en même temps que l'appel serveur
				local animDone = false
				task.spawn(function()
					playFusionAnimation(color, stars + 1, petId, shiny, currentRequired)
					animDone = true
				end)

				local ok, reason = pcall(function()
					return FusePets:InvokeServer(petId, rarity, stars, shiny)
				end)

				-- Attendre la fin de l'animation si elle tourne encore
				local guard = 0
				while not animDone and guard < 30 do
					task.wait(0.1); guard += 1
				end

				if not ok or reason == false then
					-- Échec : afficher brièvement dans le header
					local origText = TitleLbl.Text
					TitleLbl.Text = "❌ " .. (if typeof(reason) == "string" then reason else "Erreur")
					task.delay(2, function() TitleLbl.Text = origText end)
				end
				-- SyncData re-fire → rebuild() automatique
				debounce = false
			end)
		end
	end

	if layoutIdx == 0 then
		local EmptyLbl                   = Instance.new("TextLabel")
		EmptyLbl.Size                    = UDim2.new(1, 0, 0, 50)
		EmptyLbl.BackgroundTransparency  = 1
		EmptyLbl.TextColor3              = Color3.fromRGB(130, 100, 80)
		EmptyLbl.TextScaled              = true
		EmptyLbl.Font                    = Enum.Font.Gotham
		EmptyLbl.Text                    = "Aucune fusion disponible\n(besoin de " .. currentRequired .. " pets identiques)"
		EmptyLbl.Parent                  = Scroll
	end
end

-- FuseAll -------------------------------------------------------------------

local fuseAllDebounce = false
FuseAllBtn.Activated:Connect(function()
	if fuseAllDebounce or isBusy then return end
	fuseAllDebounce = true
	isBusy = true

	FuseAllBtn.Text = "..."

	local ok, created = pcall(function()
		return FuseAll:InvokeServer()
	end)

	isBusy = false
	FuseAllBtn.Text = "Fusionner tout"

	if ok and type(created) == "table" then
		local count = #created
		SummaryLbl.Text    = if count > 0
			then "✅ " .. count .. " fusion" .. (if count > 1 then "s" else "") .. " effectuée" .. (if count > 1 then "s" else "") .. " !"
			else "Rien à fusionner."
		SummaryLbl.Visible = true
		task.delay(3, function() SummaryLbl.Visible = false end)
	end

	-- SyncData re-fire → rebuild() automatique
	fuseAllDebounce = false
end)

-- Listeners -----------------------------------------------------------------

OpenBtn.Activated:Connect(function()
	isOpen = not isOpen
	Panel.Visible = isOpen
	if isOpen then rebuild() end
end)

CloseBtn.Activated:Connect(function()
	isOpen = false
	Panel.Visible = false
end)

SyncData.OnClientEvent:Connect(function(data: any)
	currentInventory = data.inventory  or {}
	currentRequired  = data.fusionRequired or 5
	if isOpen then rebuild() end
end)

return {}
