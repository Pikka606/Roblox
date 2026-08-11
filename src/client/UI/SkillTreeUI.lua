--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillTreeGolds = require(ReplicatedStorage.Shared.Config.SkillTreeGolds)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local BuySkill      = Remotes:WaitForChild("BuySkill",      15) :: RemoteFunction
local SyncSkillTree = Remotes:WaitForChild("SyncSkillTree", 15) :: RemoteEvent

-- État local
local cachedTree:  { [string]: number } = {}
local cachedStats: any = {}
local isOpen = false

local function getCurrentGolds(): number
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	if not ls then return 0 end
	local v = ls:FindFirstChild("Golds") :: IntValue?
	return if v then v.Value else 0
end

local function nodeCost(name: string, currentLevel: number): number
	local node = SkillTreeGolds[name]
	if not node then return math.huge end
	return math.round(node.costLevel1 * (node.costMult ^ currentLevel))
end

local function prereqsMet(name: string, tree: { [string]: number }): boolean
	local node = SkillTreeGolds[name]
	if not node then return false end
	local req = node.requires
	if not req then return true end
	return ((tree[req.node] or 0) :: number) >= (req.level :: number)
end

-- ScreenGui
local Gui            = Instance.new("ScreenGui")
Gui.Name             = "SkillTreeGui"
Gui.ResetOnSpawn     = false
Gui.IgnoreGuiInset   = true
Gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
Gui.Parent           = PlayerGui

-- Bouton d'ouverture
local OpenBtn              = Instance.new("TextButton")
OpenBtn.Size               = UDim2.new(0.12, 0, 0.09, 0)
OpenBtn.AnchorPoint        = Vector2.new(0, 0.5)
OpenBtn.Position           = UDim2.new(0.01, 0, 0.62, 0)
OpenBtn.BackgroundColor3   = Color3.fromRGB(55, 35, 80)
OpenBtn.BorderSizePixel    = 0
OpenBtn.Text               = "Skills"
OpenBtn.TextColor3         = Color3.fromRGB(220, 180, 255)
OpenBtn.TextScaled         = true
OpenBtn.Font               = Enum.Font.GothamBold
OpenBtn.AutoButtonColor    = false
OpenBtn.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = OpenBtn
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(130, 80, 200); s.Thickness = 2; s.Parent = OpenBtn
	local sc = Instance.new("UISizeConstraint"); sc.MaxSize = Vector2.new(130, 56); sc.Parent = OpenBtn
end

-- Panneau principal
local Panel              = Instance.new("Frame")
Panel.Name               = "SkillPanel"
Panel.Size               = UDim2.new(0.55, 0, 0.88, 0)
Panel.AnchorPoint        = Vector2.new(0.5, 0.5)
Panel.Position           = UDim2.new(0.5, 0, 0.5, 0)
Panel.BackgroundColor3   = Color3.fromRGB(14, 10, 22)
Panel.BorderSizePixel    = 0
Panel.Visible            = false
Panel.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Panel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(100, 60, 160); s.Thickness = 2; s.Parent = Panel
	local sc = Instance.new("UISizeConstraint")
	sc.MaxSize = Vector2.new(480, 560)
	sc.Parent  = Panel
end

local contentScale   = Instance.new("UIScale")
contentScale.Scale   = 1
contentScale.Parent  = Panel
Panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	contentScale.Scale = math.clamp(Panel.AbsoluteSize.Y / 480, 0.5, 1.1)
end)
task.defer(function() contentScale.Scale = math.clamp(Panel.AbsoluteSize.Y / 480, 0.5, 1.1) end)

-- Header
local Header             = Instance.new("Frame")
Header.Size              = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3  = Color3.fromRGB(28, 18, 46)
Header.BorderSizePixel   = 0
Header.Parent            = Panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Header end

