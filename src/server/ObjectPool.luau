-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- Компонент
local PoolComponent = world:component()

--
-- Объявление
local ObjectPool = Class.defineClass("ObjectPool")

export type FactoryMethod = () -> (jecs.Entity<nil>, Instance)

export type ObjectPool = {
	new: (factoryMethod: FactoryMethod, initialSize: number) -> ObjectPool,

	Get: (self: ObjectPool) -> (jecs.Entity<nil>, Instance),
	Release: (self: ObjectPool) -> jecs.Entity<nil>,
	IsPooled: (self: ObjectPool, entityId: jecs.Entity<nil>) -> boolean,
}

function ObjectPool.new(factoryMethod: FactoryMethod, initialSize: number): ObjectPool
	local self = setmetatable({}, ObjectPool)

	self._factoryMethod = factoryMethod
	self._free = {} -- свободные объекты
	self._inUse = {} -- используемые, по желанию

	for i = 1, initialSize do
		local entity, instance = self._factoryMethod()
		instance.Parent = nil -- не в Workspace, пока не нужен
		world:set(entity, PoolComponent)
		table.insert(self._free, entity)
	end

	return self
end

function ObjectPool:Get(): (jecs.Entity<nil>, Instance)
	local obj: jecs.Entity<nil>? = table.remove(self._free)
	if not obj then
		-- если всё занято, создаём новую копию
		local entity, instance = self._factoryMethod()
		obj = entity
		instance.Parent = nil
	end
	self._inUse[obj] = true
	local instance = world:get(obj, WorldWrapper:GetInstanceComponent()).Instance
	world:remove(obj, PoolComponent)
	return obj, instance
end

function ObjectPool:Release(entityId: jecs.Entity<nil>)
	local obj = world:get(entityId, WorldWrapper:GetInstanceComponent()).Instance

	-- сбросить состояние под ваши нужды (позиция, velocity, эффекты)
	obj.Parent = nil
	-- пример: если это BasePart
	if obj:IsA("BasePart") then
		obj.Velocity = Vector3.new()
		obj.RotVelocity = Vector3.new()
		obj.Anchored = false
		obj.CanCollide = true
	end

	world:set(entityId, PoolComponent)
	self._inUse[entityId] = nil
	table.insert(self._free, entityId)
end

function ObjectPool:IsPooled(entityId: jecs.Entity<nil>): boolean
	return world:has(entityId, PoolComponent)
end

return ObjectPool::ObjectPool
