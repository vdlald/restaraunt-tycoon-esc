--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local ServerScriptService = game:GetService("ServerScriptService")
local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- Компонент
export type DiningTableComponent = jecs.Id<nil>
local DiningTableComponent = world:component() :: DiningTableComponent

--
-- Объявление сущности
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)

function CreateDiningTable(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Furniture.DiningTable:Clone()
	local top = instance:WaitForChild("top_part")

	local placeHolderEntity, _ = PlaceHolder.Create(top)

	local entity = WorldWrapper:RegisterInstance(instance, "DiningTable")
	world:set(entity, DiningTableComponent)
	world:set(entity, WorldWrapper:GetBuildingMovableComponent())

	return entity, instance, placeHolderEntity
end

--
-- Модуль
return {
	Create = CreateDiningTable,
	Component = DiningTableComponent,
}
