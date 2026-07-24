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
-- IngredientFurnitureForm
export type IngredientFurnitureForm = {
	FurnitureName: string,
	Template: Model,
	IngredientPool: ObjectPool.ObjectPool, -- пул ингредиента
	IngredientComponent: jecs.Id<nil>,
}

--
-- Объявление обработчика
local IngredientFurnitureSystem = Class.defineClass("IngredientFurnitureSystem", AbstractSystem)

function IngredientFurnitureSystem.new(
	furnitureComponent: jecs.Id<nil>,
	ingredientComponent: jecs.Id<nil>,
	ingredientPool: ObjectPool.ObjectPool
)
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, IngredientFurnitureSystem)

	self.cachedQuery = world:query(WorldWrapper:GetPlayerInteractComponent()):with(furnitureComponent):cached()
	self.ingredientPool = ingredientPool
	self.ingredientComponent = ingredientComponent

	return self
end

function IngredientFurnitureSystem:Process(_: number)
	for entityId, intent in self.cachedQuery do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
			self:processPlayerInteract(entityId, playerView, keyCode)
		end)
	end
end

function IngredientFurnitureSystem:processPlayerInteract(
	_: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool then
		local _, ingredientInstance = self.ingredientPool:Get()
		ingredientInstance.Parent = workspace
		playerView:PutInHands(ingredientInstance)
		return
	end

	if world:has(equippedTool, self.ingredientComponent) then
		playerView:TakeFromHands()
		self.ingredientPool:Release(equippedTool)
	end
end

--
-- Фабрика
local IngredientFurnitureFactory = Class.defineClass("IngredientFurnitureFactory")

function IngredientFurnitureFactory:DefineFurniture(form: IngredientFurnitureForm)
	local module = {}

	local furnitureComponent = world:component()

	module.Component = furnitureComponent

	module.Create = function(): (jecs.Entity<nil>, Instance)
		local instance: Instance = form.Template:Clone()
		instance:AddTag(Consts.Tags.Interactable)
		instance:AddTag(Consts.Tags.BuildingMoveable)

		local entity = WorldWrapper:RegisterInstance(instance, form.FurnitureName)
		world:set(entity, furnitureComponent)
		world:set(entity, WorldWrapper:GetPlayerInteractableComponent())
		world:set(entity, WorldWrapper:GetBuildingMovableComponent())

		return entity, instance
	end

	module.System = IngredientFurnitureSystem.new(furnitureComponent, form.IngredientComponent, form.IngredientPool)

	return module
end

return IngredientFurnitureFactory
