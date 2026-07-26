--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)

export type PlaceHolderComponent = jecs.Id<nil>

--
-- Placed
export type Placed = jecs.Id<{ PlaceHolderEntity: jecs.Entity<nil> }>

--
-- Holds
export type Holds = jecs.Id<{ TargetEntity: jecs.Entity<nil>, Weld: WeldConstraint }>

--
-- Объявление обработчика
local System = Class.defineClass("PlaceHolderSystem", AbstractSystem)

function System.new(worldContext, placeHolderComponent, placedComponent, holdsComponent)
	local parent = AbstractSystem.new(worldContext)
	local self = setmetatable(parent, System)
	self.placeHolderComponent = placeHolderComponent
	self.placedComponent = placedComponent
	self.holdsComponent = holdsComponent
	return self
end

--
-- Процессинг
function System:Process(_: number)
	-- Обрабатываем запросы на подмену объектов
	self:query(self.placedComponent, self.worldWrapper:GetReplaceTargetComponent())
		:forEach(function(entityId, placedComponent, replaceComponent)
			if not entityId then
				return
			end

			self.world:remove(entityId, self.worldWrapper:GetReplaceTargetComponent())

			local placeHolderEntity = placedComponent.PlaceHolderEntity
			local _, newTarget = entityId, replaceComponent.NewTarget

			self.world:remove(placeHolderEntity, self.holdsComponent)
			self:Place(placeHolderEntity, newTarget)

			return entityId
		end)
end

function System:HandleInteraction(
	target: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
): boolean
	if self.world:has(target, self.placeHolderComponent) and not self.world:has(target, self.holdsComponent) then
		if keyCode == Enum.KeyCode.E then
			local equippedToolEntity = playerView:TakeFromHands()
			if equippedToolEntity then
				self:Place(target, equippedToolEntity)
			end
		end
		return true
	end

	local placedComponent = self.world:get(target, self.placedComponent)
	if not placedComponent then
		return false
	end
	if keyCode == Enum.KeyCode.E and not playerView:GetEquippedTool() then
		self.world:remove(placedComponent.PlaceHolderEntity, self.holdsComponent)
		local tool: Tool = self.world:get(target, self.worldWrapper:GetInstanceComponent()).Instance
		playerView:PutInHands(tool)
	end
	return true
end

function System:Place(placeHolderEntity: jecs.Entity<nil>, targetEntity: jecs.Entity<nil>)
	self.world:set(placeHolderEntity, self.holdsComponent, {
		TargetEntity = targetEntity,
		Weld = Instance.new("WeldConstraint"),
	})
end

local PlaceHolder = {}

function PlaceHolder.new(worldContext)
	local world = worldContext:GetWorld()
	local placeHolderComponent = world:component() :: PlaceHolderComponent
	local placedComponent = world:component() :: Placed
	local holdsComponent = world:component() :: Holds
	local system = System.new(worldContext, placeHolderComponent, placedComponent, holdsComponent)

	local function createPlaceHolder(instance: Instance): (jecs.Entity<nil>, Instance)
		instance:AddTag(Consts.Tags.Interactable)
		instance:AddTag(Consts.Tags.PlaceHolder)

		local entity = worldContext:RegisterInstance(instance, "PlaceHolder")
		world:set(entity, placeHolderComponent)
		world:set(entity, worldContext:GetPlayerInteractableComponent())

		return entity, instance
	end

	world:set(placedComponent, jecs.OnAdd, function(entity, _, _)
		world:get(entity, worldContext:GetInstanceComponent()).Instance:AddTag("Placed")
	end)
	world:set(placedComponent, jecs.OnRemove, function(entity, _, _)
		world:get(entity, worldContext:GetInstanceComponent()).Instance:RemoveTag("Placed")
	end)
	world:set(holdsComponent, jecs.OnAdd, function(placeHolderEntity, _, data)
		local targetEntity = data.TargetEntity
		world:get(placeHolderEntity, worldContext:GetInstanceComponent()).Instance:AddTag("Holds")
		world:set(targetEntity, placedComponent, { PlaceHolderEntity = placeHolderEntity })

		local targetInstance: Tool = world:get(targetEntity, worldContext:GetInstanceComponent()).Instance
		local topPart: Part = world:get(placeHolderEntity, worldContext:GetInstanceComponent()).Instance
		targetInstance.Parent = workspace
		local plateTop = topPart.CFrame * CFrame.new(0, topPart.Size.Y / 2, 0)
		local targetCFrame = plateTop * CFrame.new(0, targetInstance.PrimaryPart.Size.Y / 2, 0)
		targetInstance:SetPrimaryPartCFrame(targetCFrame)

		local weld = data.Weld
		weld.Part0 = targetInstance.PrimaryPart
		weld.Part1 = topPart
		weld.Parent = topPart
	end)
	world:set(holdsComponent, jecs.OnRemove, function(placeHolderEntity, _, deleting)
		local holdsData = world:get(placeHolderEntity, holdsComponent)
		local targetEntity: jecs.Entity<nil>, weld: WeldConstraint = holdsData.TargetEntity, holdsData.Weld

		world:get(placeHolderEntity, worldContext:GetInstanceComponent()).Instance:RemoveTag("Holds")
		if not deleting then
			world:remove(targetEntity, placedComponent)
		end
		weld:Destroy()
	end)

	return {
		Create = createPlaceHolder,
		Component = placeHolderComponent,
		System = system,
	}
end

return PlaceHolder
