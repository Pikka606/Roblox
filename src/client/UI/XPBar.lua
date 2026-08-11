--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local SyncStats  = Remotes:WaitForChild("SyncStats", 15) :: RemoteEvent

-- ScreenGui
local Gui            = Instance.new("ScreenGui")
Gui.Name             = "XPBarGui"
Gui.ResetOnSpawn     = false
Gui.IgnoreGuiInset   = true
Gui.DisplayOrder     = 5
Gui.Parent           = PlayerGui

-- Conteneur principal — bande en haut, Scale en largeur, hauteur fixe
local Container              = Instance.new("Frame")
Container.Name               = "XPContainer"
Container.Size               = UDim2.new(0.5, 0, 0, 36)
Container.AnchorPoint        = Vector2.new(0.5, 0)
Container.Position           = UDim2.new(0.5, 0, 0, 6)
Container.BackgroundColor3   = Color3.fromRGB(14, 14, 22)
Container.BorderSizePixel    = 0
Container.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = Container
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(60, 60, 100); s.Thickness = 1; s.Parent = Container
	local sc = Instance.new("UISizeConstraint")
	sc.MinSize = Vector2.new(260, 36)
	sc.MaxSize = Vector2.new(520, 44)
	sc.Parent  = Container
end

-- Label niveau (gauche)
local LevelLbl                  = Instance.new("TextLabel")
LevelLbl.Name                   = "LevelLabel"
LevelLbl.Size                   = UDim2.new(0.14, 0, 1, 0)
LevelLbl.Position               = UDim2.new(0, 0, 0, 0)
LevelLbl.BackgroundTransparency = 1
LevelLbl.TextColor3             = Color3.fromRGB(255, 210, 60)
LevelLbl.TextScaled             = true
LevelLbl.Font                   = Enum.Font.GothamBold
LevelLbl.Text                   = "Niv. 1"
LevelLbl.TextXAlignment         = Enum.TextXAlignment.Center
LevelLbl.Parent                 = Container

-- Barre XP (milieu)
local BarBg              = Instance.new("Frame")
BarBg.Name               = "BarBg"
BarBg.Size               = UDim2.new(0.58, 0, 0.5, 0)
BarBg.Position           = UDim2.new(0.15, 0, 0.25, 0)
BarBg.BackgroundColor3   = Color3.fromRGB(30, 30, 50)
BarBg.BorderSizePixel    = 0
BarBg.Parent             = Container
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = BarBg
end

local BarFill            = Instance.new("Frame")
BarFill.Name             = "BarFill"
BarFill.Size             = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
BarFill.BorderSizePixel  = 0
BarFill.Parent           = BarBg
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = BarFill

	-- Reflet brillant sur la barre
	local shine              = Instance.new("Frame")
	shine.Size               = UDim2.new(1, 0, 0.45, 0)
	shine.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.75
	shine.BorderSizePixel    = 0
	shine.Parent             = BarFill
	local cs = Instance.new("UICorner"); cs.CornerRadius = UDim.new(1, 0); cs.Parent = shine
end

-- Label XP fraction (droite)
local XPLbl                  = Instance.new("TextLabel")
XPLbl.Name                   = "XPLabel"
XPLbl.Size                   = UDim2.new(0.28, 0, 1, 0)
XPLbl.Position               = UDim2.new(0.72, 0, 0, 0)
XPLbl.BackgroundTransparency = 1
XPLbl.TextColor3             = Color3.fromRGB(180, 200, 255)
XPLbl.TextScaled             = true
XPLbl.Font                   = Enum.Font.Gotham
XPLbl.Text                   = "0 / 100 XP"
XPLbl.TextXAlignment         = Enum.TextXAlignment.Center
XPLbl.Parent                 = Container

-- Mise à jour
local function update(data: { xp: number, level: number, xpNeeded: number })
	LevelLbl.Text = "Niv. " .. data.level
	XPLbl.Text    = data.xp .. " / " .. data.xpNeeded .. " XP"
	local ratio   = math.clamp(data.xp / math.max(data.xpNeeded, 1), 0, 1)
	BarFill.Size  = UDim2.new(ratio, 0, 1, 0)
end

SyncStats.OnClientEvent:Connect(function(data: any)
	update({ xp = data.xp, level = data.level, xpNeeded = data.xpNeeded })
end)

return {}
