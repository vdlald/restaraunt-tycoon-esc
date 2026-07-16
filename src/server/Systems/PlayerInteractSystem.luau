--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

-- Объявление системы
local PlayerInteractSystem = {}

local cachedQuery = world:query(WorldWrapper:GetPlayerComponent(), WorldWrapper:GetWantsToInteractRelation()):cached()

function PlayerInteractSystem:Process(_: number)
	for playerId, playerComponent, intent in cachedQuery do
		local target: jecs.Entity<nil> = intent.Target
		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = playerComponent.PlayerView

		local ok, err = pcall(self.processPlayerInteract, self, playerView, target, keyCode)
		if not ok then
			error("PlayerInteractSystem.process failed: ", err)
		end

		world:remove(playerId, WorldWrapper:GetWantsToInteractRelation())
	end
end

function PlayerInteractSystem:processPlayerInteract(
	playerView: Types.PlayerView,
	target: jecs.Entity<nil>,
	keyCode: Enum.KeyCode
)
	world:set(target, WorldWrapper:GetPlayerInteractComponent(), { From = playerView, KeyCode = keyCode })
end

return PlayerInteractSystem
