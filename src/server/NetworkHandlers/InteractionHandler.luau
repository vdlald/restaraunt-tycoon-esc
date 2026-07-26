--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local InteractionHandler = {}

function InteractionHandler.Start(application)
	Net.playerInteract.listen(function(data: table, player: Player)
		application:RequestInteraction(player, data.entityId, data.keyCode)
	end)
end

return InteractionHandler
