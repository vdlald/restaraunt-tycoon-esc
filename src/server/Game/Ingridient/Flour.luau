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
local System = Class.defineClass("FlourSystem", AbstractSystem)

function System.new(): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	return self
end

local cachedQuery = function()
	return world:query(WorldWrapper:GetPlayerInteractComponent()):with(flourComponent)
end

function System:Process(_: number)
	for entityId, intent in cachedQuery() do
		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local res, _ = Utils:safeCall(`{self.ClassName}.processPlayerInteract`, function()
			return self:processPlayerInteract(entityId, playerView, keyCode)
		end)

		if res then
			world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())
		end
	end
end

local Dough = require(ServerScriptService.Server.Game.Ingridient.Dough)
function System:processPlayerInteract(target: jecs.Entity<nil>, _: Types.PlayerView, keyCode: Enum.KeyCode): boolean
	if keyCode ~= Enum.KeyCode.F then
		return false
	end

	local doughEntity, doughInstance = Dough.Pool:Get()
	doughInstance.Parent = workspace
	world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = doughEntity })

	FlourPool:Release(target)
	return true
end

--
-- Модуль
return {
	Pool = FlourPool,
	Component = flourComponent,
	System = System.new(),
}
