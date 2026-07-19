--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local IngridientFactory = require(ServerScriptService.Server.Game.Ingridient.IngridientFactory)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- DishForm
export type DishForm = {
	DishName: string,
	Template: Tool,
	CombineIngridients: (jecs.Entity<nil>, jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance),
	CombineDish: (jecs.Entity<nil>, jecs.Entity<nil>) -> (), -- объединяет игридиенты в блюдо
}

--
-- Обработчик
local DishSystem = Class.defineClass("DishSystem", AbstractSystem)

function DishSystem.new(
	DishPool, -- пул объектов
	DishComponent, -- система для компонента
	CombineIngridients: (self: DishSystem, jecs.Entity<nil>, jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance),
	CombineDish: (self: DishSystem, jecs.Entity<nil>, jecs.Entity<nil>) -> () -- объединяет игридиенты в блюдо
): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, DishSystem)

	self.DishPool = DishPool
	self.DishComponent = DishComponent
	self._combineIngridients = CombineIngridients
	self._combineDish = CombineDish

	return self
end

function DishSystem:Process(_: number)
	-- Обрабатываем объединение ингридиентов
	self:query(WorldWrapper:GetPlayerInteractComponent())
		:with(IngridientFactory:GetAbstractIngridientComponent())
		:forEach(function(ingridientEntity, intent)
			if not ingridientEntity then
				return
			end
			local keyCode: Enum.KeyCode = intent.KeyCode
			local playerView: Types.PlayerView = intent.PlayerView
			local processed = self:combineIngridients(ingridientEntity, playerView, keyCode)
			if processed then
				world:remove(ingridientEntity, WorldWrapper:GetPlayerInteractComponent())
			end
		end)

	-- Обрабатываем добавление игредиента в блюдо
	self:query(WorldWrapper:GetPlayerInteractComponent())
		:with(self.DishComponent)
		:forEach(function(dishEntity: jecs.Entity<nil>, intent)
			if not dishEntity then
				return
			end
			local keyCode: Enum.KeyCode = intent.KeyCode
			local playerView: Types.PlayerView = intent.PlayerView
			local processed = self:combineDish(dishEntity, playerView, keyCode)
			if processed then
				world:remove(dishEntity, WorldWrapper:GetPlayerInteractComponent())
			end
		end)
end

function DishSystem:combineIngridients(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return false
	end

	local equipped = playerView:GetEquippedTool()
	if not equipped or not world:has(equipped, IngridientFactory:GetAbstractIngridientComponent()) then
		-- Если в руках ничего нет или держим не ингредиент, то выходим
		return false
	end

	if not self._combineIngridients then
		return false
	end

	local nextEntity, nextInstance = self:_combineIngridients(target, equipped)
	if not nextEntity then
		return false
	end

	nextInstance.Parent = workspace
	world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })

	return true
end

function DishSystem:combineDish(target: jecs.Entity<nil>, _: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return false
	end

	if not self._combineDish then
		return false
	end

	local nextEntity, nextInstance = self._combineDish(target)
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

function DishFactory:DefineDish(DishForm: DishForm)
	local module = {}

	local DishComponent = world:component()

	module.Component = DishComponent

	module.Pool = ObjectPool.new(function()
		local instance: Tool = DishForm.Template:Clone()
		instance:AddTag(Consts.Tags.Interactable)

		local entity = WorldWrapper:RegisterInstance(instance, DishForm.DishName)
		world:set(entity, DishComponent)
		world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

		return entity, instance
	end, 5)

	module.System = DishSystem.new(module.Pool, DishComponent, DishForm.CombineIngridients, DishForm.CombineDish)

	return module
end

return DishFactory