local TitleLbl                  = Instance.new("TextLabel")
TitleLbl.Size                   = UDim2.new(0.6, 0, 1, 0)
TitleLbl.Position               = UDim2.new(0.03, 0, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.TextColor3             = Color3.fromRGB(220, 180, 255)
TitleLbl.TextScaled             = true
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.Text                   = "ARBRE GOLDS"
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.Parent                 = Header

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

-- Scroll
local Scroll                      = Instance.new("ScrollingFrame")
Scroll.Size                       = UDim2.new(1, -12, 1, -60)
Scroll.Position                   = UDim2.new(0, 6, 0, 56)
Scroll.BackgroundTransparency     = 1
Scroll.BorderSizePixel            = 0
Scroll.ScrollBarThickness         = 5
Scroll.ScrollBarImageColor3       = Color3.fromRGB(110, 70, 180)
Scroll.AutomaticCanvasSize        = Enum.AutomaticSize.Y
Scroll.CanvasSize                 = UDim2.new(0, 0, 0, 0)
Scroll.Parent                     = Panel

local ListLayout         = Instance.new("UIListLayout")
ListLayout.SortOrder     = Enum.SortOrder.LayoutOrder
ListLayout.Padding       = UDim.new(0, 4)
ListLayout.Parent        = Scroll

local ListPadding        = Instance.new("UIPadding")
ListPadding.PaddingTop   = UDim.new(0, 4)
ListPadding.PaddingBottom = UDim.new(0, 6)
ListPadding.PaddingLeft  = UDim.new(0, 5)
ListPadding.PaddingRight = UDim.new(0, 5)
ListPadding.Parent       = Scroll

-- Sections d'affichage (ordre logique de l'arbre)
local SECTIONS = {
	{ label = "⚔ Dégâts",        nodes = { "DegatsI", "DegatsII" } },
	{ label = "💰 Économie",      nodes = { "GainsI",  "GainsII"  } },
	{ label = "🍀 Chance & Rolls", nodes = { "LuckI", "LuckII", "RollRapide", "AutoRoll", "MultiRollX3" } },
	{ label = "🐾 Équipe",         nodes = { "EquipeBonus" } },
}

local INDENT: { [string]: number } = {
	DegatsI     = 0, DegatsII  = 1, EquipeBonus  = 1,
	GainsI      = 0, GainsII   = 1,
	LuckI       = 0, LuckII    = 1, RollRapide = 1, AutoRoll = 2, MultiRollX3 = 3,
}

