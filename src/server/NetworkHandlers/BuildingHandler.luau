--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Consts = require(ReplicatedStorage.Shared.Consts)
local Net = require(ReplicatedStorage.Shared.Net)

local BuildingHandler = {}

function BuildingHandler.Start(worldWrapper, buildingSystem, gameCycle, furnitureStore)
	local world = worldWrapper:GetWorld()

	Net.buildingModeToggle.listen(function(data: table, player: Player)
		if not gameCycle:CanBuild() then
			return
		end
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if playerId then
			world:set(playerId, worldWrapper:GetWantsToToggleBuildingModeComponent(), { Enabled = data.enabled })
		end
	end)

	Net.buildingModeCancelMove.listen(function(_: table, player: Player)
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		buildingSystem:CancelMove(playerId)
		Net.buildingModeState.sendTo({
			enabled = world:has(playerId, worldWrapper:GetBuildingModeComponent()),
			movingEntity = 0,
		}, player)
	end)

	Net.buildingGhostMove.listen(function(data: table, player: Player)
		if not gameCycle:CanBuild() then
			return
		end
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if playerId then
			buildingSystem:SetGhostTarget(playerId, data.position)
		end
	end)

	Net.buildingGhostRotate.listen(function(data: table, player: Player)
		if not gameCycle:CanBuild() then
			return
		end
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if playerId and world:has(playerId, worldWrapper:GetBuildingMoveStateComponent()) then
			buildingSystem:RequestRotation(playerId, data.deltaYaw)
		end
	end)

	Net.furniturePurchaseRequest.listen(function(data: table, player: Player)
		furnitureStore:RequestPurchase(player, data.furnitureId, buildingSystem, worldWrapper)
	end)
end

return BuildingHandler
