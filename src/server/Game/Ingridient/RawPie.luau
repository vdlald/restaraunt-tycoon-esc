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
export type RawPieComponent = jecs.Id<nil>
local rawPieComponent = world:component() :: RawPieComponent

--
-- Объявление сущности
local ObjectPool = require(ServerScriptService.Server.ObjectPool)

local RawPiePool = ObjectPool.new(function()
	local instance: Tool = ServerStorage.Ingridient.RawPie:Clone()
	instance:AddTag(Consts.Tags.Interactable)

	local entity = WorldWrapper:RegisterInstance(instance, "RawPie")
	world:set(entity, rawPieComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end, 5)

--
-- Объявление обработчика
local System = Class.defineClass("RawPieSystem", AbstractSystem)

function System.new(): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	return self
end

function System:Process(_: number)
	self:query(WorldWrapper:GetPlayerInteractComponent()):with(rawPieComponent):forEach(function(entityId, intent)
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

function System:processPlayerInteract(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	print(playerView, keyCode, target)
end

--
-- Модуль
return {
	Pool = RawPiePool,
	Component = rawPieComponent,
	System = System.new(),
}
