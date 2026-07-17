--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

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
export type FlourComponent = jecs.Id<nil>
local flourComponent = world:component() :: FlourComponent

--
-- Объявление сущности
local ObjectPool = require(ServerScriptService.Server.ObjectPool)

local FlourPool = ObjectPool.new(function()
	local instance: Tool = ServerStorage.Ingridient.Flour:Clone()
	instance:AddTag(Consts.Tags.Interactable)

	local entity = WorldWrapper:RegisterInstance(instance, "Flour")
	world:set(entity, flourComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end, 5)

--
-- Объявление обработчика
local System = Class.defineClass("FlourBagSystem", AbstractSystem)

function System.new(): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	return self
end

local cachedQuery = world:query(flourComponent, WorldWrapper:GetPlayerInteractComponent()):cached()

function System:Process(_: number)
	for entityId, _, intent in cachedQuery do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local ok, err = pcall(self.processPlayerInteract, self, entityId, playerView, keyCode)
		if not ok then
			local trace = debug.traceback(err, 1)
			warn(`{self.ClassName}.processPlayerInteract failed\n`, trace)
		end
	end
end

function System:processPlayerInteract(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	print(playerView, keyCode, target)
end

--
-- Модуль
return {
	Pool = FlourPool,
	Component = flourComponent,
	System = System.new(),
}
