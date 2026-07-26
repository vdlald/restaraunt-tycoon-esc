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

export type TrashcanComponent = jecs.Id<nil>

--
-- Объявление обработчика
local System = Class.defineClass("System", AbstractSystem)

function System.new(worldContext, trashcanComponent, ingredientFactory, dishFactory)
	local parent = AbstractSystem.new(worldContext)
	local self = setmetatable(parent, System)
	self.trashcanComponent = trashcanComponent
	self.ingredientFactory = ingredientFactory
	self.dishFactory = dishFactory

	return self
end

function System:Process(_: number) end

function System:processPlayerInteract(_: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool then
		return
	end

	if
		not self.world:has(equippedTool, self.ingredientFactory:GetAbstractIngredientComponent())
		and not self.world:has(equippedTool, self.dishFactory:GetAbstractDishComponent())
	then
		return
	end
	self.worldWrapper:RequestDestroy(equippedTool)
	playerView:TakeFromHands()
end

function System:HandleInteraction(
	entityId: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
): boolean
	if not self.world:has(entityId, self.trashcanComponent) then
		return false
	end
	Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
		self:processPlayerInteract(entityId, playerView, keyCode)
	end)
	return true
end

--
-- Модуль
local Trashcan = {}

function Trashcan.new(worldContext, ingredientFactory, dishFactory)
	local world = worldContext:GetWorld()
	local trashcanComponent = world:component() :: TrashcanComponent

	local function createTrashcan(): (jecs.Entity<nil>, Instance)
		local instance: Instance = ServerStorage.Furniture.Trashcan:Clone()
		local entity = worldContext:RegisterInstance(instance, "Trashcan")
		world:set(entity, trashcanComponent)
		world:set(entity, worldContext:GetPlayerInteractableComponent())
		world:set(entity, worldContext:GetBuildingMovableComponent())

		return entity, instance
	end

	return {
		Create = createTrashcan,
		Component = trashcanComponent,
		System = System.new(worldContext, trashcanComponent, ingredientFactory, dishFactory),
	}
end

return Trashcan
