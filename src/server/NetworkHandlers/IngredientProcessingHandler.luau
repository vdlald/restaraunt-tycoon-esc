--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local IngredientProcessingHandler = {}

function IngredientProcessingHandler.Start(application)
	Net.ingredientProcessStart.listen(function(data: table, player: Player)
		application:StartProcessing(player, data.entityId)
	end)

	Net.ingredientProcessStop.listen(function(_: table, player: Player)
		application:StopProcessing(player)
	end)
end

return IngredientProcessingHandler
