--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Utils = require(ReplicatedStorage.Shared.Utils)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- Компонент
export type GuestNpcComponent = jecs.Id<nil>
local GuestNpcComponent = world:component() :: GuestNpcComponent

--
-- Объявление сущности
function CreateGuestNpc(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.NPC.Guest:Clone()
    instance:AddTag("Interactable")

	local entity = WorldWrapper:RegisterInstance(instance, "Trashcan")
	world:set(entity, GuestNpcComponent)
    world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end

--
-- Объявление обработчика
local System = Class.defineClass("System", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)

	self.cachedQuery = world:query(WorldWrapper:GetPlayerInteractComponent()):with(GuestNpcComponent):cached()

	return self
end

function System:Process(_: number)
	for entityId, intent in self.cachedQuery do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
			self:processPlayerInteract(entityId, playerView, keyCode)
		end)
	end
end

local DishFactory = require(ServerScriptService.Server.Game.Dish.DishFactory)

function System:processPlayerInteract(
	_: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool then
        return
	end

    if not world:has(equippedTool, DishFactory:GetAbstractDishComponent()) then
        return
    end
    world:set(equippedTool, WorldWrapper:GetReleaseTargetComponent())
    playerView:TakeFromHands()
    print("dish eaten")
end

--
-- Модуль
return {
	Create = CreateGuestNpc,
	Component = GuestNpcComponent,
    System = System.new(),
}
