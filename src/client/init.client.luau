--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

require(script.Pets.PetController)
require(script.UI.InventoryUI)
require(script.UI.XPBar)
require(script.UI.CombatFX)
require(script.UI.SkillTreeUI)
require(script.UI.FusionUI)

local ZoneController = require(script.Zones.ZoneController)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Remotes
local Remotes       = ReplicatedStorage:WaitForChild("Remotes", 15)
local RollEgg       = Remotes:WaitForChild("RollEgg",        15) :: RemoteFunction
local SyncSkillTree = Remotes:WaitForChild("SyncSkillTree",  15) :: RemoteEvent
local RollResult    = Remotes:WaitForChild("RollResult",     15) :: RemoteEvent
local SystemMessage = Remotes:WaitForChild("SystemMessage",  15) :: RemoteEvent

-- Couleurs par rareté
local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(160, 160, 160),
	Uncommon  = Color3.fromRGB(80,  200, 80 ),
	Rare      = Color3.fromRGB(60,  130, 255),
	Epic      = Color3.fromRGB(160, 50,  255),
	Legendary = Color3.fromRGB(255, 185, 0  ),
	Mythic    = Color3.fromRGB(255, 70,  20 ),
	Secret    = Color3.fromRGB(30,  30,  30 ),
}
local EPIC_PLUS: { [string]: boolean } = {
	Epic = true, Legendary = true, Mythic = true, Secret = true,
}

-- ScreenGui principal -------------------------------------------------------
local Gui            = Instance.new("ScreenGui")
Gui.Name             = "RollGui"
Gui.ResetOnSpawn     = false
Gui.IgnoreGuiInset   = true
Gui.Parent           = PlayerGui

-- Panneau résultat (Scale + centré) ----------------------------------------
local Panel              = Instance.new("Frame")
Panel.Name               = "ResultPanel"
Panel.Size               = UDim2.new(0.42, 0, 0.26, 0)
Panel.AnchorPoint        = Vector2.new(0.5, 0.5)
Panel.Position           = UDim2.new(0.5, 0, 0.44, 0)
Panel.BackgroundColor3   = Color3.fromRGB(20, 20, 30)
Panel.BorderSizePixel    = 0
Panel.Visible            = false
Panel.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = Panel
	local s = Instance.new("UIStroke"); s.Thickness = 3; s.Color = Color3.fromRGB(255, 185, 0); s.Parent = Panel
	local sc = Instance.new("UISizeConstraint"); sc.MaxSize = Vector2.new(380, 170); sc.Parent = Panel
end

local panelScale  = Instance.new("UIScale")
panelScale.Scale  = 0
panelScale.Parent = Panel

local RarityLbl                  = Instance.new("TextLabel")
RarityLbl.Size                   = UDim2.new(0.92, 0, 0.26, 0)
RarityLbl.Position               = UDim2.new(0.04, 0, 0.06, 0)
RarityLbl.BackgroundTransparency = 1
RarityLbl.TextColor3             = Color3.fromRGB(255, 185, 0)
RarityLbl.TextScaled             = true
RarityLbl.Font                   = Enum.Font.GothamBold
RarityLbl.TextXAlignment         = Enum.TextXAlignment.Center
RarityLbl.Parent                 = Panel

local PetLbl                     = Instance.new("TextLabel")
PetLbl.Size                      = UDim2.new(0.92, 0, 0.36, 0)
PetLbl.Position                  = UDim2.new(0.04, 0, 0.32, 0)
PetLbl.BackgroundTransparency    = 1
PetLbl.TextColor3                = Color3.fromRGB(255, 255, 255)
PetLbl.TextScaled                = true
PetLbl.Font                      = Enum.Font.GothamBold
PetLbl.TextXAlignment            = Enum.TextXAlignment.Center
PetLbl.Parent                    = Panel

local ShinyLbl                   = Instance.new("TextLabel")
ShinyLbl.Size                    = UDim2.new(0.92, 0, 0.2, 0)
ShinyLbl.Position                = UDim2.new(0.04, 0, 0.72, 0)
ShinyLbl.BackgroundTransparency  = 1
ShinyLbl.TextColor3              = Color3.fromRGB(255, 230, 60)
ShinyLbl.TextScaled              = true
ShinyLbl.Font                    = Enum.Font.GothamBold
ShinyLbl.Text                    = "✨ SHINY !"
ShinyLbl.TextXAlignment          = Enum.TextXAlignment.Center
ShinyLbl.Visible                 = false
ShinyLbl.Parent                  = Panel

local panelStroke = Panel:FindFirstChildWhichIsA("UIStroke") :: UIStroke

-- Bouton Auto-Roll ---------------------------------------------------------
local AutoBtn              = Instance.new("TextButton")
AutoBtn.Name               = "AutoRollBtn"
AutoBtn.Size               = UDim2.new(0.22, 0, 0.07, 0)
AutoBtn.AnchorPoint        = Vector2.new(0.5, 1)
AutoBtn.Position           = UDim2.new(0.5, 0, 0.97, 0)
AutoBtn.BackgroundColor3   = Color3.fromRGB(40, 80, 40)
AutoBtn.BorderSizePixel    = 0
AutoBtn.Text               = "AUTO: OFF"
AutoBtn.TextColor3         = Color3.fromRGB(100, 220, 100)
AutoBtn.TextScaled         = true
AutoBtn.Font               = Enum.Font.GothamBold
AutoBtn.AutoButtonColor    = false
AutoBtn.Visible            = false
AutoBtn.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = AutoBtn
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(60, 160, 60); s.Thickness = 2; s.Parent = AutoBtn
	local sc = Instance.new("UISizeConstraint"); sc.MaxSize = Vector2.new(180, 46); sc.Parent = AutoBtn
