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
-- IngridientForm
export type IngridientForm = {
	IngridientName: string,
	Template: Tool,
	HandsMorhpFunc: (jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance) -- функция превращения из одного ингридиента в другой
}

--
-- Обработчик
local IngridientSystem = Class.defineClass("IngridientSystem", AbstractSystem)

function IngridientSystem.new(
	ingridientPool, -- пул объектов
	ingridientComponent, -- система для компонента
	handsMorhpFunc: (jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance)
): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, IngridientSystem)

	self.ingridientPool = ingridientPool
	self.ingridientComponent = ingridientComponent
	self.handsMorhpFunc = handsMorhpFunc

	return self
end

function IngridientSystem:Process(_: number)
	self:query(WorldWrapper:GetPlayerInteractComponent())
		:with(self.ingridientComponent)
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

function IngridientSystem:processPlayerInteract(target: jecs.Entity<nil>, _: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.F then
		return false
	end

	if not self.handsMorhpFunc then
		return false
	end

	local nextEntity, nextInstance = self.handsMorhpFunc(target)
	nextInstance.Parent = workspace
	world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })

	self.ingridientPool:Release(target)
	return true
end

--
-- Фабрика
local IngridientFactory = Class.defineClass("IngridientFactory")

local abstractIngridientComponent = world:component()

function IngridientFactory:GetAbstractIngridientComponent(): jecs.Id<nil>
	return abstractIngridientComponent
end

function IngridientFactory:DefineIngridient(ingridientForm: IngridientForm)
	local module = {}

	local ingridientComponent = world:component()

	module.Component = ingridientComponent

	module.Pool = ObjectPool.new(function()
		local instance: Tool = ingridientForm.Template:Clone()
		instance:AddTag(Consts.Tags.Interactable)

		local entity = WorldWrapper:RegisterInstance(instance, ingridientForm.IngridientName)
		world:set(entity, abstractIngridientComponent)
		world:set(entity, ingridientComponent)
		world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

		return entity, instance
	end, 5)

	module.System = IngridientSystem.new(module.Pool, ingridientComponent, ingridientForm.HandsMorhpFunc)

	return module
end

return IngridientFactory
