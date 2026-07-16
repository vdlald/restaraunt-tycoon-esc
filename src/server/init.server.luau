-- Зависимости
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

-- Login
local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)
	WorldWrapper:RegisterPlayer(player)
end)

-- Serve
local Net = require(ReplicatedStorage.Shared.Net)

Net.playerInteract.listen(function(data: table, player: Player)
	local entityId: number = data.entityId
	local keyCode = Enum.KeyCode:FromValue(data.keyCode)

	if not Consts.InteractableAllowedKeys[keyCode] then
		warn("suspicious player interaction: userId=" .. player.UserId .. ", keyCode=" .. keyCode)
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		error("playerId not found")
		return
	end

	local playerView: Types.PlayerView? = WorldWrapper:FindPlayer(playerId)
	if not playerView then
		error("unknown userId=" .. player.UserId)
		return
	end

	if not world:has(entityId, WorldWrapper:GetPlayerInteractableComponent()) then
		warn("suspicious player interaction, not interactable view: userId=" .. player.UserId)
		return
	end

	local instance = WorldWrapper:FindInstance(entityId)
	if not instance then
		warn("suspicious player interaction, unknown view: userId=" .. player.UserId .. ", entityId=" .. entityId)
		return
	end

	if instance.Parent == nil then
		warn("suspicious player interaction, view is dead? userId=" .. player.UserId)
		return
	end

	local distance = playerView:GetDistance(instance)
	if distance > Consts.InteractablePlayerDistance + 4 then
		warn("suspicious player interaction, too far: userId=" .. player.UserId .. ", distance=" .. distance)
		return
	end

	world:set(playerId, WorldWrapper:GetWantsToInteractComponent(), { Target = entityId, KeyCode = keyCode })
end)

-- Системы
local RunService = game:GetService("RunService")
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)

local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)

RunService.Heartbeat:Connect(function(deltaTime)
	PlayerInteractSystem:Process(deltaTime)
	FlourBag.System:Process(deltaTime)
end)

-- Инициализация мира
local flourBagEntity, flourBagInstance = FlourBag.Create()
flourBagInstance.Parent = workspace

