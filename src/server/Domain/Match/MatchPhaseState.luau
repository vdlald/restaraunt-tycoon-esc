--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamePhase = require(ReplicatedStorage.Shared.GamePhase)

export type GamePhase = GamePhase.GamePhase

export type MatchPhaseState = {
	phase: GamePhase,
	day: number,
	countdownSeconds: number,
	countdownTarget: GamePhase?,
	serviceSecondsRemaining: number,
	resultSecondsRemaining: number,
	guestsRemaining: number,
	guestsLeaving: number,
	ResetLobby: (self: MatchPhaseState) -> (),
	EnterPreparation: (self: MatchPhaseState) -> (),
	EnterService: (self: MatchPhaseState, guests: number, serviceSeconds: number) -> (),
	EnterResult: (self: MatchPhaseState, phase: GamePhase, duration: number) -> (),
	RequestToggle: (self: MatchPhaseState, duration: number) -> boolean,
	CanBuild: (self: MatchPhaseState) -> boolean,
	CanPurchaseFurniture: (self: MatchPhaseState) -> boolean,
	CanCook: (self: MatchPhaseState) -> boolean,
	CanFeedGuests: (self: MatchPhaseState) -> boolean,
	CanEndMatch: (self: MatchPhaseState) -> boolean,
	OnGuestFed: (self: MatchPhaseState) -> boolean,
	OnGuestExited: (self: MatchPhaseState) -> boolean,
	Tick: (self: MatchPhaseState, deltaTime: number) -> GamePhase?,
	GetDisplaySeconds: (self: MatchPhaseState) -> number,
}

local MatchPhaseState = {}
MatchPhaseState.__index = MatchPhaseState

function MatchPhaseState.new(): MatchPhaseState
	return setmetatable({
		phase = GamePhase.Lobby,
		day = 1,
		countdownSeconds = 0,
		countdownTarget = nil,
		serviceSecondsRemaining = 0,
		resultSecondsRemaining = 0,
		guestsRemaining = 0,
		guestsLeaving = 0,
	}, MatchPhaseState) :: any
end

function MatchPhaseState:ResetLobby()
	self.phase = GamePhase.Lobby
	self.day = 1
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self.serviceSecondsRemaining = 0
	self.resultSecondsRemaining = 0
	self.guestsRemaining = 0
	self.guestsLeaving = 0
end

function MatchPhaseState:EnterPreparation()
	self.phase = GamePhase.Preparation
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self.serviceSecondsRemaining = 0
end

function MatchPhaseState:EnterService(guests: number, serviceSeconds: number)
	self.phase = GamePhase.Service
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self.guestsRemaining = guests
	self.guestsLeaving = 0
	self.serviceSecondsRemaining = serviceSeconds
end

function MatchPhaseState:EnterResult(phase: GamePhase, duration: number)
	self.phase = phase
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self.serviceSecondsRemaining = 0
	self.resultSecondsRemaining = duration
end

function MatchPhaseState:RequestToggle(duration: number): boolean
	if self.countdownTarget then
		self.countdownSeconds = 0
		self.countdownTarget = nil
		return true
	end
	if self.phase == GamePhase.Lobby then
		self.countdownTarget = GamePhase.Preparation
	elseif self.phase == GamePhase.Preparation then
		self.countdownTarget = GamePhase.Service
	else
		return false
	end
	self.countdownSeconds = duration
	return true
end

function MatchPhaseState:CanBuild(): boolean
	return self.phase == GamePhase.Preparation
end

function MatchPhaseState:CanPurchaseFurniture(): boolean
	return self:CanBuild() and self.countdownTarget == nil
end

function MatchPhaseState:CanCook(): boolean
	return self.phase == GamePhase.Preparation or self.phase == GamePhase.Service
end

function MatchPhaseState:CanFeedGuests(): boolean
	return self.phase == GamePhase.Service
end

function MatchPhaseState:CanEndMatch(): boolean
	return self:CanCook()
end

function MatchPhaseState:OnGuestFed(): boolean
	if not self:CanFeedGuests() or self.guestsRemaining <= 0 then
		return false
	end
	self.guestsRemaining -= 1
	self.guestsLeaving += 1
	return true
end

function MatchPhaseState:OnGuestExited(): boolean
	if not self:CanFeedGuests() or self.guestsLeaving <= 0 then
		return false
	end
	self.guestsLeaving -= 1
	return self.guestsRemaining == 0 and self.guestsLeaving == 0
end

function MatchPhaseState:Tick(deltaTime: number): GamePhase?
	if self.countdownTarget then
		self.countdownSeconds -= deltaTime
		if self.countdownSeconds <= 0 then
			return self.countdownTarget
		end
	elseif self.phase == GamePhase.Service and self.guestsRemaining > 0 then
		self.serviceSecondsRemaining -= deltaTime
		if self.serviceSecondsRemaining <= 0 then
			return GamePhase.Defeat
		end
	elseif self.phase == GamePhase.Victory or self.phase == GamePhase.Defeat then
		self.resultSecondsRemaining -= deltaTime
		if self.resultSecondsRemaining <= 0 then
			return GamePhase.Lobby
		end
	end
	return nil
end

function MatchPhaseState:GetDisplaySeconds(): number
	if self.countdownTarget then
		return math.max(0, math.ceil(self.countdownSeconds))
	end
	if self.phase == GamePhase.Service then
		return math.max(0, math.ceil(self.serviceSecondsRemaining))
	end
	return math.max(0, math.ceil(self.resultSecondsRemaining))
end

return MatchPhaseState
