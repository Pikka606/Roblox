--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Pets     = require(ReplicatedStorage.Shared.Config.Pets)
local Fusion   = require(ReplicatedStorage.Shared.Config.Fusion)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes  = ReplicatedStorage:WaitForChild("Remotes")
local SyncData = Remotes:WaitForChild("SyncData",  15) :: RemoteEvent
local EquipPet = Remotes:WaitForChild("EquipPet",  15) :: RemoteFunction

local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(160, 160, 160),
	Uncommon  = Color3.fromRGB(80,  200, 80 ),
	Rare      = Color3.fromRGB(60,  130, 255),
	Epic      = Color3.fromRGB(160, 50,  255),
	Legendary = Color3.fromRGB(255, 185, 0  ),
	Mythic    = Color3.fromRGB(255, 70,  20 ),
	Secret    = Color3.fromRGB(30,  30,  30 ),
}

local currentInventory: { any } = {}
local currentEquipped:  { string } = {}
local currentMaxSlots:  number = 3
local equippedSet:      { [string]: boolean } = {}
local isOpen = false

-- ScreenGui
local Gui            = Instance.new("ScreenGui")
Gui.Name             = "InventoryGui"
Gui.ResetOnSpawn     = false
Gui.IgnoreGuiInset   = true
Gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
Gui.Parent           = PlayerGui

-- Bouton d'ouverture — Scale, ancré à gauche-milieu
local OpenBtn              = Instance.new("TextButton")
OpenBtn.Name               = "OpenBtn"
OpenBtn.Size               = UDim2.new(0.12, 0, 0.09, 0)
OpenBtn.AnchorPoint        = Vector2.new(0, 0.5)
OpenBtn.Position           = UDim2.new(0.01, 0, 0.5, 0)
OpenBtn.BackgroundColor3   = Color3.fromRGB(40, 40, 65)
OpenBtn.BorderSizePixel    = 0
OpenBtn.Text               = "Pets"
OpenBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
OpenBtn.TextScaled         = true
OpenBtn.Font               = Enum.Font.GothamBold
OpenBtn.AutoButtonColor    = false
OpenBtn.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = OpenBtn
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(90, 90, 160); s.Thickness = 2; s.Parent = OpenBtn
	local sc = Instance.new("UISizeConstraint"); sc.MaxSize = Vector2.new(130, 56); sc.Parent = OpenBtn
end

-- Panneau principal — Scale, centré, capé en taille pour le desktop
local Panel              = Instance.new("Frame")
Panel.Name               = "InventoryPanel"
Panel.Size               = UDim2.new(0.55, 0, 0.88, 0)
Panel.AnchorPoint        = Vector2.new(0.5, 0.5)
Panel.Position           = UDim2.new(0.5, 0, 0.5, 0)
Panel.BackgroundColor3   = Color3.fromRGB(16, 16, 26)
Panel.BorderSizePixel    = 0
Panel.Visible            = false
Panel.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Panel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(70, 70, 120); s.Thickness = 2; s.Parent = Panel
	local sc = Instance.new("UISizeConstraint")
	sc.MaxSize = Vector2.new(480, 560)
	sc.Parent  = Panel
end

-- UIScale interne au panneau — ajuste le contenu à la taille réelle du panneau
-- (la référence de design est 480 × 560 ; sur mobile le panneau est plus petit)
local contentScale       = Instance.new("UIScale")
contentScale.Scale       = 1
contentScale.Parent      = Panel

local function refreshContentScale()
	contentScale.Scale = math.clamp(Panel.AbsoluteSize.Y / 480, 0.5, 1.1)
end
Panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshContentScale)
task.defer(refreshContentScale)

-- Header
local Header             = Instance.new("Frame")
Header.Size              = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3  = Color3.fromRGB(28, 28, 48)
Header.BorderSizePixel   = 0
Header.Parent            = Panel
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Header
end

