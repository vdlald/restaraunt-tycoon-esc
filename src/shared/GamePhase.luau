--!strict

export type GamePhase = number

local GamePhase = {
	Lobby = 0,
	Preparation = 1,
	Service = 2,
	Victory = 3,
	Defeat = 4,
}

return GamePhase
