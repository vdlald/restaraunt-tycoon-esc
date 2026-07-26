--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
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
	worldWrapper,
	ingredientFactory,
	DishPool, -- пул объектов
	DishComponent, -- система для компонента
	CombineIngredients: (self: DishSystem, jecs.Entity<nil>, jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance),
	CombineDish: (self: DishSystem, jecs.Entity<nil>, jecs.Entity<nil>) -> () -- объединяет игридиенты в блюдо
): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new(worldWrapper)
	local self = setmetatable(parent, DishSystem)

	self.DishPool = DishPool
	self.DishComponent = DishComponent
	self._combineIngredients = CombineIngredients
	self._combineDish = CombineDish
	self.worldWrapper = worldWrapper
	self.ingredientFactory = ingredientFactory

	return self
end

function DishSystem:Process(_: number) end

function DishSystem:HandleInteraction(
	target: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
): boolean
	if self.world:has(target, self.ingredientFactory:GetAbstractIngredientComponent()) then
		return self:combineIngredients(target, playerView, keyCode)
	end
	if self.world:has(target, self.DishComponent) then
		return self:combineDish(target, playerView, keyCode)
	end
	return false
end

function DishSystem:combineIngredients(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return false
	end

	local equipped = playerView:GetEquippedTool()
	if not equipped or not self.world:has(equipped, self.ingredientFactory:GetAbstractIngredientComponent()) then
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
	self.world:set(target, self.worldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })

	return true
end

function DishSystem:combineDish(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return false
	end

	local equipped = playerView:GetEquippedTool()
	if not equipped or not self.world:has(equipped, self.ingredientFactory:GetAbstractIngredientComponent()) then
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
	self.world:set(target, self.worldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })

	return true
end

--
-- Фабрика
local DishFactory = {}
DishFactory.__index = DishFactory

function DishFactory.new(worldWrapper, lifecycleSystem, ingredientFactory)
	local world = worldWrapper:GetWorld()
	return setmetatable({
		worldWrapper = worldWrapper,
		lifecycleSystem = lifecycleSystem,
		ingredientFactory = ingredientFactory,
		world = world,
		abstractDishComponent = world:component(),
	}, DishFactory)
end

function DishFactory:GetAbstractDishComponent(): jecs.Id<nil>
	return self.abstractDishComponent
end

function DishFactory:DefineDish(DishForm: DishForm)
	local module = {}

	local DishComponent = self.world:component()

	module.Component = DishComponent

	module.Pool = ObjectPool.new(self.worldWrapper, self.lifecycleSystem, function()
		local instance: Tool = DishForm.Template:Clone()
		local entity = self.worldWrapper:RegisterInstance(instance, DishForm.DishName)
		self.world:set(entity, self.abstractDishComponent)
		self.world:set(entity, DishComponent)
		self.world:set(entity, self.worldWrapper:GetPlayerInteractableComponent())

		return entity, instance
	end, 5)

	module.System = DishSystem.new(
		self.worldWrapper,
		self.ingredientFactory,
		module.Pool,
		DishComponent,
		DishForm.CombineIngredients,
		DishForm.CombineDish
	)

	return module
end

return DishFactory
