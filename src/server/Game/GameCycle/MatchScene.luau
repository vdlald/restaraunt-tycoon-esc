--!strict

export type MatchScene = {
	Clear: (self: MatchScene) -> (),
	Prepare: (self: MatchScene) -> (),
	StartService: (self: MatchScene, guestCount: number) -> (),
}

return {}
