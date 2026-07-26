--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local MatchHandler = {}

function MatchHandler.Start(application)
	Net.gamePhaseToggle.listen(function(_: table, player: Player)
		application:RequestPhaseToggle(player)
	end)

	Net.endMatchRequest.listen(function(_: table, player: Player)
		application:RequestEndMatch(player)
	end)
end

return MatchHandler
