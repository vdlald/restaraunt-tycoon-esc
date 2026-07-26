--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local MatchHandler = {}

function MatchHandler.Start(gameCycle)
	Net.gamePhaseToggle.listen(function(_: table, player: Player)
		gameCycle:RequestPhaseToggle(player)
	end)

	Net.endMatchRequest.listen(function(_: table, player: Player)
		gameCycle:RequestEndMatch(player)
	end)
end

return MatchHandler
