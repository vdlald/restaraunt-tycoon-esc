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
export type ChairComponent = jecs.Id<nil>
local ChairComponent = world:component() :: ChairComponent

--
-- Объявление сущности
function CreateChair(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.Furniture.Chair:Clone()
	local entity = WorldWrapper:RegisterInstance(instance, "Chair")
	world:set(entity, ChairComponent)

	instance:AddTag(Consts.Tags.Furniture)
	instance:AddTag(Consts.Tags.Interactable)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end

--
-- Модуль
return {
	Create = CreateChair,
	Component = ChairComponent,
}
