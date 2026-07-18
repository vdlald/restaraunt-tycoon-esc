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

export type Holds = jecs.Id<nil>
local _holdsComponent = world:component() :: Holds

export type Placed = jecs.Id<{ PlaceHolderEntity: jecs.Id<nil> }>
local _placedComponent = world:component() :: Placed

--
-- Объявление сущности
function CreatePlaceHolder(instance: Instance): (jecs.Entity<nil>, Instance)
	instance:AddTag(Consts.Tags.Interactable)

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

-- Ищем взаимодействие с пустым placeholder
local findEmptyPlaceHoldersQuery = function()
	return world
		:query(WorldWrapper:GetPlayerInteractComponent())
		:with(placeHolderComponent)
		:without(jecs.pair(_holdsComponent, jecs.Wildcard))
end

-- Ищем взаимодействие с placeholder, который что-то содержит
local findFilledPlaceHoldersQuery = function()
	return world
		:query(WorldWrapper:GetPlayerInteractComponent())
		:with(placeHolderComponent, jecs.pair(_holdsComponent, jecs.Wildcard))
end

-- Ищем компоненты, которые на placeholder и их требуется заменить на новые
local findToReplaceHoldersQuery = function()
	return world:query(_placedComponent, WorldWrapper:GetReplaceTargetComponent())
end

-- Ищем компоненты, которые лежат на placeholder и их хотят поднять
local findDirectItemInteract = function()
	return world:query(_placedComponent, WorldWrapper:GetPlayerInteractComponent())
end

function System:Process(_: number)
	for entityId, intent in findEmptyPlaceHoldersQuery() do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local ok, err = pcall(function()
			System:processPlace(entityId, playerView, keyCode)
		end)
		if not ok then
			local trace = debug.traceback(err)
			warn(`{self.ClassName}.processPlayerInteract failed\n`, trace)
		end
	end

	for entityId, intent in findFilledPlaceHoldersQuery() do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local ok, err = pcall(function()
			System:processTake(entityId, playerView, keyCode)
		end)
		if not ok then
			local trace = debug.traceback(err)
			warn(`{self.ClassName}.processPlayerInteract failed\n`, trace)
		end
	end

	for entityId, placedComponent, replaceComponent in findToReplaceHoldersQuery() do
		world:remove(entityId, WorldWrapper:GetReplaceTargetComponent())

		local placeHolder = placedComponent.PlaceHolder
		local oldTarget, newTarget = entityId, replaceComponent.NewTarget

		local ok, err = pcall(function()
			System:processReplace(placeHolder, oldTarget, newTarget)
		end)
		if not ok then
			local trace = debug.traceback(err)
			warn(`{self.ClassName}.processPlayerInteract failed\n`, trace)
		end
	end

	for entityId, placedComponent, intent in findDirectItemInteract() do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local placeHolder = placedComponent.PlaceHolder
		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local ok, err = pcall(function()
			System:processDirectInteract(entityId, placeHolder, playerView, keyCode)
		end)
		if not ok then
			local trace = debug.traceback(err)
			warn(`{self.ClassName}.processPlayerInteract failed\n`, trace)
		end
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

	local equippedToolInstance: Tool = world:get(equippedToolEntity, WorldWrapper:GetInstanceComponent()).Instance
	local topPart: Part = world:get(placeHolderEntity, WorldWrapper:GetInstanceComponent()).Instance

	-- Устанавливаем поверх
	equippedToolInstance.Parent = workspace
	System:placeOnTop(equippedToolInstance, topPart)

	-- Привариваем
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = equippedToolInstance.PrimaryPart
	weld.Part1 = topPart
	weld.Parent = topPart

	-- Устанавливаем связи
	world:set(placeHolderEntity, jecs.pair(_holdsComponent, equippedToolEntity), weld)
	world:set(equippedToolEntity, _placedComponent, { PlaceHolder = placeHolderEntity })
end

-- Поднятие с места пользователем
function System:processTake(entityId: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if equippedTool then
		-- Если в руках что-то есть, то ничего не берем
		return
	end

	-- Находим предмет, который держим
	local targetEntityId = world:target(entityId, _holdsComponent)

	-- Отвариваем
	local weld: WeldConstraint = world:get(entityId, jecs.pair(_holdsComponent, targetEntityId))
	weld:Destroy()

	-- Убираем связь
	world:remove(entityId, jecs.pair(_holdsComponent, targetEntityId))
	world:remove(targetEntityId, _placedComponent)

	-- Выдаем в руки
	local tool: Tool = world:get(targetEntityId, WorldWrapper:GetInstanceComponent()).Instance
	playerView:PutInHands(tool)
end

-- Замена предмета
function System:processReplace(placeHolder: jecs.Entity<nil>, oldTarget: jecs.Entity<nil>, newTarget: jecs.Entity<nil>)
	-- Находим модели
	local newInstance: Tool = world:get(newTarget, WorldWrapper:GetInstanceComponent()).Instance
	local placeHolderInstance: Part = world:get(placeHolder, WorldWrapper:GetInstanceComponent()).Instance

	-- Ставим поверх
	System:placeOnTop(newInstance, placeHolderInstance)

	-- Привариваем
	local weld: WeldConstraint = world:get(placeHolder, jecs.pair(_holdsComponent, oldTarget))
	weld.Part0 = newInstance.PrimaryPart

	-- Перевешиваем связи
	world:remove(placeHolder, jecs.pair(_holdsComponent, oldTarget))
	world:set(placeHolder, jecs.pair(_holdsComponent, newTarget), weld)

	world:remove(oldTarget, _placedComponent)
	world:set(newTarget, _placedComponent, { PlaceHolder = placeHolder })
end

function System:placeOnTop(placeable: Tool, topPart: Part)
	local plateTop = topPart.CFrame * CFrame.new(0, topPart.Size.Y / 2, 0)
	local targetCFrame = plateTop * CFrame.new(0, placeable.PrimaryPart.Size.Y / 2, 0)
	placeable:SetPrimaryPartCFrame(targetCFrame)
end

-- Поднимает предмет при взаимодествии с ним
function System:processDirectInteract(
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
	local weld: WeldConstraint = world:get(placeHolderEntity, jecs.pair(_holdsComponent, placedEntity))
	weld:Destroy()

	-- Убираем связь
	world:remove(placeHolderEntity, jecs.pair(_holdsComponent, placedEntity))
	world:remove(placedEntity, _placedComponent)

	-- Выдаем в руки
	local tool: Tool = world:get(placedEntity, WorldWrapper:GetInstanceComponent()).Instance
	playerView:PutInHands(tool)
end

--
-- Модуль
return {
	Create = CreatePlaceHolder,
	Component = placeHolderComponent,
	System = System.new() :: AbstractSystem.AbstractSystem,
}
