--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)
local Utils = require(ReplicatedStorage.Shared.Utils)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local Net = require(ReplicatedStorage.Shared.Net)
local BuildModeValidator = require(ServerScriptService.Server.Game.BuildMode.BuildModeValidator)

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

local function capturePhysicsState(instance: Instance): { [BasePart]: { Anchored: boolean, CanCollide: boolean } }
	local state = {}
	for _, descendant: Instance in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			state[descendant] = {
				Anchored = descendant.Anchored,
				CanCollide = descendant.CanCollide,
			}
		end
	end
	return state
end

local function applyPhysicsState(physicsState: { [BasePart]: { Anchored: boolean, CanCollide: boolean } })
	for part: BasePart, saved in pairs(physicsState) do
		if part.Parent then
			part.Anchored = saved.Anchored
			part.CanCollide = saved.CanCollide
		end
	end
end

local function disablePhysics(instance: Instance)
	for _, descendant: Instance in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
end

local BuildModeSystem = Class.defineClass("BuildModeSystem", AbstractSystem)

function BuildModeSystem.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, BuildModeSystem)
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
	for _, carriedData in world:query(WorldWrapper:GetBuildModeCarriedComponent()) do
		if carriedData.FurnitureEntity == furnitureEntity then
			return true
		end
	end
	return false
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
	local physicsState = capturePhysicsState(instance)

	disablePhysics(instance)
	instance.Parent = getOrCreateHiddenFolder()
	instance:SetPrimaryPartCFrame(HIDDEN_OFFSET)

	world:set(playerId, WorldWrapper:GetBuildModeCarriedComponent(), {
		FurnitureEntity = furnitureEntity,
		OriginalCFrame = originalCFrame,
		PhysicsState = physicsState,
	})

	self:_sendState(playerView)
end

function BuildModeSystem:Place(playerView: Types.PlayerView, targetCFrame: CFrame)
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

	if not BuildModeValidator.IsPlacementReachable(rootPart.Position, targetCFrame.Position) then
		return
	end

	if not BuildModeValidator.IsInBuildZone(targetCFrame.Position) then
		return
	end

	local floorResult = BuildModeValidator.FindFloorUnder(targetCFrame.Position)
	if not floorResult then
		return
	end

	local size = instance:GetExtentsSize()
	local _, yaw, _ = targetCFrame:ToEulerAnglesXYZ()
	local snappedPosition = BuildModeValidator.SnapPosition(
		Vector3.new(targetCFrame.Position.X, floorResult.Position.Y + size.Y, targetCFrame.Position.Z)
	)
	local correctedCFrame = CFrame.new(snappedPosition) * CFrame.Angles(0, yaw, 0)

	if not BuildModeValidator.IsAreaClear(correctedCFrame, size, { instance, playerView:GetCharacter() }) then
		return
	end

	applyPhysicsState(carriedData.PhysicsState)
	instance.Parent = workspace
	instance:SetPrimaryPartCFrame(correctedCFrame)

	world:remove(playerId, WorldWrapper:GetBuildModeCarriedComponent())
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
		applyPhysicsState(carriedData.PhysicsState)
		instance.Parent = workspace
		instance:SetPrimaryPartCFrame(carriedData.OriginalCFrame)
	end

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
