--!strict

-- Owns destruction of ECS entities. Domain systems request destruction; they do
-- not decide when children, pooled objects, and Roblox instances are cleaned up.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

export type Cleanup = (entityId: jecs.Entity<nil>) -> boolean

local EntityLifecycleSystem = {}
EntityLifecycleSystem.__index = EntityLifecycleSystem

function EntityLifecycleSystem.new(gameWorld)
	return setmetatable({
		gameWorld = gameWorld,
		worldWrapper = gameWorld,
		world = gameWorld.Ecs,
		cleanups = {} :: { [jecs.Entity<nil>]: Cleanup },
	}, EntityLifecycleSystem)
end

function EntityLifecycleSystem:RegisterCleanup(entityId: jecs.Entity<nil>, cleanup: Cleanup)
	self.cleanups[entityId] = cleanup
end
function EntityLifecycleSystem:UnregisterCleanup(entityId: jecs.Entity<nil>)
	self.cleanups[entityId] = nil
end

function EntityLifecycleSystem:Process(_: number)
	for entityId in self.world:query(self.gameWorld.Components.DestroyRequested) do
		if not self.world:contains(entityId) then
			continue
		end

		local children = self.world:get(entityId, self.gameWorld.Components.ChildEntities)
		local hasLiveChildren = false
		if children then
			for _, childEntity in children.Entities do
				if self.world:contains(childEntity) then
					hasLiveChildren = true
					self.worldWrapper:RequestDestroy(childEntity)
				end
			end
		end
		if hasLiveChildren then
			continue
		end

		local cleanup = self.cleanups[entityId]
		if cleanup then
			if cleanup(entityId) then
				continue
			end
			self.cleanups[entityId] = nil
		end

		local instance = self.gameWorld:FindInstance(entityId)
		self.world:remove(entityId, self.gameWorld.Components.DestroyRequested)
		self.world:delete(entityId)
		if instance then
			instance:Destroy()
		end
	end
end

return EntityLifecycleSystem
