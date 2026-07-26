--!strict

-- Owns destruction of ECS entities. Domain systems request destruction; they do
-- not decide when children, pooled objects, and Roblox instances are cleaned up.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local ServerScriptService = game:GetService("ServerScriptService")
local WorldWrapper = require(ServerScriptService.Server.World)

local world = WorldWrapper:GetWorld()

export type Cleanup = (entityId: jecs.Entity<nil>) -> boolean

local EntityLifecycleSystem = {}
local cleanups = {} :: { [jecs.Entity<nil>]: Cleanup }

function EntityLifecycleSystem:RegisterCleanup(entityId: jecs.Entity<nil>, cleanup: Cleanup)
	cleanups[entityId] = cleanup
end

function EntityLifecycleSystem:UnregisterCleanup(entityId: jecs.Entity<nil>)
	cleanups[entityId] = nil
end

function EntityLifecycleSystem:Process(_: number)
	for entityId in world:query(WorldWrapper:GetDestroyRequestedComponent()) do
		if not world:contains(entityId) then
			continue
		end

		local children = world:get(entityId, WorldWrapper:GetChildEntitiesComponent())
		local hasLiveChildren = false
		if children then
			for _, childEntity in children.Entities do
				if world:contains(childEntity) then
					hasLiveChildren = true
					WorldWrapper:RequestDestroy(childEntity)
				end
			end
		end
		if hasLiveChildren then
			continue
		end

		local cleanup = cleanups[entityId]
		if cleanup then
			if cleanup(entityId) then
				continue
			end
			cleanups[entityId] = nil
		end

		local instance = WorldWrapper:FindInstance(entityId)
		world:remove(entityId, WorldWrapper:GetDestroyRequestedComponent())
		world:delete(entityId)
		if instance then
			instance:Destroy()
		end
	end
end

return EntityLifecycleSystem
