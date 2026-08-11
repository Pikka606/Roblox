--!strict
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local ShowDamage  = Remotes:WaitForChild("ShowDamage", 15) :: RemoteEvent

local TWEEN_INFO  = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

ShowDamage.OnClientEvent:Connect(function(worldPos: Vector3, damage: number)
	-- Part invisible servant d'ancre au BillboardGui
	local anchor          = Instance.new("Part")
	anchor.Anchored       = true
	anchor.CanCollide     = false
	anchor.Transparency   = 1
	anchor.Size           = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame         = CFrame.new(worldPos)
	anchor.Parent         = workspace

	local gui             = Instance.new("BillboardGui")
	gui.Size              = UDim2.new(0, 70, 0, 36)
	gui.AlwaysOnTop       = true
	gui.StudsOffset       = Vector3.new(0, 0, 0)
	gui.Parent            = anchor

	local lbl                    = Instance.new("TextLabel")
	lbl.Size                     = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency   = 1
	lbl.TextColor3               = Color3.fromRGB(255, 80, 80)
	lbl.TextScaled               = true
	lbl.Font                     = Enum.Font.GothamBold
	lbl.TextStrokeTransparency   = 0.2
	lbl.TextStrokeColor3         = Color3.fromRGB(80, 0, 0)
	lbl.Text                     = "-" .. tostring(damage)
	lbl.Parent                   = gui

	-- Monte et s'efface
	local endPos = CFrame.new(worldPos + Vector3.new(0, 5, 0))
	TweenService:Create(anchor, TWEEN_INFO, { CFrame = endPos }):Play()

	task.delay(0.25, function()
		TweenService:Create(lbl, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency      = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)

	task.delay(0.95, function()
		anchor:Destroy()
	end)
end)

return {}
