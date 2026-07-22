--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Consts = require(ReplicatedStorage.Shared.Consts)
local PlacementQuery = require(ReplicatedStorage.Shared.Placement.PlacementQuery)

local StarterPlayer = game:GetService("StarterPlayer")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)
local EntityRegistry = require(StarterPlayer.StarterPlayerScripts.Client.EntityRegistry)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local BuildModeController = {}

local ghostModel: Model? = nil
local ghostRotation: number = 0
local targetHighlight: Highlight? = nil
local currentTargetEntityId: number? = nil

local function getCharacter(): Model?
	return player.Character
end

local function raycastFromCamera(
	maxDistance: number,
	filterType: Enum.RaycastFilterType,
	filterInstances: { Instance }?
): RaycastResult?
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * maxDistance

	local params = RaycastParams.new()
	params.FilterType = filterType
	params.FilterDescendantsInstances = filterInstances or {}

	return workspace:Raycast(origin, direction, params)
end

local function computeAimPoint(): Vector3
	local character = getCharacter()
	local ignoreList = { character }
	if ghostModel then
		table.insert(ignoreList, ghostModel)
	end

	local result = raycastFromCamera(Consts.BuildModeMaxDistance, Enum.RaycastFilterType.Exclude, ignoreList)
	if result then
		return result.Position
	end

	return camera.CFrame.Position + camera.CFrame.LookVector * Consts.BuildModeMaxDistance
end

local function findFurnitureTarget(result: RaycastResult): (Instance?, number?)
	local part: Instance = result.Instance
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil, nil
	end

	if not model:HasTag(Consts.Tags.Furniture) then
		return nil, nil
	end

	local entityId: number? = model:GetAttribute(Consts.Attributes.EntityId)
	if not entityId then
		return nil, nil
	end

	return model, entityId
end

local function setGhostTransparency(transparency: number)
	if not ghostModel then
		return
	end

	for _, descendant: Instance in ipairs(ghostModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = transparency
		end
	end
end

local function updateGhostPosition()
	if not ghostModel then
		return
	end

	local aimPoint = computeAimPoint()
	local modelHeight = ghostModel:GetExtentsSize().Y
	local placementCFrame = PlacementQuery.ComputePlacementCFrame(aimPoint, ghostRotation, modelHeight)

	if not placementCFrame then
		setGhostTransparency(1)
		return
	end

	setGhostTransparency(0.6)
	ghostModel:SetPrimaryPartCFrame(placementCFrame)
end

local function destroyGhost()
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
	ghostRotation = 0
end

local function createGhost(entityId: number)
	destroyGhost()

	local instance = EntityRegistry.GetInstanceByEntityId(entityId)
	if not instance or not instance:IsA("Model") then
		return
	end

	local clone = instance:Clone()
	clone.Name = "BuildModeGhost"

	for _, descendant: Instance in ipairs(clone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.Transparency = 0.6
			descendant.CastShadow = false
		end
	end

	clone.Parent = camera
	ghostModel = clone
end

local function updateHighlight(model: Instance?)
	if targetHighlight then
		targetHighlight:Destroy()
		targetHighlight = nil
	end

	if not model then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(80, 150, 255)
	highlight.OutlineColor = Color3.fromRGB(100, 180, 255)
	highlight.FillTransparency = 0.75
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model
	targetHighlight = highlight
end

local function onCarriedEntityChanged(entityId: number?)
	if entityId then
		createGhost(entityId)
	else
		destroyGhost()
	end
end

local function updateTarget()
	if State.CarriedFurnitureEntity:get() then
		currentTargetEntityId = nil
		updateHighlight(nil)
		return
	end

	local character = getCharacter()
	local ignoreList = { character }
	if ghostModel then
		table.insert(ignoreList, ghostModel)
	end
	for _, zone: Instance in ipairs(CollectionService:GetTagged(Consts.Tags.BuildZone)) do
		table.insert(ignoreList, zone)
	end

	local result = raycastFromCamera(Consts.BuildModePickupDistance, Enum.RaycastFilterType.Exclude, ignoreList)
	if not result then
		currentTargetEntityId = nil
		updateHighlight(nil)
		return
	end

	local model, entityId = findFurnitureTarget(result)
	if model and entityId then
		currentTargetEntityId = entityId
		updateHighlight(model)
	else
		currentTargetEntityId = nil
		updateHighlight(nil)
	end
end

function BuildModeController.IsCarrying(): boolean
	return State.CarriedFurnitureEntity:get() ~= nil
end

function BuildModeController.IsActive(): boolean
	return State.BuildModeActive:get()
end

function BuildModeController.Init()
	State.CarriedFurnitureEntity:on(onCarriedEntityChanged)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.B then
			NetClient:BuildModeSetActive(not State.BuildModeActive:get())
			return
		end

		if not State.BuildModeActive:get() then
			return
		end

		if input.KeyCode == Enum.KeyCode.R then
			ghostRotation += Consts.BuildModeRotationStep
			return
		end

		if input.KeyCode ~= Enum.KeyCode.E then
			return
		end

		local carriedEntityId = State.CarriedFurnitureEntity:get()
		if carriedEntityId and ghostModel then
			local aimPoint = computeAimPoint()
			NetClient:BuildModePlace(aimPoint, ghostRotation)
			return
		end

		if currentTargetEntityId then
			NetClient:PlayerInteract(currentTargetEntityId, Enum.KeyCode.E)
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not State.BuildModeActive:get() then
			return
		end

		updateTarget()
		updateGhostPosition()
	end)
end

return BuildModeController
