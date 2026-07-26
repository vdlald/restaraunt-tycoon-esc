--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local BuildingHandler = {}

function BuildingHandler.Start(application)
	Net.buildingModeToggle.listen(function(data: table, player: Player)
		application:RequestModeToggle(player, data.enabled)
	end)

	Net.buildingModeCancelMove.listen(function(_: table, player: Player)
		application:CancelMove(player)
	end)

	Net.buildingGhostMove.listen(function(data: table, player: Player)
		application:MoveGhost(player, data.position)
	end)

	Net.buildingGhostRotate.listen(function(data: table, player: Player)
		application:RotateGhost(player, data.deltaYaw)
	end)

	Net.furniturePurchaseRequest.listen(function(data: table, player: Player)
		application:PurchaseFurniture(player, data.furnitureId)
	end)
end

return BuildingHandler
