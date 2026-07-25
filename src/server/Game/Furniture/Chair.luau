--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
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
	world:set(entity, WorldWrapper:GetBuildingMovableComponent())

	return entity, instance
end

local System = Class.defineClass("ChairSystem", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	return setmetatable(parent, System)
end

function System:Process(_: number)
	self:query(ChairComponent, WorldWrapper:GetReleaseTargetComponent()):forEach(function(entity)
		if not entity then
			return
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
	Create = CreateChair,
	Component = ChairComponent,
	System = System.new(),
}
