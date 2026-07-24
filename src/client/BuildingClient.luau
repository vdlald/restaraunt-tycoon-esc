--!strict

-- Зависимости
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local StarterPlayer = game:GetService("StarterPlayer")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)
local PlacementValidation = require(ReplicatedStorage.Shared.Building.PlacementValidation)

--
-- Состояние
local movingEntity = 0
local localGhost: Model? = nil
local ghostHighlight: Highlight? = nil

local lastSentPosition: Vector3? = nil
local lastSentTime = 0

--
-- Helpers
local function getBuildZoneParts(): { BasePart }
	local parts = {}
	for _, instance in CollectionService:GetTagged(Consts.Tags.BuildZone) do
		if instance:IsA("BasePart") then
			table.insert(parts, instance :: BasePart)
		end
	end
	return parts
end

local function getLocalGhost(): Model?
	if localGhost and localGhost.Parent then
		return localGhost
	end

	for _, instance in CollectionService:GetTagged(Consts.Tags.BuildingGhost) do
		if instance:GetAttribute("MoverUserId") == player.UserId then
			localGhost = instance :: Model
			return localGhost
		end
	end

	return nil
end

local function setGhostValid(valid: boolean)
	if not ghostHighlight then
		return
	end

	ghostHighlight.FillColor = valid and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end

local function attachHighlight(ghost: Model)
	if ghostHighlight then
		ghostHighlight:Destroy()
	end

	ghostHighlight = Instance.new("Highlight")
	ghostHighlight.FillTransparency = 0.3
	ghostHighlight.OutlineTransparency = 0
	ghostHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	ghostHighlight.FillColor = Color3.fromRGB(0, 255, 0)
	ghostHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	ghostHighlight.Adornee = ghost
	ghostHighlight.Parent = ghost
end

local function onMovingEntityChanged(entityId: number)
	movingEntity = entityId
	lastSentPosition = nil
	lastSentTime = 0

	if entityId == 0 then
		if ghostHighlight then
			ghostHighlight:Destroy()
			ghostHighlight = nil
		end
		localGhost = nil
		return
	end

	task.defer(function()
		local ghost = getLocalGhost()
		if ghost then
			attachHighlight(ghost)
		else
			warn("[BuildingClient] ghost not found for mover " .. tostring(player.UserId))
		end
	end)
end

State.MovingFurnitureEntity:on(onMovingEntityChanged)

--
-- Raycast мыши по миру, исключая персонажа и призраки
local function raycastMouse(): RaycastResult?
	local camera = Workspace.CurrentCamera
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local filter = {}
	if player.Character then
		table.insert(filter, player.Character)
	end
	for _, ghost in CollectionService:GetTagged(Consts.Tags.BuildingGhost) do
		table.insert(filter, ghost)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = filter

	return Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
end

--
-- Перемещение призрака
local function updateGhostTarget()
	if movingEntity == 0 then
		return
	end

	local ghost = getLocalGhost()
	if not ghost or not ghost.PrimaryPart then
		return
	end

	if not ghostHighlight or ghostHighlight.Parent ~= ghost then
		attachHighlight(ghost)
	end

	local result = raycastMouse()
	if not result then
		return
	end

	local targetPosition = result.Position

	local character = player.Character
	if not character then
		return
	end
	local playerPosition = character:GetPivot().Position
	if (targetPosition - playerPosition).Magnitude > Consts.BuildingMaxCarryDistance then
		setGhostValid(false)
		return
	end

	local buildZoneParts = getBuildZoneParts()
	if #buildZoneParts == 0 then
		return
	end

	local primaryPart = ghost.PrimaryPart
	local footprintSize = Vector2.new(primaryPart.Size.X, primaryPart.Size.Z)

	local candidateCFrame = CFrame.new(targetPosition) * ghost:GetPrimaryPartCFrame().Rotation

	local validation = PlacementValidation.Validate(candidateCFrame, footprintSize, buildZoneParts, Consts.BuildingMaxHoverHeight)
	setGhostValid(validation.IsValid)

	local now = tick()
	local shouldSend = not lastSentPosition
		or (targetPosition - lastSentPosition).Magnitude >= Consts.BuildingGhostSendThreshold
		or (now - lastSentTime) >= Consts.BuildingGhostSendInterval

	if shouldSend then
		NetClient:BuildingGhostMove(targetPosition)
		lastSentPosition = targetPosition
		lastSentTime = now
	end
end

RunService.RenderStepped:Connect(updateGhostTarget)

--
-- Ввод
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local keyCode = input.KeyCode

	if keyCode == Enum.KeyCode.B then
		if State.GamePhase:get() ~= 1 then
			return
		end
		NetClient:ToggleBuildingMode(not State.IsInBuildingMode:get())
		return
	end

	if not State.IsInBuildingMode:get() then
		return
	end

	if keyCode == Enum.KeyCode.E and movingEntity ~= 0 then
		NetClient:PlayerInteract(movingEntity, Enum.KeyCode.E)
		return
	end

	if keyCode == Enum.KeyCode.R and movingEntity ~= 0 then
		NetClient:BuildingGhostRotate(math.rad(90))
		return
	end

	if keyCode == Enum.KeyCode.Escape and movingEntity ~= 0 then
		NetClient:CancelBuildingMove()
		return
	end
end)

return {}
