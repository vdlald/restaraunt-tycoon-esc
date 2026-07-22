--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)
local Utils = require(ReplicatedStorage.Shared.Utils)
local PlacementQuery = require(ReplicatedStorage.Shared.Placement.PlacementQuery)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local Net = require(ReplicatedStorage.Shared.Net)
local BuildModeValidator = require(ServerScriptService.Server.Game.BuildMode.BuildModeValidator)
local BuildModePhysics = require(ServerScriptService.Server.Game.BuildMode.BuildModePhysics)

local HIDDEN_OFFSET = CFrame.new(0, -500, 0)

local function getOrCreateHiddenFolder(): Folder
	local folder = workspace:FindFirstChild("BuildModeHidden")
	if folder then
		return folder :: Folder
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = "BuildModeHidden"
	newFolder.Parent = workspace
	return newFolder
end

local BuildModeSystem = Class.defineClass("BuildModeSystem", AbstractSystem)

function BuildModeSystem.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, BuildModeSystem)
	self._carriedFurnitureToPlayer = {} :: { [jecs.Entity<nil>]: jecs.Entity<nil> }
	return self
end

function BuildModeSystem:_getPlayerEntity(playerView: Types.PlayerView): jecs.Entity<nil>?
	local player = playerView:GetPlayer()
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId or not world:contains(playerId) then
		return nil
	end
	return playerId
end

function BuildModeSystem:_sendState(playerView: Types.PlayerView)
	local player = playerView:GetPlayer()
	local playerId = self:_getPlayerEntity(playerView)
	local active = playerId ~= nil and world:has(playerId, WorldWrapper:GetBuildModeActiveComponent())

	local carriedEntityId: number? = nil
	if active and playerId then
		local carriedData = world:get(playerId, WorldWrapper:GetBuildModeCarriedComponent())
		if carriedData then
			carriedEntityId = carriedData.FurnitureEntity
		end
	end

	Net.buildModeState.sendTo({
		active = active,
		carriedEntityId = carriedEntityId,
	}, player)
end

function BuildModeSystem:SetActive(playerView: Types.PlayerView, active: boolean)
	local playerId = self:_getPlayerEntity(playerView)
	if not playerId then
		return
	end

	local isActive = world:has(playerId, WorldWrapper:GetBuildModeActiveComponent())
	if active == isActive then
		return
	end

	if not active then
		self:CancelCarry(playerView)
		world:remove(playerId, WorldWrapper:GetBuildModeActiveComponent())
	else
		world:set(playerId, WorldWrapper:GetBuildModeActiveComponent())
	end

	self:_sendState(playerView)
end

function BuildModeSystem:_isFurnitureCarried(furnitureEntity: jecs.Entity<nil>): boolean
	return self._carriedFurnitureToPlayer[furnitureEntity] ~= nil
end

function BuildModeSystem:Pickup(playerView: Types.PlayerView, furnitureEntity: jecs.Entity<nil>)
	local playerId = self:_getPlayerEntity(playerView)
	if not playerId then
		return
	end

	if not world:has(playerId, WorldWrapper:GetBuildModeActiveComponent()) then
		return
	end

	if world:has(playerId, WorldWrapper:GetBuildModeCarriedComponent()) then
		return
	end

	if not world:contains(furnitureEntity) then
		return
	end

	local instance = WorldWrapper:FindInstance(furnitureEntity)
	if not instance then
		return
	end

	if not instance:IsA("Model") or not instance:HasTag(Consts.Tags.Furniture) then
		return
	end

	if self:_isFurnitureCarried(furnitureEntity) then
		return
	end

	local distance = playerView:GetDistance(instance)
	if distance > Consts.BuildModePickupDistance then
		return
	end

	local primaryPart = instance.PrimaryPart
	if not primaryPart then
		warn(`BuildModeSystem:Pickup: furniture {instance.Name} has no PrimaryPart`)
		return
	end

	local originalCFrame = instance:GetPrimaryPartCFrame()
	local physicsState = BuildModePhysics.Capture(instance)

	BuildModePhysics.Disable(instance)
	instance:AddTag(Consts.Tags.InteractableDisabled)
	instance.Parent = getOrCreateHiddenFolder()
	instance:SetPrimaryPartCFrame(HIDDEN_OFFSET)

	world:set(playerId, WorldWrapper:GetBuildModeCarriedComponent(), {
		FurnitureEntity = furnitureEntity,
		OriginalCFrame = originalCFrame,
		PhysicsState = physicsState,
	})
	self._carriedFurnitureToPlayer[furnitureEntity] = playerId

	self:_sendState(playerView)
