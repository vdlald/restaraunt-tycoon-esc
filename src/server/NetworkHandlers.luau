--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Consts = require(ReplicatedStorage.Shared.Consts)
local Net = require(ReplicatedStorage.Shared.Net)

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)
local WorldWrapper = require(ServerScriptService.Server.World)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local FurnitureStore = require(ServerScriptService.Server.Game.Furniture.FurnitureStore)

local world = WorldWrapper:GetWorld()

local NetworkHandlers = {}

function NetworkHandlers:Start()
	Net.clientReady.listen(function(_: table, player: Player)
		if player.Parent ~= Players then
			return
		end

		GameCycle:SendState(player)
		local playerData = DataManager:GetReadOnlyVersion(player)
		if playerData then
			Net.playerDataUpdate.sendTo({
				experience = playerData.ExperienceEarned - playerData.ExperienceSpend,
			}, player)
		end
	end)

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

		if not GameCycle:CanInteract() then
			return
		end

		if not world:contains(entityId) then
			warn("suspicious player interaction, unfound entityId=" .. entityId)
			return
		end

		if
			not world:has(entityId, WorldWrapper:GetPlayerInteractableComponent())
			and not world:has(entityId, WorldWrapper:GetBuildingMovableComponent())
		then
			warn("suspicious player interaction, not interactable view: userId=" .. player.UserId)
			return
		end

		if ObjectPool:IsPooled(entityId) then
			warn("suspicious player interaction, interact with pooled view: userId=" .. player.UserId)
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
			local isPlacing = keyCode == Enum.KeyCode.E
				and world:has(entityId, WorldWrapper:GetBuildingLockComponent())
				and world:get(entityId, WorldWrapper:GetBuildingLockComponent()).OwnerPlayerEntity == playerId

			if not isPlacing then
				warn("suspicious player interaction, too far: userId=" .. player.UserId .. ", distance=" .. distance)
				return
			end
		end

		world:set(playerId, WorldWrapper:GetWantsToInteractComponent(), { Target = entityId, KeyCode = keyCode })
	end)

	Net.ingredientProcessStart.listen(function(data: table, player: Player)
		local entityId: number = data.entityId
		if not GameCycle:CanInteract() or not world:contains(entityId) then
			return
		end

		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		if
			not world:has(entityId, IngredientFactory:GetProcessableIngredientComponent())
			or not world:has(entityId, WorldWrapper:GetPlayerInteractableComponent())
			or ObjectPool:IsPooled(entityId)
		then
			return
		end

		local playerView: Types.PlayerView? = WorldWrapper:FindPlayer(playerId)
		local instance = WorldWrapper:FindInstance(entityId)
		if not playerView or not instance or instance.Parent == nil then
			return
		end

		local ok, distance = pcall(function()
			return playerView:GetDistance(instance)
		end)
		if not ok or distance > Consts.InteractablePlayerDistance + 4 then
			return
		end

		world:set(playerId, WorldWrapper:GetIngredientProcessingComponent(), { Target = entityId })
	end)

	Net.ingredientProcessStop.listen(function(_: table, player: Player)
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		world:remove(playerId, WorldWrapper:GetIngredientProcessingComponent())
	end)

	Net.buildingModeToggle.listen(function(data: table, player: Player)
		if not GameCycle:CanBuild() then
			return
		end
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		world:set(playerId, WorldWrapper:GetWantsToToggleBuildingModeComponent(), { Enabled = data.enabled })
	end)

	Net.buildingModeCancelMove.listen(function(_: table, player: Player)
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		BuildingSystem:CancelMove(playerId)

		local enabled = world:has(playerId, WorldWrapper:GetBuildingModeComponent())
		Net.buildingModeState.sendTo({ enabled = enabled, movingEntity = 0 }, player)
	end)

	Net.buildingGhostMove.listen(function(data: table, player: Player)
		if not GameCycle:CanBuild() then
			return
		end
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		BuildingSystem:SetGhostTarget(playerId, data.position)
	end)

	Net.buildingGhostRotate.listen(function(data: table, player: Player)
		if not GameCycle:CanBuild() then
			return
		end
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		if not world:has(playerId, WorldWrapper:GetBuildingMoveStateComponent()) then
			return
		end

		BuildingSystem:RequestRotation(playerId, data.deltaYaw)
	end)

	Net.furniturePurchaseRequest.listen(function(data: table, player: Player)
		FurnitureStore:RequestPurchase(player, data.furnitureId)
	end)

	Net.gamePhaseToggle.listen(function(_: table, player: Player)
		GameCycle:RequestPhaseToggle(player)
	end)

	Net.endMatchRequest.listen(function(_: table, player: Player)
		GameCycle:RequestEndMatch(player)
	end)
end

return NetworkHandlers
