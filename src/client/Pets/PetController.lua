--!strict
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local SyncData    = Remotes:WaitForChild("SyncData",    15) :: RemoteEvent
local PetAttackRE = Remotes:WaitForChild("PetAttack",   15) :: RemoteEvent

local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(160, 160, 160),
	Uncommon  = Color3.fromRGB(80,  200, 80 ),
	Rare      = Color3.fromRGB(60,  130, 255),
	Epic      = Color3.fromRGB(160, 50,  255),
	Legendary = Color3.fromRGB(255, 185, 0  ),
	Mythic    = Color3.fromRGB(255, 70,  20 ),
	Secret    = Color3.fromRGB(30,  30,  30 ),
}

local inventoryMap:   { [string]: any }       = {}
local equippedUuids:  { string }              = {}
local petParts:       { [string]: Part }      = {}
local lunging:        { [string]: boolean }   = {}
-- Labels étoiles 4-5★ qui reçoivent une couleur arc-en-ciel animée
local rainbowLabels:  { [string]: TextLabel } = {}

local PetFolder      = Instance.new("Folder")
PetFolder.Name       = "PetModels"
PetFolder.Parent     = workspace

local function starsColor(stars: number): Color3
	if stars >= 4 then return Color3.fromRGB(255, 100, 255) end -- initial, mis à jour en Heartbeat
	if stars >= 1 then return Color3.fromRGB(255, 210, 50)  end -- doré
	return Color3.fromRGB(255, 255, 255)
end

local function spawnPart(uuid: string): Part
	local entry = inventoryMap[uuid]
	local part  = Instance.new("Part")
	part.Name       = "Pet_" .. uuid
	part.Size       = Vector3.new(1.5, 1.5, 1.5)
	part.Anchored   = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent     = PetFolder

	if entry then
		part.Color    = RARITY_COLORS[entry.rarity] or Color3.fromRGB(200, 200, 200)
		part.Material = if entry.shiny then Enum.Material.Neon else Enum.Material.SmoothPlastic

		local stars: number = entry.stars or 0
		local hasStars = stars > 0
		local guiH    = if hasStars then 44 else 28

		local gui            = Instance.new("BillboardGui")
		gui.Size             = UDim2.new(0, 130, 0, guiH)
		gui.StudsOffset      = Vector3.new(0, 1.6, 0)
		gui.AlwaysOnTop      = false
		gui.Parent           = part

		-- Label nom
		local nameLbl                    = Instance.new("TextLabel")
		nameLbl.Name                     = "NameLabel"
		nameLbl.Size                     = UDim2.new(1, 0, if hasStars then 0.52 else 1, 0)
		nameLbl.BackgroundTransparency   = 1
		nameLbl.TextColor3               = Color3.fromRGB(255, 255, 255)
		nameLbl.TextStrokeTransparency   = 0.3
		nameLbl.TextScaled               = true
		nameLbl.Font                     = Enum.Font.GothamBold
		nameLbl.Text                     = entry.id .. (if entry.shiny then " ✨" else "")
		nameLbl.Parent                   = gui

		-- Label étoiles (uniquement si stars > 0)
		if hasStars then
			local starsLbl                   = Instance.new("TextLabel")
			starsLbl.Name                    = "StarsLabel"
			starsLbl.Size                    = UDim2.new(1, 0, 0.44, 0)
			starsLbl.Position                = UDim2.new(0, 0, 0.54, 0)
			starsLbl.BackgroundTransparency  = 1
			starsLbl.TextColor3              = starsColor(stars)
			starsLbl.TextStrokeTransparency  = 0.4
			starsLbl.TextScaled              = true
			starsLbl.Font                    = Enum.Font.GothamBold
			starsLbl.Text                    = string.rep("★", stars)
			starsLbl.Parent                  = gui

			if stars >= 4 then
				rainbowLabels[uuid] = starsLbl
			end
		end
	end

	return part
end

local function rebuildModels()
	local equippedSet: { [string]: boolean } = {}
	for _, uuid in equippedUuids do equippedSet[uuid] = true end

	for uuid in petParts do
		if not equippedSet[uuid] then
			petParts[uuid]:Destroy()
			petParts[uuid]      = nil
			rainbowLabels[uuid] = nil
		end
	end

	for _, uuid in equippedUuids do
		if not petParts[uuid] then
			petParts[uuid] = spawnPart(uuid)
		end
	end
end

RunService.Heartbeat:Connect(function()
	local count = #equippedUuids
	if count == 0 then return end

	local character = LocalPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local t = tick()

	-- Orbite des pets
	for i, uuid in equippedUuids do
		if lunging[uuid] then continue end
		local part = petParts[uuid]
		if not part then continue end
		local angle  = (2 * math.pi * (i - 1) / count) + t * 1.5
		local radius = 3.5
		part.CFrame = CFrame.new(
			hrp.Position.X + math.cos(angle) * radius,
			hrp.Position.Y + 2 + math.sin(t * 2 + i) * 0.3,
			hrp.Position.Z + math.sin(angle) * radius
		)
	end

	-- Arc-en-ciel animé pour les étoiles 4-5★
	local hue = (t * 0.4) % 1
	for _, lbl in rainbowLabels do
		lbl.TextColor3 = Color3.fromHSV(hue, 1, 1)
	end
end)

PetAttackRE.OnClientEvent:Connect(function(uuid: string, targetPos: Vector3)
	if lunging[uuid] then return end
	local part = petParts[uuid]
	if not part then return end

	lunging[uuid] = true

	local dir  = (targetPos - part.Position)
	local dist = dir.Magnitude
	if dist < 0.5 then lunging[uuid] = false; return end

	local lungeTarget = part.Position + dir.Unit * math.min(dist * 0.7, 6)

	local t1 = TweenService:Create(
		part,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(lungeTarget) }
	)
	t1:Play()
	t1.Completed:Connect(function()
		task.delay(0.08, function()
			lunging[uuid] = false
		end)
	end)
end)

SyncData.OnClientEvent:Connect(function(data: any)
	table.clear(inventoryMap)
	for _, pet in data.inventory do
		inventoryMap[pet.uuid] = pet
	end
	equippedUuids = data.equippedPets
	rebuildModels()
end)

return {}
