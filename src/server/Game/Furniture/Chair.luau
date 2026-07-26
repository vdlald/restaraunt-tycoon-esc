--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local Chair = {}

function Chair.new(gameWorld)
	local world = gameWorld.Ecs
	local component = world:component() :: jecs.Id<nil>

	return {
		Component = component,
		Create = function(): (jecs.Entity<nil>, Instance)
			local instance: Instance = ServerStorage.Furniture.Chair:Clone()
			local entity = gameWorld:RegisterInstance(instance, "Chair")
			world:set(entity, component)
			world:set(entity, gameWorld.Components.BuildingMovable)

			return entity, instance
		end,
	}
end

return Chair
