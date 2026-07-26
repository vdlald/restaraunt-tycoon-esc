--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local InteractionHandler = {}
type PlayerInteractPacket = { entityId: number, keyCode: number }

function InteractionHandler.Start(application)
	Net.playerInteract.listen(function(data: PlayerInteractPacket, player: Player)
		application:RequestInteraction(player, data.entityId, data.keyCode)
	end)
end

return InteractionHandler
