--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

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
export type TrashcanComponent = jecs.Id<nil>
local TrashcanComponent = world:component() :: TrashcanComponent

--
-- Объявление сущности
function CreateTrashcan(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Furniture.Trashcan:Clone()
	instance:AddTag(Consts.Tags.Interactable)
	instance:AddTag(Consts.Tags.BuildingMoveable)

	local entity = WorldWrapper:RegisterInstance(instance, "Trashcan")
	world:set(entity, TrashcanComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())
	world:set(entity, WorldWrapper:GetBuildingMovableComponent())

	return entity, instance
end

--
-- Объявление обработчика
local System = Class.defineClass("System", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)

	self.cachedQuery = world:query(WorldWrapper:GetPlayerInteractComponent()):with(TrashcanComponent):cached()

	return self
end

function System:Process(_: number)
	for entityId, intent in self.cachedQuery do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
			self:processPlayerInteract(entityId, playerView, keyCode)
		end)
	end
end

local DishFactory = require(ServerScriptService.Server.Game.Dish.DishFactory)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

function System:processPlayerInteract(_: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool then
		return
	end

	if
		not world:has(equippedTool, IngredientFactory:GetAbstractIngredientComponent())
		and not world:has(equippedTool, DishFactory:GetAbstractDishComponent())
	then
		return
	end
	world:set(equippedTool, WorldWrapper:GetReleaseTargetComponent())
	playerView:TakeFromHands()
end

--
-- Модуль
return {
	Create = CreateTrashcan,
	Component = TrashcanComponent,
	System = System.new(),
}
