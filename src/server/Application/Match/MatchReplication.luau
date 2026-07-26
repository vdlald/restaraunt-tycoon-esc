--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

export type MatchState = {
	phase: number,
	day: number,
	countdownSeconds: number,
	guestsRemaining: number,
	serviceSecondsRemaining: number,
	cash: number,
	canEndMatch: boolean,
}

export type DayReceipt = {
	day: number,
	dishes: { { dishName: string, count: number, earned: number } },
	total: number,
}

export type MatchReplication = {
	SendState: (self: MatchReplication, player: Player, state: MatchState) -> (),
	BroadcastState: (self: MatchReplication, getState: (Player) -> MatchState) -> (),
	SendReceipt: (self: MatchReplication, receipt: DayReceipt) -> (),
}

local MatchReplication = {}
MatchReplication.__index = MatchReplication

function MatchReplication.new(): MatchReplication
	return setmetatable({}, MatchReplication)
end

function MatchReplication:SendState(player: Player, state: MatchState)
	Net.gameCycleState.sendTo(state, player)
end

function MatchReplication:BroadcastState(getState: (Player) -> MatchState)
	for _, player in Players:GetPlayers() do
		self:SendState(player, getState(player))
	end
end

function MatchReplication:SendReceipt(receipt: DayReceipt)
	Net.dayReceipt.sendToAll(receipt)
end

return MatchReplication
