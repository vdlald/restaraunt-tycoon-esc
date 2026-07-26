--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- DishForm
export type DishForm = {
	DishName: string,
	Template: Tool,
	CombineIngredients: (jecs.Entity<nil>, jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance),
	CombineDish: (jecs.Entity<nil>, jecs.Entity<nil>) -> (), -- объединяет игридиенты в блюдо
}

--
-- Обработчик
local DishSystem = Class.defineClass("DishSystem", AbstractSystem)

function DishSystem.new(
	DishPool, -- пул объектов
	DishComponent, -- система для компонента
	CombineIngredients: (self: DishSystem, jecs.Entity<nil>, jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance),
	CombineDish: (self: DishSystem, jecs.Entity<nil>, jecs.Entity<nil>) -> () -- объединяет игридиенты в блюдо
): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, DishSystem)

	self.DishPool = DishPool
	self.DishComponent = DishComponent
	self._combineIngredients = CombineIngredients
	self._combineDish = CombineDish

	return self
end

function DishSystem:Process(_: number) end

function DishSystem:HandleInteraction(
	target: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
): boolean
	if world:has(target, IngredientFactory:GetAbstractIngredientComponent()) then
		return self:combineIngredients(target, playerView, keyCode)
	end
	if world:has(target, self.DishComponent) then
		return self:combineDish(target, playerView, keyCode)
	end
	return false
end

function DishSystem:combineIngredients(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return false
	end

	local equipped = playerView:GetEquippedTool()
	if not equipped or not world:has(equipped, IngredientFactory:GetAbstractIngredientComponent()) then
		-- Если в руках ничего нет или держим не ингредиент, то выходим
		return false
	end

	if not self._combineIngredients then
		return false
	end

	local nextEntity, nextInstance = self:_combineIngredients(target, equipped)
	if not nextEntity then
		return false
	end

	nextInstance.Parent = workspace
	world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })

	return true
end

function DishSystem:combineDish(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return false
	end

	local equipped = playerView:GetEquippedTool()
	if not equipped or not world:has(equipped, IngredientFactory:GetAbstractIngredientComponent()) then
		-- Если в руках ничего нет или держим не ингредиент, то выходим
		return false
	end

	if not self._combineDish then
		return false
	end

	local nextEntity, nextInstance = self._combineDish(target, equipped)
	if not nextEntity then
		return false
	end

	nextInstance.Parent = workspace
	world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })

	return true
end

--
-- Фабрика
local DishFactory = Class.defineClass("DishFactory")

local abstractDishComponent = world:component()

function DishFactory:GetAbstractDishComponent(): jecs.Id<nil>
	return abstractDishComponent
end

function DishFactory:DefineDish(DishForm: DishForm)
	local module = {}

	local DishComponent = world:component()

	module.Component = DishComponent

	module.Pool = ObjectPool.new(function()
		local instance: Tool = DishForm.Template:Clone()
		local entity = WorldWrapper:RegisterInstance(instance, DishForm.DishName)
		world:set(entity, abstractDishComponent)
		world:set(entity, DishComponent)
		world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

		return entity, instance
	end, 5)

	module.System = DishSystem.new(module.Pool, DishComponent, DishForm.CombineIngredients, DishForm.CombineDish)

	return module
end

return DishFactory
