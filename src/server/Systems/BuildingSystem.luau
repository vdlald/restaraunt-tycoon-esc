--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Utils = require(ReplicatedStorage.Shared.Utils)
local Consts = require(ReplicatedStorage.Shared.Consts)
local PlacementValidation = require(ReplicatedStorage.Shared.Building.PlacementValidation)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local BuildingValidation = require(ServerScriptService.Server.Game.Building.BuildingValidation)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local Net = require(ReplicatedStorage.Shared.Net)

--
-- Объявление системы
local BuildingSystem = Class.defineClass("BuildingSystem", AbstractSystem)

function BuildingSystem.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, BuildingSystem)

	self.cachedQueryToggle = world:query(WorldWrapper:GetWantsToToggleBuildingModeComponent()):cached()
	self.cachedQueryInteract =
		world:query(WorldWrapper:GetPlayerInteractComponent()):with(WorldWrapper:GetBuildingMovableComponent()):cached()
	self.cachedQueryMove = world:query(WorldWrapper:GetBuildingMoveStateComponent()):cached()

	self.pendingRotations = {}
	self.lastGhostMoveTime = {}
	self.lastGhostRotateTime = {}

	return self
end

local function getHiddenFolder(): Folder
	local folder = ServerStorage:FindFirstChild("BuildingHidden")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "BuildingHidden"
		folder.Parent = ServerStorage
	end
	return folder :: Folder
end

local function removeAllTags(instance: Instance)
	local targets = { instance }
	for _, desc in instance:GetDescendants() do
		table.insert(targets, desc)
	end

	for _, target in targets do
		for _, tag in target:GetTags() do
			target:RemoveTag(tag)
		end
		target:SetAttribute(Consts.Attributes.EntityId, nil)
	end
end

local function stripScriptsAndConstraints(instance: Instance)
	for _, desc in instance:GetDescendants() do
		if
			desc:IsA("LuaSourceContainer")
			or desc:IsA("JointInstance")
			or desc:IsA("WeldConstraint")
			or desc:IsA("NoCollisionConstraint")
		then
			desc:Destroy()
		end
	end
end

local function createGhost(original: Model, player: Player): Model?
	if not original.PrimaryPart then
		return nil
	end

	local ghost = original:Clone()
	removeAllTags(ghost)
	ghost:AddTag(Consts.Tags.BuildingGhost)
	ghost:SetAttribute("MoverUserId", player.UserId)
	stripScriptsAndConstraints(ghost)

	for _, desc in ghost:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.Anchored = true
			desc.Transparency = Consts.BuildingGhostTransparency
		end
	end

	ghost.Parent = workspace
	return ghost
end

local function getPlayerEntityFromView(playerView: Types.PlayerView): jecs.Entity<nil>?
	local player = playerView:GetPlayer()
	local playerEntity = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerEntity then
		return nil
	end
	return playerEntity
end

local function getPlayerCharacterPosition(playerView: Types.PlayerView): Vector3?
	local character = playerView:GetCharacter()
	if not character then
		return nil
	end
	return character:GetPivot().Position
end

local function sendBuildingModeState(player: Player, enabled: boolean, movingEntity: number)
	Net.buildingModeState.sendTo({
		enabled = enabled,
		movingEntity = movingEntity,
	}, player)
end

local function computeFloorOffset(instance: Model): number
	local primaryPart = instance.PrimaryPart
	if not primaryPart then
		return 0
	end

	local originalPosition = primaryPart.Position
	local floorPart = PlacementValidation.FindFloorPart(originalPosition, BuildingValidation.GetBuildZoneParts())
	if not floorPart then
		return 0
	end

	local floorY = floorPart.Position.Y + floorPart.Size.Y / 2
	return originalPosition.Y - floorY
end

function BuildingSystem:CancelMove(playerEntity: jecs.Entity<nil>)
	local moveState = world:get(playerEntity, WorldWrapper:GetBuildingMoveStateComponent())
	if not moveState then
		return
	end

	local furnitureEntity = moveState.FurnitureEntity
	local instance = WorldWrapper:FindInstance(furnitureEntity)
	if instance and instance:IsA("Model") then
		instance.Parent = moveState.OriginalParent
		instance:SetPrimaryPartCFrame(moveState.OriginalCFrame)
	end

	if moveState.GhostInstance then
		moveState.GhostInstance:Destroy()
	end

	self.pendingRotations[playerEntity] = nil
	self.lastGhostMoveTime[playerEntity] = nil
	self.lastGhostRotateTime[playerEntity] = nil

	world:remove(furnitureEntity, WorldWrapper:GetBuildingLockComponent())
	world:remove(playerEntity, WorldWrapper:GetBuildingMoveStateComponent())
end