end

function BuildModeSystem:Place(playerView: Types.PlayerView, aimPoint: Vector3, yaw: number)
	local playerId = self:_getPlayerEntity(playerView)
	if not playerId then
		return
	end

	if not world:has(playerId, WorldWrapper:GetBuildModeCarriedComponent()) then
		return
	end

	local carriedData = world:get(playerId, WorldWrapper:GetBuildModeCarriedComponent())
	local furnitureEntity = carriedData.FurnitureEntity
	local instance = WorldWrapper:FindInstance(furnitureEntity)
	if not instance or not instance:IsA("Model") then
		self:CancelCarry(playerView)
		return
	end

	local humanoid = playerView:GetHumanoid()
	local rootPart = humanoid.RootPart
	if not rootPart then
		return
	end

	if not BuildModeValidator.IsPlacementReachable(rootPart.Position, aimPoint) then
		return
	end

	local size = instance:GetExtentsSize()
	local correctedCFrame = PlacementQuery.ComputePlacementCFrame(aimPoint, yaw, size.Y)
	if not correctedCFrame then
		return
	end

	if not BuildModeValidator.IsAreaClear(correctedCFrame, size, { instance, playerView:GetCharacter() }) then
		return
	end

	BuildModePhysics.Apply(carriedData.PhysicsState)
	instance:RemoveTag(Consts.Tags.InteractableDisabled)
	instance.Parent = workspace
	instance:SetPrimaryPartCFrame(correctedCFrame)

	world:remove(playerId, WorldWrapper:GetBuildModeCarriedComponent())
	self._carriedFurnitureToPlayer[furnitureEntity] = nil
	self:_sendState(playerView)
end

function BuildModeSystem:CancelCarry(playerView: Types.PlayerView)
	local playerId = self:_getPlayerEntity(playerView)
	if not playerId then
		return
	end

	local carriedData = world:get(playerId, WorldWrapper:GetBuildModeCarriedComponent())
	if not carriedData then
		return
	end

	local instance = WorldWrapper:FindInstance(carriedData.FurnitureEntity)
	if instance and instance:IsA("Model") then
		BuildModePhysics.Apply(carriedData.PhysicsState)
		instance:RemoveTag(Consts.Tags.InteractableDisabled)
		instance.Parent = workspace
		instance:SetPrimaryPartCFrame(carriedData.OriginalCFrame)
	end

	self._carriedFurnitureToPlayer[carriedData.FurnitureEntity] = nil
	world:remove(playerId, WorldWrapper:GetBuildModeCarriedComponent())
	self:_sendState(playerView)
end

function BuildModeSystem:Process(_: number)
	for playerId, carriedData in world:query(WorldWrapper:GetBuildModeCarriedComponent()) do
		Utils:safeCall("BuildModeSystem:Process", function()
			local playerComponent = world:get(playerId, WorldWrapper:GetPlayerComponent())
			if not playerComponent then
				return
			end

			local player = playerComponent.Player
			local character = player.Character
			if not character then
				self:CancelCarry(playerComponent.PlayerView)
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
			if not humanoid or humanoid.Health <= 0 then
				self:CancelCarry(playerComponent.PlayerView)
				return
			end

			local instance = WorldWrapper:FindInstance(carriedData.FurnitureEntity)
			if not instance then
				self:CancelCarry(playerComponent.PlayerView)
			end
		end)
	end
end

return BuildModeSystem.new() :: AbstractSystem.AbstractSystem
