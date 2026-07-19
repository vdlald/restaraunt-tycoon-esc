--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Utils = require(ReplicatedStorage.Shared.Utils)
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

export type Holds = jecs.Id<{ TargetEntity: jecs.Id<nil>, Weld: WeldConstraint }>
local _holdsComponent = world:component() :: Holds

world:set(_holdsComponent, jecs.OnAdd, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:AddTag("Holds")
end)

world:set(_holdsComponent, jecs.OnRemove, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:RemoveTag("Holds")
end)

export type Placed = jecs.Id<{ PlaceHolderEntity: jecs.Id<nil> }>
local _placedComponent = world:component() :: Placed

world:set(_placedComponent, jecs.OnAdd, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:AddTag("Placed")
end)

world:set(_placedComponent, jecs.OnRemove, function(entity, _, _)
	world:get(entity, WorldWrapper:GetInstanceComponent()).Instance:RemoveTag("Placed")
end)

export type PlaceCommand = jecs.Id<{ TargetEntity: jecs.Id<nil> }>
local _placeCommand = world:component() :: PlaceCommand

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

-- Запросы
-- Ищем взаимодействие с пустым placeholder
local findEmptyPlaceHoldersQuery = function()
	return world
		:query(WorldWrapper:GetPlayerInteractComponent())
		:with(placeHolderComponent)
		:without(_holdsComponent)
end

-- Ищем компоненты, которые на placeholder и их требуется заменить на новые
local findToReplaceHoldersQuery = function()
	return world:query(_placedComponent, WorldWrapper:GetReplaceTargetComponent())
end

-- Ищем компоненты, которые лежат на placeholder и их хотят поднять
local findDirectItemInteract = function()
	return world:query(_placedComponent, WorldWrapper:GetPlayerInteractComponent())
end

local findPlaceCommand = function()
	return world:query(_placeCommand):with(placeHolderComponent):without(_holdsComponent)
end

--
-- Процессинг
function System:Process(_: number)
	for entityId, intent in findEmptyPlaceHoldersQuery() do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		Utils:safeCall("System:processPlace", function()
			System:processPlace(entityId, playerView, keyCode)
		end)
	end

	for entityId, placedComponent, replaceComponent in findToReplaceHoldersQuery() do
		world:remove(entityId, WorldWrapper:GetReplaceTargetComponent())

		local placeHolder = placedComponent.PlaceHolder
		local oldTarget, newTarget = entityId, replaceComponent.NewTarget

		Utils:safeCall("System:processReplace", function()
			System:processReplace(placeHolder, oldTarget, newTarget)
		end)
	end

	for entityId, placedComponent, intent in findDirectItemInteract() do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local placeHolder = placedComponent.PlaceHolder
		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		Utils:safeCall("System:processTake", function()
			System:processTake(entityId, placeHolder, playerView, keyCode)
		end)
	end

	for entityId, placeCommand in findPlaceCommand() do
		world:remove(entityId, _placeCommand)

		local placeHolder = entityId
		local targetEntity = placeCommand.TargetEntity

		Utils:safeCall("System:processPlaceCommand", function()
			System:processPlaceCommand(placeHolder, targetEntity)
		end)
	end
end

-- Установка на место
function System:processPlace(placeHolderEntity: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedToolEntity = playerView:TakeFromHands()
	if not equippedToolEntity then
		-- Если ничего нет в руках у пользователя, то выходим
		return
	end

	System:processPlaceCommand(placeHolderEntity, equippedToolEntity)
end

-- Замена предмета
function System:processReplace(placeHolder: jecs.Entity<nil>, oldTarget: jecs.Entity<nil>, newTarget: jecs.Entity<nil>)
	-- Находим модели
	local newInstance: Tool = world:get(newTarget, WorldWrapper:GetInstanceComponent()).Instance
	local placeHolderInstance: Part = world:get(placeHolder, WorldWrapper:GetInstanceComponent()).Instance

	-- Ставим поверх
	System:placeOnTop(newInstance, placeHolderInstance)

	-- Привариваем
	local weld: WeldConstraint = world:get(placeHolder, _holdsComponent).Weld
	weld.Part0 = newInstance.PrimaryPart

	-- Перевешиваем связи
	world:remove(placeHolder, _holdsComponent)
	world:set(placeHolder, _holdsComponent, { TargetEntity = newTarget, Weld = weld })

	world:remove(oldTarget, _placedComponent)
	world:set(newTarget, _placedComponent, { PlaceHolder = placeHolder })
end

-- Поднимает предмет при взаимодествии с ним
function System:processTake(
	placedEntity: jecs.Entity<nil>,
	placeHolderEntity: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if equippedTool then
		-- Если в руках что-то есть, то ничего не берем
		return
	end

	-- Отвариваем
	local weld: WeldConstraint = world:get(placeHolderEntity, _holdsComponent).Weld
	weld:Destroy()

	-- Убираем связь
	world:remove(placeHolderEntity, _holdsComponent)
	world:remove(placedEntity, _placedComponent)

	-- Выдаем в руки
	local tool: Tool = world:get(placedEntity, WorldWrapper:GetInstanceComponent()).Instance
	playerView:PutInHands(tool)
end

function System:processPlaceCommand(placeHolderEntity: jecs.Entity<nil>, targetEntity: jecs.Entity<nil>)
	local targetInstance: Tool = world:get(targetEntity, WorldWrapper:GetInstanceComponent()).Instance
	local topPart: Part = world:get(placeHolderEntity, WorldWrapper:GetInstanceComponent()).Instance

	-- Устанавливаем поверх
	targetInstance.Parent = workspace
	System:placeOnTop(targetInstance, topPart)

	-- Привариваем
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = targetInstance.PrimaryPart
	weld.Part1 = topPart
	weld.Parent = topPart

	-- Устанавливаем связи
	world:set(placeHolderEntity, _holdsComponent, { TargetEntity = targetEntity, Weld = weld })
	world:set(targetEntity, _placedComponent, { PlaceHolder = placeHolderEntity })
end

--
-- Вспомогательные методы
function System:placeOnTop(placeable: Tool, topPart: Part)
	local plateTop = topPart.CFrame * CFrame.new(0, topPart.Size.Y / 2, 0)
	local targetCFrame = plateTop * CFrame.new(0, placeable.PrimaryPart.Size.Y / 2, 0)
	placeable:SetPrimaryPartCFrame(targetCFrame)
end

--
-- Модуль
return {
	Create = CreatePlaceHolder,
	Component = placeHolderComponent,
	System = System.new() :: AbstractSystem.AbstractSystem,

	PlaceCommand = _placeCommand,
}