function BuildingSystem:RequestRotation(playerEntity: jecs.Entity<nil>, deltaYaw: number)
	if not world:has(playerEntity, WorldWrapper:GetBuildingMoveStateComponent()) then
		return
	end

	local now = tick()
	local last = self.lastGhostRotateTime[playerEntity] or 0
	if now - last < Consts.BuildingGhostServerRateLimit then
		return
	end
	self.lastGhostRotateTime[playerEntity] = now

	self.pendingRotations[playerEntity] = (self.pendingRotations[playerEntity] or 0) + deltaYaw
end

function BuildingSystem:SetGhostTarget(playerEntity: jecs.Entity<nil>, position: Vector3)
	if not world:has(playerEntity, WorldWrapper:GetBuildingMoveStateComponent()) then
		return
	end

	local now = tick()
	local last = self.lastGhostMoveTime[playerEntity] or 0
	if now - last < Consts.BuildingGhostServerRateLimit then
		return
	end
	self.lastGhostMoveTime[playerEntity] = now

	world:set(playerEntity, WorldWrapper:GetBuildingGhostTargetComponent(), { Position = position })
end

function BuildingSystem:processToggles()
	for playerEntity, request in self.cachedQueryToggle do
		local enabled = request.Enabled
		local playerView = WorldWrapper:FindPlayer(playerEntity)
		if not playerView then
			world:remove(playerEntity, WorldWrapper:GetWantsToToggleBuildingModeComponent())
			continue
		end

		local player = playerView:GetPlayer()
		local currentlyEnabled = world:has(playerEntity, WorldWrapper:GetBuildingModeComponent())

		if enabled and not currentlyEnabled then
			world:set(playerEntity, WorldWrapper:GetBuildingModeComponent())
		elseif not enabled and currentlyEnabled then
			world:remove(playerEntity, WorldWrapper:GetBuildingModeComponent())
			self:CancelMove(playerEntity)
		end

		local moveState = world:get(playerEntity, WorldWrapper:GetBuildingMoveStateComponent())
		local movingEntity = moveState and moveState.FurnitureEntity or 0
		sendBuildingModeState(player, world:has(playerEntity, WorldWrapper:GetBuildingModeComponent()), movingEntity)

		world:remove(playerEntity, WorldWrapper:GetWantsToToggleBuildingModeComponent())
	end
end

function BuildingSystem:processRotations()
	for playerEntity, deltaYaw in self.pendingRotations do
		local moveState = world:get(playerEntity, WorldWrapper:GetBuildingMoveStateComponent())
		if moveState then
			local newYawOffset = moveState.YawOffset + deltaYaw
			local newState = table.clone(moveState)
			newState.YawOffset = newYawOffset
			world:set(playerEntity, WorldWrapper:GetBuildingMoveStateComponent(), newState)

			local ghost = moveState.GhostInstance
			if ghost then
				local currentCFrame = ghost:GetPrimaryPartCFrame()
				local originalRotation = moveState.OriginalCFrame.Rotation
				local newCFrame = CFrame.new(currentCFrame.Position)
					* originalRotation
					* CFrame.Angles(0, newYawOffset, 0)
				ghost:SetPrimaryPartCFrame(newCFrame)
			end
		end
	end

	table.clear(self.pendingRotations)
end

function BuildingSystem:processGhostMovement()
	for playerEntity, moveState in self.cachedQueryMove do
		local ghostTarget = world:get(playerEntity, WorldWrapper:GetBuildingGhostTargetComponent())
		if not ghostTarget then
			continue
		end

		world:remove(playerEntity, WorldWrapper:GetBuildingGhostTargetComponent())

		local ghost = moveState.GhostInstance
		if not ghost then
			continue
		end

		local playerView = WorldWrapper:FindPlayer(playerEntity)
		if not playerView then
			continue
		end
		local playerPosition = getPlayerCharacterPosition(playerView)

		local targetPosition = ghostTarget.Position
		local originalRotation = moveState.OriginalCFrame.Rotation
		local candidateCFrame = CFrame.new(targetPosition) * originalRotation * CFrame.Angles(0, moveState.YawOffset, 0)
		local validation = BuildingValidation.ValidateModelPlacement(ghost, candidateCFrame)

		if validation.IsValid and validation.FloorY then
			local finalPosition =
				Vector3.new(targetPosition.X, validation.FloorY + moveState.FloorOffset, targetPosition.Z)

			if playerPosition and (finalPosition - playerPosition).Magnitude > Consts.BuildingMaxCarryDistance then
				continue
			end

			local finalCFrame = CFrame.new(finalPosition) * originalRotation * CFrame.Angles(0, moveState.YawOffset, 0)
			ghost:SetPrimaryPartCFrame(finalCFrame)
		end
	end
end

