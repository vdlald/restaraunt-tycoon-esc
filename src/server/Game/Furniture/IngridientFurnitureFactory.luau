--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Utils = require(ReplicatedStorage.Shared.Utils)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- IngridientFurnitureForm
export type IngridientFurnitureForm = {
	FurnitureName: string,
	Template: Model,
	IngridientPool: ObjectPool.ObjectPool, -- пул ингредиента
	IngridientComponent: jecs.Id<nil>,
}

--
-- Объявление обработчика
local IngridientFurnitureSystem = Class.defineClass("IngridientFurnitureSystem", AbstractSystem)

function IngridientFurnitureSystem.new(
	furnitureComponent: jecs.Id<nil>,
	ingridientComponent: jecs.Id<nil>,
	ingridientPool: ObjectPool.ObjectPool
)
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, IngridientFurnitureSystem)

	self.cachedQuery = world:query(WorldWrapper:GetPlayerInteractComponent()):with(furnitureComponent):cached()
	self.ingridientPool = ingridientPool
	self.ingridientComponent = ingridientComponent

	return self
end

function IngridientFurnitureSystem:Process(_: number)
	for entityId, intent in self.cachedQuery do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
			self:processPlayerInteract(entityId, playerView, keyCode)
		end)
	end
end

function IngridientFurnitureSystem:processPlayerInteract(
	_: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool then
		local _, flourInstance = self.ingridientPool:Get()
		flourInstance.Parent = workspace
		playerView:PutInHands(flourInstance)
		return
	end

	if world:has(equippedTool, self.ingridientComponent) then
		playerView:TakeFromHands()
		self.ingridientPool:Release(equippedTool)
	end
end

--
-- Фабрика
local IngridientFurnitureFactory = Class.defineClass("IngridientFurnitureFactory")

function IngridientFurnitureFactory:DefineFurniture(form: IngridientFurnitureForm)
	local module = {}

	local furnitureComponent = world:component()

	module.Component = furnitureComponent

	module.Create = function(): (jecs.Entity<nil>, Instance)
		local instance: Instance = form.Template
		instance:AddTag(Consts.Tags.Interactable)

		local entity = WorldWrapper:RegisterInstance(instance, form.FurnitureName)
		world:set(entity, furnitureComponent)
		world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

		return entity, instance
	end

	module.System = IngridientFurnitureSystem.new(furnitureComponent, form.IngridientComponent, form.IngridientPool)

	return module
end

return IngridientFurnitureFactory
