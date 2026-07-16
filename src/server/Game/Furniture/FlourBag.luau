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
export type FlourBagComponent = jecs.Id<nil>
local flourBagComponent = world:component() :: FlourBagComponent

--
-- Объявление сущности
function CreateFlourBag(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Furniture.FlourBag:Clone()
	instance:AddTag(Consts.Tags.Interactable)

	local entity = WorldWrapper:RegisterInstance(instance, "FlourBag")
	world:set(entity, flourBagComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end

--
-- Объявление обработчика
local System = Class.defineClass("FlourBagSystem", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	return self
end

local cachedQuery = world:query(flourBagComponent, WorldWrapper:GetPlayerInteractComponent()):cached()

function System:Process(_: number)
	for entityId, _, intent in cachedQuery do
		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local ok, err = pcall(self.processPlayerInteract, self, entityId, playerView, keyCode)
		if not ok then
			error(`{self.ClassName}.processPlayerInteract failed: {err}`)
		end

		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())
	end
end

function System:processPlayerInteract(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	print(playerView, keyCode, target)
end

--
-- Модуль
return {
	Create = CreateFlourBag,
	Component = flourBagComponent,
	System = System.new() :: AbstractSystem.AbstractSystem,
}
