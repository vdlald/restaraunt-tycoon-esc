--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local World = require(ServerScriptService.Server.World)
local EntityLifecycleSystem = require(ServerScriptService.Server.Systems.EntityLifecycleSystem)

--
-- Объявление
local ObjectPool = Class.defineClass("ObjectPool")

export type FactoryMethod = () -> (jecs.Entity<nil>, Instance)
export type ReleaseCallback = (jecs.Entity<nil>) -> ()

export type ObjectPool = {
	new: (
		worldWrapper: World.GameWorld,
		lifecycleSystem: typeof(EntityLifecycleSystem.new(World.new())),
		factoryMethod: FactoryMethod,
		initialSize: number
	) -> ObjectPool,

	Get: (self: ObjectPool) -> (jecs.Entity<nil>, Instance),
	Release: (self: ObjectPool, jecs.Entity<nil>) -> (),
	SetReleaseCallback: (self: ObjectPool, ReleaseCallback) -> (),
	IsPooled: (self: ObjectPool, entityId: jecs.Entity<nil>) -> boolean,
}

function ObjectPool.new(
	worldWrapper: World.GameWorld,
	lifecycleSystem: typeof(EntityLifecycleSystem.new(World.new())),
	factoryMethod: FactoryMethod,
	initialSize: number
): ObjectPool
	local self = setmetatable({}, ObjectPool)

	self._worldWrapper = worldWrapper
	self._world = worldWrapper:GetWorld()
	self._lifecycleSystem = lifecycleSystem
	self._poolComponent = self._world:component()
	self._factoryMethod = factoryMethod
	self._free = {} -- свободные объекты
	self._inUse = {} -- используемые, по желанию

	for _ = 1, initialSize do
		local entity, instance = self._factoryMethod()
		instance.Parent = nil -- не в Workspace, пока не нужен
		self._world:set(entity, self._poolComponent)
		self._lifecycleSystem:RegisterCleanup(entity, function(entityId)
			if self:IsPooled(entityId) then
				self._world:remove(entityId, self._worldWrapper:GetDestroyRequestedComponent())
			else
				self:Release(entityId)
			end
			return true
		end)
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
		self._lifecycleSystem:RegisterCleanup(entity, function(entityId)
			if self:IsPooled(entityId) then
				self._world:remove(entityId, self._worldWrapper:GetDestroyRequestedComponent())
			else
				self:Release(entityId)
			end
			return true
		end)
	end
	self._inUse[obj] = true
	local instance = self._world:get(obj, self._worldWrapper:GetInstanceComponent()).Instance
	self._world:remove(obj, self._poolComponent)
	return obj, instance
end

function ObjectPool:Release(entityId: jecs.Entity<nil>)
	if self._world:has(entityId, self._poolComponent) then
		return
	end

	if self._releaseCallback then
		self._releaseCallback(entityId)
	end

	local obj = self._world:get(entityId, self._worldWrapper:GetInstanceComponent()).Instance

	-- сбросить состояние под ваши нужды (позиция, velocity, эффекты)
	obj.Parent = nil
	-- пример: если это BasePart
	if obj:IsA("BasePart") then
		obj.Velocity = Vector3.new()
		obj.RotVelocity = Vector3.new()
		obj.Anchored = false
		obj.CanCollide = true
	end

	self._world:set(entityId, self._poolComponent)
	self._inUse[entityId] = nil
	table.insert(self._free, entityId)
end

function ObjectPool:SetReleaseCallback(callback: ReleaseCallback)
	self._releaseCallback = callback
end

function ObjectPool:IsPooled(entityId: jecs.Entity<nil>): boolean
	return self._world:has(entityId, self._poolComponent)
end

return ObjectPool :: ObjectPool
