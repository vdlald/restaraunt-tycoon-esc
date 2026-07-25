--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
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
	instance:AddTag(Consts.Tags.BuildingMoveable)
	local top = instance:WaitForChild("top_part")

	local placeHolderEntity, _ = PlaceHolder.Create(top)

	local entity = WorldWrapper:RegisterInstance(instance, "DiningTable")
	world:set(entity, DiningTableComponent)
	world:set(entity, WorldWrapper:GetBuildingMovableComponent())
	world:set(entity, WorldWrapper:GetChildEntitiesComponent(), { Entities = { placeHolderEntity } })

	return entity, instance, placeHolderEntity
end

local System = Class.defineClass("DiningTableSystem", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	return setmetatable(parent, System)
end

function System:Process(_: number)
	self:query(DiningTableComponent, WorldWrapper:GetReleaseTargetComponent()):forEach(function(entity)
		if not entity then
			return
		end
		local children = world:get(entity, WorldWrapper:GetChildEntitiesComponent())
		if children then
			local hasLiveChildren = false
			for _, childEntity in children.Entities do
				if world:contains(childEntity) then
					hasLiveChildren = true
					world:set(childEntity, WorldWrapper:GetReleaseTargetComponent())
				end
			end
			if hasLiveChildren then
				return entity
			end
		end
		local instance = WorldWrapper:FindInstance(entity)
		world:remove(entity, WorldWrapper:GetReleaseTargetComponent())
		world:delete(entity)
		if instance then
			instance:Destroy()
		end
		return entity
	end)
end

--
-- Модуль
return {
	Create = CreateDiningTable,
	Component = DiningTableComponent,
	System = System.new(),
}