function BuildingSystem:attemptPickup(
	playerEntity: jecs.Entity<nil>,
	furnitureEntity: jecs.Entity<nil>,
	playerView: Types.PlayerView
)
	local lock = world:get(furnitureEntity, WorldWrapper:GetBuildingLockComponent())
	if lock and lock.OwnerPlayerEntity ~= playerEntity then
		return
	end

	local instance = WorldWrapper:FindInstance(furnitureEntity)
	if not instance or not instance:IsA("Model") then
		return
	end

	if not instance.PrimaryPart then
		return
	end

	local originalCFrame = instance:GetPrimaryPartCFrame()
	local originalParent = instance.Parent
	local floorOffset = computeFloorOffset(instance)

	local ghost = createGhost(instance, playerView:GetPlayer())
	if not ghost then
		return
	end
	instance.Parent = getHiddenFolder()

	world:set(playerEntity, WorldWrapper:GetBuildingMoveStateComponent(), {
		FurnitureEntity = furnitureEntity,
		GhostInstance = ghost,
		OriginalCFrame = originalCFrame,
		OriginalParent = originalParent,
		FloorOffset = floorOffset,
		YawOffset = 0,
	})

	world:set(furnitureEntity, WorldWrapper:GetBuildingLockComponent(), {
		OwnerPlayerEntity = playerEntity,
	})

	sendBuildingModeState(playerView:GetPlayer(), true, furnitureEntity)
end

function BuildingSystem:attemptPlace(
	playerEntity: jecs.Entity<nil>,
	furnitureEntity: jecs.Entity<nil>,
	moveState: {
		FurnitureEntity: jecs.Entity<nil>,
		GhostInstance: Model,
		OriginalCFrame: CFrame,
		OriginalParent: Instance,
		FloorOffset: number,
		YawOffset: number,
	},
	playerView: Types.PlayerView
)
	local ghost = moveState.GhostInstance
	if not ghost.PrimaryPart then
		Net.buildingPlacementResult.sendTo({ success = false }, playerView:GetPlayer())
		return
	end

	local ghostCFrame = ghost:GetPrimaryPartCFrame()

	local playerPosition = getPlayerCharacterPosition(playerView)
	if playerPosition and (ghostCFrame.Position - playerPosition).Magnitude > Consts.BuildingMaxCarryDistance then
		Net.buildingPlacementResult.sendTo({ success = false }, playerView:GetPlayer())
		return
	end

	local validation = BuildingValidation.ValidateModelPlacement(ghost, ghostCFrame)
	if not validation.IsValid then
		Net.buildingPlacementResult.sendTo({ success = false }, playerView:GetPlayer())
		return
	end

	local instance = WorldWrapper:FindInstance(furnitureEntity)
	if not instance or not instance:IsA("Model") then
		Net.buildingPlacementResult.sendTo({ success = false }, playerView:GetPlayer())
		return
	end

	instance.Parent = moveState.OriginalParent
	instance:SetPrimaryPartCFrame(ghostCFrame)

	ghost:Destroy()

	world:remove(furnitureEntity, WorldWrapper:GetBuildingLockComponent())
	world:remove(playerEntity, WorldWrapper:GetBuildingMoveStateComponent())

	Net.buildingPlacementResult.sendTo({ success = true }, playerView:GetPlayer())
	sendBuildingModeState(playerView:GetPlayer(), true, 0)
end

function BuildingSystem:processInteractions()
	for furnitureEntity, intent in self.cachedQueryInteract do
		if intent.KeyCode ~= Enum.KeyCode.E then
			continue
		end

		local playerEntity = getPlayerEntityFromView(intent.PlayerView)
		if not playerEntity then
			continue
		end

		if not world:has(playerEntity, WorldWrapper:GetBuildingModeComponent()) then
			continue
		end

		world:remove(furnitureEntity, WorldWrapper:GetPlayerInteractComponent())

		local moveState = world:get(playerEntity, WorldWrapper:GetBuildingMoveStateComponent())
		if moveState then
			if moveState.FurnitureEntity == furnitureEntity then
				Utils:safeCall("BuildingSystem.attemptPlace", function()
					self:attemptPlace(playerEntity, furnitureEntity, moveState, intent.PlayerView)
				end)
			end
		else
			Utils:safeCall("BuildingSystem.attemptPickup", function()
				self:attemptPickup(playerEntity, furnitureEntity, intent.PlayerView)
			end)
		end
	end
end

function BuildingSystem:Process(_: number)
	Utils:safeCall("BuildingSystem.processToggles", function()
		self:processToggles()
	end)

	Utils:safeCall("BuildingSystem.processRotations", function()
		self:processRotations()
	end)

	Utils:safeCall("BuildingSystem.processGhostMovement", function()
		self:processGhostMovement()
	end)

	Utils:safeCall("BuildingSystem.processInteractions", function()
		self:processInteractions()
	end)
end

return BuildingSystem.new()
