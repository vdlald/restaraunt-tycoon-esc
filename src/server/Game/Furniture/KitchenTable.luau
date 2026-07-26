--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local KitchenTable = {}

function KitchenTable.new(gameWorld, placeHolder)
	local world = gameWorld.Ecs
	local kitchenTableComponent = world:component() :: jecs.Id<nil>

	local function createKitchenTable(): (jecs.Entity<nil>, Instance)
		local instance: Instance = ServerStorage.Furniture.KitchenTable:Clone()
		local top = instance:WaitForChild("top_geom")

		local placeHolderEntity, _ = placeHolder.Create(top)

		local entity = gameWorld:RegisterInstance(instance, "KitchenTable")
		world:set(entity, kitchenTableComponent)
		world:set(entity, gameWorld.Components.BuildingMovable)
		world:set(entity, gameWorld.Components.ChildEntities, { Entities = { placeHolderEntity } })

		return entity, instance, placeHolderEntity
	end

	return {
		Create = createKitchenTable,
		Component = kitchenTableComponent,
	}
end

return KitchenTable
