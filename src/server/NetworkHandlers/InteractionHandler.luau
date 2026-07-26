--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Consts = require(ReplicatedStorage.Shared.Consts)
local Net = require(ReplicatedStorage.Shared.Net)

local InteractionHandler = {}

function InteractionHandler.Start(worldWrapper, gameCycle, objectPool)
	local world = worldWrapper:GetWorld()

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

		local playerView = worldWrapper:FindPlayer(playerId)
		if not playerView then
			error("unknown userId=" .. player.UserId)
			return
		end

		if not gameCycle:CanInteract() or not world:contains(entityId) then
			return
		end

		if
			not world:has(entityId, worldWrapper:GetPlayerInteractableComponent())
			and not world:has(entityId, worldWrapper:GetBuildingMovableComponent())
		then
			warn("suspicious player interaction, not interactable view: userId=" .. player.UserId)
			return
		end

		if objectPool:IsPooled(entityId) then
			warn("suspicious player interaction, interact with pooled view: userId=" .. player.UserId)
			return
		end

		local instance = worldWrapper:FindInstance(entityId)
		if not instance or instance.Parent == nil then
			warn("suspicious player interaction, unknown or dead view: userId=" .. player.UserId)
			return
		end

		local distance = playerView:GetDistance(instance)
		if distance > Consts.InteractablePlayerDistance + 4 then
			local lock = world:get(entityId, worldWrapper:GetBuildingLockComponent())
			local isPlacing = keyCode == Enum.KeyCode.E and lock and lock.OwnerPlayerEntity == playerId
			if not isPlacing then
				warn("suspicious player interaction, too far: userId=" .. player.UserId .. ", distance=" .. distance)
				return
			end
		end

		worldWrapper:EnqueueInteraction(playerId, { Target = entityId, KeyCode = keyCode })
	end)
end

return InteractionHandler
