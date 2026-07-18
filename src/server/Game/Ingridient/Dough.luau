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
export type DoughComponent = jecs.Id<nil>
local doughComponent = world:component() :: DoughComponent

--
-- Объявление сущности
local ObjectPool = require(ServerScriptService.Server.ObjectPool)

local DoughPool = ObjectPool.new(function()
	local instance: Tool = ServerStorage.Ingridient.Dough:Clone()
	instance:AddTag(Consts.Tags.Interactable)

	local entity = WorldWrapper:RegisterInstance(instance, "Dough")
	world:set(entity, doughComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end, 5)

--
-- Объявление обработчика
local System = Class.defineClass("DoughSystem", AbstractSystem)

function System.new(): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	return self
end

local cachedQuery = world:query(doughComponent, WorldWrapper:GetPlayerInteractComponent()):cached()

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
	Pool = DoughPool,
	Component = doughComponent,
	System = System.new(),
}