end

-- Toast notification (SystemMessage) --------------------------------------
local ToastFrame              = Instance.new("Frame")
ToastFrame.Name               = "ToastFrame"
ToastFrame.Size               = UDim2.new(0.5, 0, 0.07, 0)
ToastFrame.AnchorPoint        = Vector2.new(0.5, 0)
ToastFrame.Position           = UDim2.new(0.5, 0, 0.08, 0)
ToastFrame.BackgroundColor3   = Color3.fromRGB(15, 15, 25)
ToastFrame.BorderSizePixel    = 0
ToastFrame.Visible            = false
ToastFrame.Parent             = Gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = ToastFrame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(100, 80, 160); s.Thickness = 2; s.Parent = ToastFrame
	local sc = Instance.new("UISizeConstraint"); sc.MaxSize = Vector2.new(480, 52); sc.Parent = ToastFrame
end

local ToastLbl                  = Instance.new("TextLabel")
ToastLbl.Size                   = UDim2.new(1, -12, 1, 0)
ToastLbl.Position               = UDim2.new(0, 6, 0, 0)
ToastLbl.BackgroundTransparency = 1
ToastLbl.TextColor3             = Color3.fromRGB(220, 200, 255)
ToastLbl.TextScaled             = true
ToastLbl.Font                   = Enum.Font.GothamBold
ToastLbl.TextXAlignment         = Enum.TextXAlignment.Center
ToastLbl.Parent                 = ToastFrame

local toastTask: thread? = nil
SystemMessage.OnClientEvent:Connect(function(msg: string)
	if toastTask then task.cancel(toastTask); toastTask = nil end
	ToastLbl.Text     = msg
	ToastFrame.Visible = true
	toastTask = task.delay(3.5, function()
		ToastFrame.Visible = false
		toastTask = nil
	end)
end)

-- Affichage résultats -------------------------------------------------------
local SHOW_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HIDE_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local hideTask: thread? = nil

local function showResult(result: { id: string, rarity: string, shiny: boolean })
	if hideTask then task.cancel(hideTask); hideTask = nil end

	local color     = RARITY_COLORS[result.rarity] or Color3.fromRGB(200, 200, 200)
	local isSpecial = EPIC_PLUS[result.rarity] or result.shiny

	RarityLbl.Text         = result.rarity:upper()
	RarityLbl.TextColor3   = color
	PetLbl.Text            = result.id
	ShinyLbl.Visible       = result.shiny
	panelStroke.Color      = color
	Panel.BackgroundColor3 = color:Lerp(Color3.fromRGB(10, 10, 20), 0.82)

	Panel.Visible    = true
	panelScale.Scale = 0
	TweenService:Create(panelScale, SHOW_INFO, { Scale = 1 }):Play()

	local wait = if isSpecial then 4 else 2.5
	hideTask = task.delay(wait, function()
		local t = TweenService:Create(panelScale, HIDE_INFO, { Scale = 0 })
		t:Play()
		t.Completed:Wait()
		Panel.Visible = false
		hideTask = nil
	end)
end

local function showResults(results: { any })
	for i, entry in results do
		showResult(entry :: any)
		if i < #results then task.wait(0.5) end
	end
end

-- RollResult : ProximityPrompt déclenché côté serveur
RollResult.OnClientEvent:Connect(function(results: { any })
	task.spawn(showResults, results)
end)

-- État skills
local skillRollDelay    = 1.0
local skillAutoUnlocked = false

SyncSkillTree.OnClientEvent:Connect(function(data: any)
	local stats = data.stats or {}
	skillRollDelay    = (stats.rollDelay         or 1.0)  :: number
	skillAutoUnlocked = (stats.autoRollUnlocked  or false) :: boolean
	AutoBtn.Visible   = skillAutoUnlocked
end)

-- Auto-Roll -----------------------------------------------------------------
local isRolling     = false
local isAutoRolling = false
local autoThread: thread? = nil

local function doRoll(): boolean
	if isRolling then return false end
	local zoneName = ZoneController.GetNearestUnlockedZone()
	if not zoneName then return false end

	isRolling = true
	local ok, results = pcall(function()
		return RollEgg:InvokeServer(zoneName)
	end)
	isRolling = false

	if ok and results and type(results) == "table" and #results > 0 then
		task.spawn(showResults, results :: any)
		return true
	end
	return false
end

local function stopAutoRoll()
	isAutoRolling = false
	if autoThread then task.cancel(autoThread); autoThread = nil end
	AutoBtn.Text             = "AUTO: OFF"
	AutoBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
end

local function startAutoRoll()
	if isAutoRolling then return end
	isAutoRolling = true
	AutoBtn.Text             = "AUTO: ON"
	AutoBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 20)

	autoThread = task.spawn(function()
		while isAutoRolling do
			local success = doRoll()
			if not success then
				stopAutoRoll()
				break
			end
			task.wait(math.max(0.3, skillRollDelay))
		end
	end)
end

AutoBtn.Activated:Connect(function()
	if isAutoRolling then stopAutoRoll() else startAutoRoll() end
end)
