--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- Компонент
export type KitchenTableComponent = jecs.Id<nil>
local kitchenTableComponent = world:component() :: KitchenTableComponent

--
-- Объявление сущности
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)

function CreateKitchenTable(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Furniture.KitchenTable:Clone()
	instance:AddTag(Consts.Tags.BuildingMoveable)
	local top = instance:WaitForChild("top_geom")

	local placeHolderEntity, _ = PlaceHolder.Create(top)

	local entity = WorldWrapper:RegisterInstance(instance, "KitchenTable")
	world:set(entity, kitchenTableComponent)
	world:set(entity, WorldWrapper:GetBuildingMovableComponent())

	return entity, instance, placeHolderEntity
end

--
-- Модуль
return {
	Create = CreateKitchenTable,
	Component = kitchenTableComponent,
}
