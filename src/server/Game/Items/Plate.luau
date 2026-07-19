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
export type PlateComponent = jecs.Id<nil>
local plateComponent = world:component() :: PlateComponent

--
-- Объявление сущности
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)

function CreatePlate(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Items.Plate:Clone()
	instance:AddTag(Consts.Tags.Interactable)

	local top = instance:WaitForChild("Handle")
	local placeHolderEntity, _ = PlaceHolder.Create(top)

	local entity = WorldWrapper:RegisterInstance(instance, "Plate")
	world:set(entity, plateComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance, placeHolderEntity
end

--
-- Модуль
return {
	Create = CreatePlate,
	Component = plateComponent,
}