local TitleLbl                  = Instance.new("TextLabel")
TitleLbl.Size                   = UDim2.new(0.6, 0, 1, 0)
TitleLbl.Position               = UDim2.new(0.03, 0, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
TitleLbl.TextScaled             = true
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.Text                   = "INVENTAIRE PETS"
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.Parent                 = Header

local SlotLbl                   = Instance.new("TextLabel")
SlotLbl.Size                    = UDim2.new(0.28, 0, 1, 0)
SlotLbl.Position                = UDim2.new(0.63, 0, 0, 0)
SlotLbl.BackgroundTransparency  = 1
SlotLbl.TextColor3              = Color3.fromRGB(255, 200, 80)
SlotLbl.TextScaled              = true
SlotLbl.Font                    = Enum.Font.GothamBold
SlotLbl.Text                    = "0/3 équipés"
SlotLbl.TextXAlignment          = Enum.TextXAlignment.Right
SlotLbl.Parent                  = Header

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
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = CloseBtn
end

-- ScrollFrame
local Scroll                       = Instance.new("ScrollingFrame")
Scroll.Size                        = UDim2.new(1, -12, 1, -60)
Scroll.Position                    = UDim2.new(0, 6, 0, 56)
Scroll.BackgroundTransparency      = 1
Scroll.BorderSizePixel             = 0
Scroll.ScrollBarThickness          = 5
Scroll.ScrollBarImageColor3        = Color3.fromRGB(90, 90, 150)
Scroll.AutomaticCanvasSize         = Enum.AutomaticSize.Y
Scroll.CanvasSize                  = UDim2.new(0, 0, 0, 0)
Scroll.Parent                      = Panel

local ListLayout         = Instance.new("UIListLayout")
ListLayout.SortOrder     = Enum.SortOrder.LayoutOrder
ListLayout.Padding       = UDim.new(0, 5)
ListLayout.Parent        = Scroll

local ListPadding               = Instance.new("UIPadding")
ListPadding.PaddingTop          = UDim.new(0, 5)
ListPadding.PaddingBottom       = UDim.new(0, 5)
ListPadding.PaddingLeft         = UDim.new(0, 5)
ListPadding.PaddingRight        = UDim.new(0, 5)
ListPadding.Parent              = Scroll

-- Helpers
local function calcDamage(petId: string, rarity: string, stars: number, shiny: boolean): number
	local petCfg    = Pets[petId]
	local rarityCfg = Rarities[rarity]
	if not petCfg or not rarityCfg then return 0 end
	local base        = petCfg.baseDamage * rarityCfg.damageMult
	local fusionEntry = if stars > 0 then Fusion.Stars[stars - 1] else nil
	local starsMult   = if fusionEntry then fusionEntry.cumulative else 1
	local shinyMult   = if shiny then (Rarities.SHINY_STATS_MULT :: number) else 1
	return math.floor(base * starsMult * shinyMult)
end

local function starsStr(stars: number): string
	return if stars > 0 then (" " .. string.rep("★", stars)) else ""
end

local function rebuild()
	for _, child in Scroll:GetChildren() do
		if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
	end

	table.clear(equippedSet)
	for _, uuid in currentEquipped do equippedSet[uuid] = true end

	SlotLbl.Text = (#currentEquipped) .. "/" .. currentMaxSlots .. " équipés"

	type Group = { id: string, rarity: string, stars: number, shiny: boolean, uuids: { string }, damage: number }

	local groupMap: { [string]: Group } = {}
	local groupOrder: { string } = {}

	for _, pet in currentInventory do
		local key = pet.id .. "|" .. pet.rarity .. "|" .. pet.stars .. "|" .. tostring(pet.shiny)
		if not groupMap[key] then
			groupMap[key] = {
				id     = pet.id,
				rarity = pet.rarity,
				stars  = pet.stars,
				shiny  = pet.shiny,
				uuids  = {},
				damage = calcDamage(pet.id, pet.rarity, pet.stars, pet.shiny),
			}
			table.insert(groupOrder, key)
		end
		table.insert(groupMap[key].uuids, pet.uuid)
	end

	table.sort(groupOrder, function(a, b)
		return groupMap[a].damage > groupMap[b].damage
	end)

	for idx, key in groupOrder do
		local grp   = groupMap[key]
		local count = #grp.uuids
		local eqCount = 0
		for _, uuid in grp.uuids do
			if equippedSet[uuid] then eqCount += 1 end
		end

		local color = RARITY_COLORS[grp.rarity] or Color3.fromRGB(200, 200, 200)

		local Row              = Instance.new("TextButton")
		Row.Size               = UDim2.new(1, 0, 0, 58)
		Row.BackgroundColor3   = if eqCount > 0
			then color:Lerp(Color3.fromRGB(8, 8, 18), 0.72)
			else Color3.fromRGB(26, 26, 40)
		Row.BorderSizePixel    = 0
		Row.Text               = ""
		Row.AutoButtonColor    = false
		Row.LayoutOrder        = idx
		Row.Parent             = Scroll
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = Row
			if eqCount > 0 then
				local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = 2; s.Parent = Row
			end
		end

		-- Bande couleur rareté
		local Badge              = Instance.new("Frame")
		Badge.Size               = UDim2.new(0, 8, 0.65, 0)
		Badge.Position           = UDim2.new(0, 8, 0.175, 0)
		Badge.BackgroundColor3   = color
		Badge.BorderSizePixel    = 0
		Badge.Parent             = Row
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = Badge
		end

		-- Nom + étoiles + shiny + quantité
		local NameLbl                   = Instance.new("TextLabel")
		NameLbl.Size                    = UDim2.new(0.5, 0, 0.52, 0)
		NameLbl.Position                = UDim2.new(0.06, 0, 0.1, 0)
		NameLbl.BackgroundTransparency  = 1
		NameLbl.TextColor3              = Color3.fromRGB(255, 255, 255)
		NameLbl.TextScaled              = true
		NameLbl.Font                    = Enum.Font.GothamBold
		NameLbl.TextXAlignment          = Enum.TextXAlignment.Left
		NameLbl.Text                    = grp.id
			.. starsStr(grp.stars)
			.. (if grp.shiny then " ✨" else "")
			.. (if count > 1 then ("  ×" .. count) else "")
		NameLbl.Parent                  = Row

		-- Rareté
		local RarLbl                    = Instance.new("TextLabel")
		RarLbl.Size                     = UDim2.new(0.5, 0, 0.38, 0)
		RarLbl.Position                 = UDim2.new(0.06, 0, 0.58, 0)
		RarLbl.BackgroundTransparency   = 1
		RarLbl.TextColor3               = color
		RarLbl.TextScaled               = true
		RarLbl.Font                     = Enum.Font.Gotham
		RarLbl.TextXAlignment           = Enum.TextXAlignment.Left
		RarLbl.Text                     = grp.rarity
		RarLbl.Parent                   = Row

		-- Dégâts
		local DmgLbl                    = Instance.new("TextLabel")
		DmgLbl.Size                     = UDim2.new(0.28, 0, 1, 0)
		DmgLbl.Position                 = UDim2.new(0.56, 0, 0, 0)
		DmgLbl.BackgroundTransparency   = 1
		DmgLbl.TextColor3               = Color3.fromRGB(255, 120, 120)
		DmgLbl.TextScaled               = true
		DmgLbl.Font                     = Enum.Font.GothamBold
		DmgLbl.TextXAlignment           = Enum.TextXAlignment.Right
		DmgLbl.Text                     = grp.damage .. " dmg"
		DmgLbl.Parent                   = Row

		-- Indicateur équipé
		if eqCount > 0 then
			local EqLbl                  = Instance.new("TextLabel")
			EqLbl.Size                   = UDim2.new(0.18, 0, 1, 0)
			EqLbl.Position               = UDim2.new(0.82, 0, 0, 0)
			EqLbl.BackgroundTransparency = 1
			EqLbl.TextColor3             = Color3.fromRGB(80, 255, 120)
			EqLbl.TextScaled             = true
			EqLbl.Font                   = Enum.Font.GothamBold
			EqLbl.TextXAlignment         = Enum.TextXAlignment.Right
			EqLbl.Text                   = "✓ " .. eqCount
			EqLbl.Parent                 = Row
		end

		-- Clic : équiper/déséquiper
		local debounce = false
		Row.Activated:Connect(function()
			if debounce then return end
			debounce = true

			local currentEqCount = 0
			for _, u in grp.uuids do
				if equippedSet[u] then currentEqCount += 1 end
			end

			local targetUuid: string? = nil
			if currentEqCount > 0 then
				for _, u in grp.uuids do
					if equippedSet[u] then targetUuid = u; break end
				end
			else
				for _, u in grp.uuids do
					if not equippedSet[u] then targetUuid = u; break end
				end
			end

			if targetUuid then
				pcall(function()
					EquipPet:InvokeServer(targetUuid)
				end)
			end

			debounce = false
		end)
	end
end

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
	currentInventory = data.inventory
	currentEquipped  = data.equippedPets
	currentMaxSlots  = data.maxSlots or 3
	if isOpen then rebuild() end
end)

return {}
