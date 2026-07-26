--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local InteractionDispatcher = require(ServerScriptService.Server.Systems.InteractionDispatcher)

-- Объявление системы
local PlayerInteractSystem = Class.defineClass("PlayerInteractSystem", AbstractSystem)

function PlayerInteractSystem.new(worldWrapper, dispatcher: InteractionDispatcher.InteractionDispatcher)
	local parent = AbstractSystem.new(worldWrapper)
	local self = setmetatable(parent, PlayerInteractSystem)
	self.worldWrapper = worldWrapper
	self.dispatcher = dispatcher
	self.cachedQuery =
		worldWrapper.Ecs:query(worldWrapper:GetPlayerComponent(), worldWrapper:GetInteractionQueueComponent()):cached()
	return self
end

-- Процессинг
function PlayerInteractSystem:Process(_: number)
	local worldWrapper = self.worldWrapper
	local world = worldWrapper.Ecs
	local reservedTargets = {} :: { [jecs.Entity<nil>]: boolean }
	for playerId, playerComponent, queue in self.cachedQuery do
		local requests = queue.Requests
		local request = requests[1]
		if not request then
			world:remove(playerId, worldWrapper:GetInteractionQueueComponent())
			continue
		end

		-- Dispatch at most one request per target per tick so no interaction can
		-- overwrite another handler's work during this frame.
		if reservedTargets[request.Target] then
			continue
		end
		reservedTargets[request.Target] = true

		local target: jecs.Entity<nil> = request.Target
		local keyCode: Enum.KeyCode = request.KeyCode
		local playerView: Types.PlayerView = playerComponent.PlayerView

		local ok, err = pcall(self.dispatcher.Dispatch, self.dispatcher, target, playerView, keyCode)
		if not ok then
			warn(`PlayerInteractSystem.Dispatch failed: {err}`)
		end

		table.remove(requests, 1)
		if #requests == 0 then
			world:remove(playerId, worldWrapper:GetInteractionQueueComponent())
		else
			world:set(playerId, worldWrapper:GetInteractionQueueComponent(), { Requests = requests })
		end
	end
end

return PlayerInteractSystem
