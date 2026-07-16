--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

-- Объявление
function CreateFlour(): jecs.Entity<nil>
	local instance: Tool = ServerStorage.Ingridient.Flour:Clone()
	local entity = WorldWrapper:RegisterInstance(instance, "Flour")
    world:set(entity, WorldWrapper:GetPlayerInteractableComponent())
	return entity
end

return {
	Create = CreateFlour,
}
