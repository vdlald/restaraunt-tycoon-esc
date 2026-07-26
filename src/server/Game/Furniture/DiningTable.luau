--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local DiningTable = {}

function DiningTable.new(gameWorld, placeHolder)
	local world = gameWorld.Ecs
	local diningTableComponent = world:component() :: jecs.Id<nil>

	local function createDiningTable(): (jecs.Entity<nil>, Instance)
		local instance: Instance = ServerStorage.Furniture.DiningTable:Clone()
		local top = instance:WaitForChild("top_part")

		local placeHolderEntity, _ = placeHolder.Create(top)

		local entity = gameWorld:RegisterInstance(instance, "DiningTable")
		world:set(entity, diningTableComponent)
		world:set(entity, gameWorld.Components.BuildingMovable)
		world:set(entity, gameWorld.Components.ChildEntities, { Entities = { placeHolderEntity } })

		return entity, instance, placeHolderEntity
	end

	return {
		Create = createDiningTable,
		Component = diningTableComponent,
	}
end

return DiningTable
