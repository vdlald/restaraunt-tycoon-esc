--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local ClientSessionHandler = {}

function ClientSessionHandler.Start(application)
	Net.clientReady.listen(function(_: table, player: Player)
		application:SynchronizeClient(player)
	end)
end

return ClientSessionHandler
