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

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- IngredientForm
export type IngredientForm = {
	IngredientName: string,
	Template: Tool,
	HandsMorphFunc: ((jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance))?, -- функция превращения из одного ингредиента в другой
}

--
-- Обработчик
local IngredientSystem = Class.defineClass("IngredientSystem", AbstractSystem)

function IngredientSystem.new(
	ingredientPool, -- пул объектов
	ingredientComponent, -- система для компонента
	handsMorphFunc: ((jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance))?
): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, IngredientSystem)

	self.ingredientPool = ingredientPool
	self.ingredientComponent = ingredientComponent
	self.handsMorphFunc = handsMorphFunc

	return self
end

function IngredientSystem:Process(_: number)
	if self.handsMorphFunc then
		self:query(WorldWrapper:GetPlayerInteractComponent())
			:with(self.ingredientComponent)
			:forEach(function(entityId, intent)
				if not entityId then
					return
				end
				local keyCode: Enum.KeyCode = intent.KeyCode
				local playerView: Types.PlayerView = intent.PlayerView
				local processed = self:processPlayerInteract(entityId, playerView, keyCode)
				if processed then
					world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())
				end
			end)
	end

	self:query(WorldWrapper:GetReleaseTargetComponent())
		:with(self.ingredientComponent)
		:forEach(function(entityId: jecs.Entity<nil>, _)
			if not entityId then
				return
			end
			world:remove(entityId, WorldWrapper:GetReleaseTargetComponent())
			self.ingredientPool:Release(entityId)
		end)
end

function IngredientSystem:processPlayerInteract(target: jecs.Entity<nil>, _: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.F then
		return false
	end

	if not self.handsMorphFunc then
		return false
	end

	local nextEntity, nextInstance = self.handsMorphFunc(target)
	nextInstance.Parent = workspace
	world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })

	self.ingredientPool:Release(target)
	return true
end

--
-- Фабрика
local IngredientFactory = Class.defineClass("IngredientFactory")

local abstractIngredientComponent = world:component()

function IngredientFactory:GetAbstractIngredientComponent(): jecs.Id<nil>
	return abstractIngredientComponent
end

function IngredientFactory:DefineIngredient(ingredientForm: IngredientForm)
	local module = {}

	local ingredientComponent = world:component()

	module.Component = ingredientComponent

	module.Pool = ObjectPool.new(function()
		local instance: Tool = ingredientForm.Template:Clone()
		instance:AddTag(Consts.Tags.Interactable)

		local entity = WorldWrapper:RegisterInstance(instance, ingredientForm.IngredientName)
		world:set(entity, abstractIngredientComponent)
		world:set(entity, ingredientComponent)
		world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

		return entity, instance
	end, 5)

	module.System = IngredientSystem.new(module.Pool, ingredientComponent, ingredientForm.HandsMorphFunc)

	return module
end

return IngredientFactory
