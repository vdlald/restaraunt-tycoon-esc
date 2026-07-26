--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)

local MatchApplication = {}
MatchApplication.__index = MatchApplication

export type MatchApplication = {
	gameCycle: typeof(GameCycle.new()),
	RequestPhaseToggle: (self: MatchApplication, player: Player) -> (),
	RequestEndMatch: (self: MatchApplication, player: Player) -> (),
}

function MatchApplication.new(gameCycle: typeof(GameCycle.new())): MatchApplication
	return setmetatable({ gameCycle = gameCycle }, MatchApplication) :: MatchApplication
end

function MatchApplication:RequestPhaseToggle(player: Player)
	self.gameCycle:RequestPhaseToggle(player)
end

function MatchApplication:RequestEndMatch(player: Player)
	self.gameCycle:RequestEndMatch(player)
end

return MatchApplication
