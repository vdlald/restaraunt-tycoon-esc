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
export type DiningTableComponent = jecs.Id<nil>
local DiningTableComponent = world:component() :: DiningTableComponent

--
-- Объявление сущности
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)

function CreateDiningTable(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Furniture.DiningTable:Clone()
	local entity = WorldWrapper:RegisterInstance(instance, "DiningTable")
	world:set(entity, DiningTableComponent)

	instance:AddTag(Consts.Tags.Furniture)

	local top = instance:WaitForChild("top_part")
	local placeHolderEntity, _ = PlaceHolder.Create(top, entity)

	return entity, instance, placeHolderEntity
end

--
-- Модуль
return {
	Create = CreateDiningTable,
	Component = DiningTableComponent,
}
