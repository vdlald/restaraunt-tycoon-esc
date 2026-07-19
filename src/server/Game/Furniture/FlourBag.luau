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

local cachedQuery = world:query(WorldWrapper:GetPlayerInteractComponent()):with(flourBagComponent):cached()

function System:Process(_: number)
	for entityId, intent in cachedQuery do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
			System:processPlayerInteract(entityId, playerView, keyCode)
		end)
	end
end

local Flour = require(ServerScriptService.Server.Game.Ingridient.Flour)
function System:processPlayerInteract(_: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool then
		local _, flourInstance = Flour.Pool:Get()
		flourInstance.Parent = workspace
		playerView:PutInHands(flourInstance)
		return
	end

	if world:has(equippedTool, Flour.Component) then
		playerView:TakeFromHands()
		Flour.Pool:Release(equippedTool)
	end
end

--
-- Модуль
return {
	Create = CreateFlourBag,
	Component = flourBagComponent,
	System = System.new() :: AbstractSystem.AbstractSystem,
}
