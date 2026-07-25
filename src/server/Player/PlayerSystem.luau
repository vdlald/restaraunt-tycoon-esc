--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local WorldWrapper = require(ServerScriptService.Server.World)

local world = WorldWrapper:GetWorld()

local PlayerSystem = Class.defineClass("PlayerSystem", AbstractSystem)

function PlayerSystem.new()
	local parent = AbstractSystem.new()
	return setmetatable(parent, PlayerSystem)
end

function PlayerSystem:Process(_: number)
	self:query(WorldWrapper:GetPlayerComponent(), WorldWrapper:GetReleaseTargetComponent()):forEach(function(entity)
		if not entity then
			return
		end
		world:remove(entity, WorldWrapper:GetReleaseTargetComponent())
		world:delete(entity)
		return entity
	end)
end

return PlayerSystem.new()
