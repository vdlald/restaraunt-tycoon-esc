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
export type DinningTableComponent = jecs.Id<nil>
local DinningTableComponent = world:component() :: DinningTableComponent

--
-- Объявление сущности
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)

function CreateDinningTable(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Furniture.DinningTable:Clone()
	local top = instance:WaitForChild("top_part")

	local placeHolderEntity, _ = PlaceHolder.Create(top)

	local entity = WorldWrapper:RegisterInstance(instance, "DinningTable")
	world:set(entity, DinningTableComponent)

	return entity, instance, placeHolderEntity
end

--
-- Модуль
return {
	Create = CreateDinningTable,
	Component = DinningTableComponent,
}
