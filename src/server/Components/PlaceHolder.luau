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
export type Placed = jecs.Id<{ PlaceHolderEntity: jecs.Id<nil> }>
local _placedComponent = world:component() :: Placed

world:set(_placedComponent, jecs.OnAdd, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:AddTag("Placed")
end)

world:set(_placedComponent, jecs.OnRemove, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:RemoveTag("Placed")
end)

--
-- Holds
export type Holds = jecs.Id<{ TargetEntity: jecs.Id<nil>, Weld: WeldConstraint }>
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
world:set(_holdsComponent, jecs.OnRemove, function(placeHolderEntity, _, _)
	local holdsData = world:get(placeHolderEntity, _holdsComponent)
	local targetEntity: jecs.Entity<nil>, weld: WeldConstraint = holdsData.TargetEntity, holdsData.Weld

	world:get(placeHolderEntity, WorldWrapper:GetInstanceComponent()).Instance:RemoveTag("Holds")
	world:remove(targetEntity, _placedComponent)

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

local function isOwnerCarried(placeHolderEntity: jecs.Entity<nil>?): boolean
	if not placeHolderEntity then
		return false
	end

	local instance = WorldWrapper:FindInstance(placeHolderEntity)
	if not instance then
		return false
	end

	local ownerModel = instance:FindFirstAncestorOfClass("Model")
	if not ownerModel then
		return false
	end

	return ownerModel:HasTag(Consts.Tags.InteractableDisabled)
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
	-- Обрабатываем запрос пользователя на размещение объекта
	self:query(WorldWrapper:GetPlayerInteractComponent())
		:with(placeHolderComponent)
		:without(_holdsComponent)
		:forEach(function(placeHolderEntity: jecs.Entity<nil>?, intent): jecs.Entity<nil>?
			if not placeHolderEntity then
				return
			end

			-- Считаем задачу выполненной
			world:remove(placeHolderEntity, WorldWrapper:GetPlayerInteractComponent())

			if isOwnerCarried(placeHolderEntity) then
				return placeHolderEntity
			end

			-- Начало обработки
			local keyCode: Enum.KeyCode = intent.KeyCode
			local playerView: Types.PlayerView = intent.PlayerView

			if keyCode ~= Enum.KeyCode.E then
				return placeHolderEntity
			end

			local equippedToolEntity = playerView:TakeFromHands()
			if not equippedToolEntity then
				-- Если ничего нет в руках у пользователя, то выходим
				return placeHolderEntity
			end

			System:Place(placeHolderEntity, equippedToolEntity)

			return placeHolderEntity
		end)

	-- Обрабатываем запрос пользователя на поднятие объекта
	self:query(_placedComponent, WorldWrapper:GetPlayerInteractComponent())
		:forEach(function(placedEntity, placedComponent, intent)
			if not placedEntity then
				return
			end

			-- Считаем задачу выполненной
			world:remove(placedEntity, WorldWrapper:GetPlayerInteractComponent())

			if isOwnerCarried(placedComponent.PlaceHolderEntity) then
				return placedEntity
			end

			-- Начало обработки
			local placeHolderEntity = placedComponent.PlaceHolderEntity
			local keyCode: Enum.KeyCode = intent.KeyCode
			local playerView: Types.PlayerView = intent.PlayerView

			if keyCode ~= Enum.KeyCode.E then
				return placedEntity
			end

			local equippedTool = playerView:GetEquippedTool()
			if equippedTool then
				-- Если в руках что-то есть, то ничего не берем
				return placedEntity
			end

			-- Убираем связь
			world:remove(placeHolderEntity, _holdsComponent)

			-- Выдаем в руки
			local tool: Tool = world:get(placedEntity, WorldWrapper:GetInstanceComponent()).Instance
			playerView:PutInHands(tool)

			return placedEntity
		end)

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
