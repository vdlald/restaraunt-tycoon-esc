--!strict

local MatchApplication = {}
MatchApplication.__index = MatchApplication

export type MatchApplication = {
	gameCycle: any,
	RequestPhaseToggle: (self: MatchApplication, player: Player) -> (),
	RequestEndMatch: (self: MatchApplication, player: Player) -> (),
}

function MatchApplication.new(gameCycle): MatchApplication
	return setmetatable({ gameCycle = gameCycle }, MatchApplication) :: any
end

function MatchApplication:RequestPhaseToggle(player: Player)
	self.gameCycle:RequestPhaseToggle(player)
end

function MatchApplication:RequestEndMatch(player: Player)
	self.gameCycle:RequestEndMatch(player)
end

return MatchApplication
