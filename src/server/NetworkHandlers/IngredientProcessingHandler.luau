--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local IngredientProcessingHandler = {}
type IngredientProcessStartPacket = { entityId: number }

function IngredientProcessingHandler.Start(application)
	Net.ingredientProcessStart.listen(function(data: IngredientProcessStartPacket, player: Player)
		application:StartProcessing(player, data.entityId)
	end)

	Net.ingredientProcessStop.listen(function(_: {}, player: Player)
		application:StopProcessing(player)
	end)
end

return IngredientProcessingHandler
