--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local BuildingHandler = {}
type BuildingModeTogglePacket = { enabled: boolean }
type BuildingGhostMovePacket = { position: Vector3 }
type BuildingGhostRotatePacket = { deltaYaw: number }
type FurniturePurchasePacket = { furnitureId: string }

function BuildingHandler.Start(application)
	Net.buildingModeToggle.listen(function(data: BuildingModeTogglePacket, player: Player)
		application:RequestModeToggle(player, data.enabled)
	end)

	Net.buildingModeCancelMove.listen(function(_: {}, player: Player)
		application:CancelMove(player)
	end)

	Net.buildingGhostMove.listen(function(data: BuildingGhostMovePacket, player: Player)
		application:MoveGhost(player, data.position)
	end)

	Net.buildingGhostRotate.listen(function(data: BuildingGhostRotatePacket, player: Player)
		application:RotateGhost(player, data.deltaYaw)
	end)

	Net.furniturePurchaseRequest.listen(function(data: FurniturePurchasePacket, player: Player)
		application:PurchaseFurniture(player, data.furnitureId)
	end)
end

return BuildingHandler
