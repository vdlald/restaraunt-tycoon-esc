--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local Plate = {}

function Plate.new(gameWorld, placeHolder)
	local world = gameWorld.Ecs
	local plateComponent = world:component() :: jecs.Id<nil>

	local function createPlate(): (jecs.Entity<nil>, Instance)
		local instance: Instance = ServerStorage.Items.Plate:Clone()
		local top = instance:WaitForChild("Handle")
		local placeHolderEntity, _ = placeHolder.Create(top)

		local entity = gameWorld:RegisterInstance(instance, "Plate")
		world:set(entity, plateComponent)
		world:set(entity, gameWorld.Components.PlayerInteractable)
		world:set(entity, gameWorld.Components.ChildEntities, { Entities = { placeHolderEntity } })

		return entity, instance, placeHolderEntity
	end

	return {
		Create = createPlate,
		Component = plateComponent,
	}
end

return Plate
