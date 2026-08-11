--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local SyncZones  = Remotes:WaitForChild("SyncZones", 15) :: RemoteEvent

local STATION_CLIENT_RANGE = 30  -- studs : rayon détection zone pour auto-roll

local ZoneController = {}

-- Zones débloquées (reçues du serveur)
local unlockedSet: { [string]: boolean } = { Prairie = true }

-- Mise à jour visuelle des portes (locale, sans répercussion serveur) --------
local function updateGates(unlockedZones: { string })
	unlockedSet = {}
	for _, z in unlockedZones do unlockedSet[z] = true end

	local zonesFolder = workspace:FindFirstChild("Zones") :: Folder?
	if not zonesFolder then return end

	for _, child in zonesFolder:GetChildren() do
		if not child:IsA("Folder") then continue end
		local gate = child:FindFirstChild("Gate")
		if not gate or not gate:IsA("BasePart") then continue end
		local gatePart = gate :: BasePart

		if unlockedSet[child.Name] then
			-- Rendre la porte traversable et invisible localement
			gatePart.CanCollide  = false
			gatePart.Transparency = 1
			local pp = gatePart:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt?
			if pp then pp.Enabled = false end
		else
			gatePart.CanCollide   = true
			gatePart.Transparency = 0
		end
	end
end

SyncZones.OnClientEvent:Connect(function(zones: { string })
	updateGates(zones)
	-- Mettre à jour les portes au moment où elles apparaissent dans le workspace
	-- (cas où SyncZones arrive avant que Workspace.Zones soit chargé)
	task.defer(function() updateGates(zones) end)
end)

-- Gère le respawn du personnage (les changements locaux sur les Parts workspace persistent,
-- mais on reforce au cas où le serveur réinitialise les valeurs)
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	local zonesFolder = workspace:FindFirstChild("Zones") :: Folder?
	if not zonesFolder then return end
	local currentUnlocked: { string } = {}
	for z, _ in unlockedSet do table.insert(currentUnlocked, z) end
	updateGates(currentUnlocked)
end)

-- API : zone la plus proche avec un RollStation (pour auto-roll) ------------
function ZoneController.GetNearestUnlockedZone(): string?
	local char = LocalPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil end

	local zonesFolder = workspace:FindFirstChild("Zones") :: Folder?
	if not zonesFolder then return nil end

	local nearest: string? = nil
	local nearestDist       = STATION_CLIENT_RANGE

	for _, child in zonesFolder:GetChildren() do
		if not child:IsA("Folder") then continue end
		if not unlockedSet[child.Name] then continue end

		local station = child:FindFirstChild("RollStation")
		if not station or not station:IsA("BasePart") then continue end

		local dist = (hrp.Position - (station :: BasePart).Position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearest     = child.Name
		end
	end

	return nearest
end

return ZoneController