local function rebuild()
	for _, child in Scroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local golds      = getCurrentGolds()
	local tree       = cachedTree
	local layoutIdx  = 0

	for _, section in SECTIONS do
		layoutIdx += 1

		-- Entête de section
		local SectionLbl                  = Instance.new("TextLabel")
		SectionLbl.Size                   = UDim2.new(1, 0, 0, 28)
		SectionLbl.BackgroundColor3       = Color3.fromRGB(30, 18, 50)
		SectionLbl.BackgroundTransparency = 0
		SectionLbl.TextColor3             = Color3.fromRGB(200, 160, 255)
		SectionLbl.TextScaled             = true
		SectionLbl.Font                   = Enum.Font.GothamBold
		SectionLbl.Text                   = section.label
		SectionLbl.TextXAlignment         = Enum.TextXAlignment.Left
		SectionLbl.BorderSizePixel        = 0
		SectionLbl.LayoutOrder            = layoutIdx
		SectionLbl.Parent                 = Scroll
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = SectionLbl
			local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 10); p.Parent = SectionLbl
		end

		for _, nodeName in section.nodes do
			layoutIdx += 1
			local node         = SkillTreeGolds[nodeName]
			if not node then continue end

			local currentLevel = (tree[nodeName] or 0) :: number
			local maxLevel     = node.maxLevel :: number
			local cost         = nodeCost(nodeName, currentLevel)
			local indent       = (INDENT[nodeName] or 0) * 14

			-- Déterminer l'état
			local isMax      = currentLevel >= maxLevel
			local isLocked   = not prereqsMet(nodeName, tree)
			local canAfford  = golds >= cost
			local req        = node.requires

			local stateBg: Color3
			local stateText: string
			local stateColor: Color3

			if isMax then
				stateBg    = Color3.fromRGB(50, 40, 10)
				stateText  = "MAX ★"
				stateColor = Color3.fromRGB(255, 210, 50)
			elseif isLocked then
				stateBg    = Color3.fromRGB(28, 22, 36)
				stateText  = "🔒 " .. (req and (req.node .. " niv." .. req.level) or "")
				stateColor = Color3.fromRGB(130, 100, 160)
			elseif canAfford then
				stateBg    = Color3.fromRGB(20, 36, 22)
				stateText  = "Acheter\n" .. cost .. " g"
				stateColor = Color3.fromRGB(80, 220, 100)
			else
				stateBg    = Color3.fromRGB(36, 22, 22)
				stateText  = "Coût :\n" .. cost .. " g"
				stateColor = Color3.fromRGB(200, 80, 80)
			end

			local Row              = Instance.new("Frame")
			Row.Size               = UDim2.new(1, -indent, 0, 68)
			Row.Position           = UDim2.new(0, indent, 0, 0)
			Row.BackgroundColor3   = stateBg
			Row.BorderSizePixel    = 0
			Row.LayoutOrder        = layoutIdx
			Row.Parent             = Scroll
			do
				local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = Row
				if not isMax and not isLocked then
					local s = Instance.new("UIStroke")
					s.Color     = if canAfford then Color3.fromRGB(60, 180, 70) else Color3.fromRGB(160, 60, 60)
					s.Thickness = 1.5
					s.Parent    = Row
				end
			end

			-- Nom + niveau
			local NameLbl                   = Instance.new("TextLabel")
			NameLbl.Size                    = UDim2.new(0.52, 0, 0.48, 0)
			NameLbl.Position                = UDim2.new(0.02, 0, 0.05, 0)
			NameLbl.BackgroundTransparency  = 1
			NameLbl.TextColor3              = Color3.fromRGB(240, 240, 255)
			NameLbl.TextScaled              = true
			NameLbl.Font                    = Enum.Font.GothamBold
			NameLbl.TextXAlignment          = Enum.TextXAlignment.Left
			NameLbl.Text                    = node.displayName
			NameLbl.Parent                  = Row

			local LevelLbl                  = Instance.new("TextLabel")
			LevelLbl.Size                   = UDim2.new(0.22, 0, 0.48, 0)
			LevelLbl.Position               = UDim2.new(0.53, 0, 0.05, 0)
			LevelLbl.BackgroundTransparency = 1
			LevelLbl.TextColor3             = if isMax then Color3.fromRGB(255, 210, 50) else Color3.fromRGB(160, 200, 255)
			LevelLbl.TextScaled             = true
			LevelLbl.Font                   = Enum.Font.GothamBold
			LevelLbl.TextXAlignment         = Enum.TextXAlignment.Center
			LevelLbl.Text                   = currentLevel .. "/" .. maxLevel
			LevelLbl.Parent                 = Row

			-- Effet
			local EffectLbl                 = Instance.new("TextLabel")
			EffectLbl.Size                  = UDim2.new(0.75, 0, 0.44, 0)
			EffectLbl.Position              = UDim2.new(0.02, 0, 0.52, 0)
			EffectLbl.BackgroundTransparency = 1
			EffectLbl.TextColor3            = Color3.fromRGB(160, 160, 200)
			EffectLbl.TextScaled            = true
			EffectLbl.Font                  = Enum.Font.Gotham
			EffectLbl.TextXAlignment        = Enum.TextXAlignment.Left
			EffectLbl.Text                  = node.effect
			EffectLbl.Parent                = Row

			-- Bouton d'action (droite)
			local ActionBtn              = Instance.new("TextButton")
			ActionBtn.Size               = UDim2.new(0.22, 0, 0.8, 0)
			ActionBtn.AnchorPoint        = Vector2.new(1, 0.5)
			ActionBtn.Position           = UDim2.new(0.98, 0, 0.5, 0)
			ActionBtn.BackgroundColor3   = stateColor:Lerp(Color3.fromRGB(10, 10, 20), 0.55)
			ActionBtn.BorderSizePixel    = 0
			ActionBtn.Text               = stateText
			ActionBtn.TextColor3         = stateColor
			ActionBtn.TextScaled         = true
			ActionBtn.Font               = Enum.Font.GothamBold
			ActionBtn.AutoButtonColor    = false
			ActionBtn.Active             = (not isMax) and (not isLocked) and canAfford
			ActionBtn.Parent             = Row
			do
				local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = ActionBtn
			end

			if (not isMax) and (not isLocked) and canAfford then
				local debounce = false
				ActionBtn.Activated:Connect(function()
					if debounce then return end
					debounce = true
					local ok, success = pcall(function()
						return BuySkill:InvokeServer(nodeName)
					end)
					-- SyncSkillTree fired by server si succès → rebuild() automatique
					-- Si échec, libérer le debounce pour permettre de réessayer
					if not ok or not success then debounce = false end
				end)
			end
		end
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

SyncSkillTree.OnClientEvent:Connect(function(data: any)
	cachedTree  = data.skillTreeGolds or {}
	cachedStats = data.stats or {}
	if isOpen then rebuild() end
end)

return {}
