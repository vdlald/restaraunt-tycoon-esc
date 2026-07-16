--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

-- Объявление системы
local PlayerInteractSystem = Class.defineClass("PlayerInteractSystem", AbstractSystem)

function PlayerInteractSystem.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, PlayerInteractSystem)
	return self
end

local cachedQuery = world:query(WorldWrapper:GetPlayerComponent(), WorldWrapper:GetWantsToInteractComponent()):cached()

-- Процессинг
function PlayerInteractSystem:Process(_: number)
	for playerId, playerComponent, intent in cachedQuery do
		local target: jecs.Entity<nil> = intent.Target
		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = playerComponent.PlayerView

		local ok, err = pcall(self.processPlayerInteract, self, playerView, target, keyCode)
		if not ok then
			error(`PlayerInteractSystem.processPlayerInteract failed: {err}`)
		end

		world:remove(playerId, WorldWrapper:GetWantsToInteractComponent())
	end
end

function PlayerInteractSystem:processPlayerInteract(
	playerView: Types.PlayerView,
	target: jecs.Entity<nil>,
	keyCode: Enum.KeyCode
)
	world:set(target, WorldWrapper:GetPlayerInteractComponent(), { PlayerView = playerView, KeyCode = keyCode })
end

return PlayerInteractSystem.new()
