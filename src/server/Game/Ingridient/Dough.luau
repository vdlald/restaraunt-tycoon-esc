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

function System:Process(_: number)
	self:query(WorldWrapper:GetPlayerInteractComponent()):with(doughComponent):forEach(function(entityId, intent)
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

local RawPie = require(ServerScriptService.Server.Game.Ingridient.RawPie)
function System:processPlayerInteract(target: jecs.Entity<nil>, _: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.F then
		return false
	end

	local doughEntity, doughInstance = RawPie.Pool:Get()
	doughInstance.Parent = workspace
	world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = doughEntity })

	DoughPool:Release(target)
	return true
end

--
-- Модуль
return {
	Pool = DoughPool,
	Component = doughComponent,
	System = System.new(),
}
