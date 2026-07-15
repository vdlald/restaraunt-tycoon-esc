-- Зависимости
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

-- Serve
local Net = require(ReplicatedStorage.Shared.Net)

Net.playerInteract.listen(function(data: table, player: Player)
	local entityId: number = data.entityId
	local keyCode = Enum.KeyCode:FromValue(data.keyCode)

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	local playerView: Types.PlayerView? = WorldWrapper:FindPlayer(playerId)
	if not playerView then
		error("unknown playerId=" .. playerId)
		return
	end

	local instance = WorldWrapper:FindInstance(entityId)
	if not instance then
		warn("suspicious player interaction, unknown view: userId=" .. player.UserId .. ", entityId=" .. entityId)
		return
	end

	local distance = playerView:GetDistance(instance)
	if distance > Consts.InteractablePlayerDistance + 4 then
		warn("suspicious player interaction, too far: userId=" .. player.UserId .. ", distance=" .. distance)
		return
	end

	world:set(playerId, WorldWrapper:GetWantsToInteractRelation(), { Target = entityId, KeyCode = keyCode })
end)

-- Системы
local RunService = game:GetService("RunService")
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)

RunService.Heartbeat:Connect(function(deltaTime)
	PlayerInteractSystem:Process(deltaTime)
end)
