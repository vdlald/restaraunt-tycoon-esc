--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- Компонент
export type PlaceHolderComponent = jecs.Id<nil>
local placeHolderComponent = world:component() :: PlaceHolderComponent

--
-- Placed
export type Placed = jecs.Id<{ PlaceHolderEntity: jecs.Entity<nil> }>
local _placedComponent = world:component() :: Placed

world:set(_placedComponent, jecs.OnAdd, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:AddTag("Placed")
end)

world:set(_placedComponent, jecs.OnRemove, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:RemoveTag("Placed")
end)

--
-- Holds
export type Holds = jecs.Id<{ TargetEntity: jecs.Entity<nil>, Weld: WeldConstraint }>
local _holdsComponent = world:component() :: Holds

-- Обработка установки связи
world:set(_holdsComponent, jecs.OnAdd, function(placeHolderEntity, _, data)
	local targetEntity = data.TargetEntity
	world:get(placeHolderEntity, WorldWrapper:GetInstanceComponent()).Instance:AddTag("Holds")
	world:set(targetEntity, _placedComponent, { PlaceHolderEntity = placeHolderEntity })

	-- Берем инстансы
	local targetInstance: Tool = world:get(targetEntity, WorldWrapper:GetInstanceComponent()).Instance
	local topPart: Part = world:get(placeHolderEntity, WorldWrapper:GetInstanceComponent()).Instance

	-- Устанавливаем поверх
	targetInstance.Parent = workspace

	local plateTop = topPart.CFrame * CFrame.new(0, topPart.Size.Y / 2, 0)
	local targetCFrame = plateTop * CFrame.new(0, targetInstance.PrimaryPart.Size.Y / 2, 0)
	targetInstance:SetPrimaryPartCFrame(targetCFrame)

	-- Привариваем
	local weld = data.Weld
	weld.Part0 = targetInstance.PrimaryPart
	weld.Part1 = topPart
	weld.Parent = topPart
end)

-- Обработка снятия связи
world:set(_holdsComponent, jecs.OnRemove, function(placeHolderEntity, _, deleting)
	local holdsData = world:get(placeHolderEntity, _holdsComponent)
	local targetEntity: jecs.Entity<nil>, weld: WeldConstraint = holdsData.TargetEntity, holdsData.Weld

	world:get(placeHolderEntity, WorldWrapper:GetInstanceComponent()).Instance:RemoveTag("Holds")
	if not deleting then
		world:remove(targetEntity, _placedComponent)
	end

	weld:Destroy()
end)

--
-- Объявление сущности
function CreatePlaceHolder(instance: Instance): (jecs.Entity<nil>, Instance)
	instance:AddTag(Consts.Tags.Interactable)
	instance:AddTag(Consts.Tags.PlaceHolder)

	local entity = WorldWrapper:RegisterInstance(instance, "PlaceHolder")
	world:set(entity, placeHolderComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end

--
-- Объявление обработчика
local System = Class.defineClass("PlaceHolderSystem", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	return self
end

--
-- Процессинг
function System:Process(_: number)
	-- Обрабатываем запросы на подмену объектов
	self:query(_placedComponent, WorldWrapper:GetReplaceTargetComponent())
		:forEach(function(entityId, placedComponent, replaceComponent)
			if not entityId then
				return
			end

			world:remove(entityId, WorldWrapper:GetReplaceTargetComponent())

			local placeHolderEntity = placedComponent.PlaceHolderEntity
			local _, newTarget = entityId, replaceComponent.NewTarget

			world:remove(placeHolderEntity, _holdsComponent)
			System:Place(placeHolderEntity, newTarget)

			return entityId
		end)
end

function System:HandleInteraction(
	target: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
): boolean
	if world:has(target, placeHolderComponent) and not world:has(target, _holdsComponent) then
		if keyCode == Enum.KeyCode.E then
			local equippedToolEntity = playerView:TakeFromHands()
			if equippedToolEntity then
				System:Place(target, equippedToolEntity)
			end
		end
		return true
	end

	local placedComponent = world:get(target, _placedComponent)
	if not placedComponent then
		return false
	end
	if keyCode == Enum.KeyCode.E and not playerView:GetEquippedTool() then
		world:remove(placedComponent.PlaceHolderEntity, _holdsComponent)
		local tool: Tool = world:get(target, WorldWrapper:GetInstanceComponent()).Instance
		playerView:PutInHands(tool)
	end
	return true
end

function System:Place(placeHolderEntity: jecs.Entity<nil>, targetEntity: jecs.Entity<nil>)
	world:set(placeHolderEntity, _holdsComponent, {
		TargetEntity = targetEntity,
		Weld = Instance.new("WeldConstraint"),
	})
end

--
-- Модуль
return {
	Create = CreatePlaceHolder,
	Component = placeHolderComponent,
	System = System.new() :: AbstractSystem.AbstractSystem,
}
