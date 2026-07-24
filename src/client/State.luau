--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)
local Val = require(ReplicatedStorage.Packages.Val)
local GamePhase = require(ReplicatedStorage.Shared.GamePhase)

export type ReceiptDish = {
	dishName: string,
	count: number,
	earned: number,
}

export type DayReceipt = {
	day: number,
	dishes: { ReceiptDish },
	total: number,
}

local State = {
	Coins = Val.new(0),
	IsInBuildingMode = Val.new(false),
	MovingFurnitureEntity = Val.new(0),
	GamePhase = Val.new(GamePhase.Lobby),
	GameDay = Val.new(1),
	PhaseCountdown = Val.new(0),
	GuestsRemaining = Val.new(0),
	ServiceTimeRemaining = Val.new(0),
	DayReceipt = Val.new(nil :: DayReceipt?),
}

Net.playerDataUpdate.listen(function(data)
	local coins: number = data.coins
	State.Coins:set(coins)
end)

Net.dayReceipt.listen(function(data)
	State.DayReceipt:set(data :: DayReceipt)
end)

Net.gameCycleState.listen(function(data)
	State.GamePhase:set(data.phase)
	State.GameDay:set(data.day)
	State.PhaseCountdown:set(data.countdownSeconds)
	State.GuestsRemaining:set(data.guestsRemaining)
	State.ServiceTimeRemaining:set(data.serviceSecondsRemaining)
	if data.phase == GamePhase.Lobby then
		State.DayReceipt:set(nil)
	end
	if data.phase ~= GamePhase.Preparation and State.IsInBuildingMode:get() then
		State.IsInBuildingMode:set(false)
		State.MovingFurnitureEntity:set(0)
	end
end)

Net.buildingModeState.listen(function(data)
	State.IsInBuildingMode:set(data.enabled)
	State.MovingFurnitureEntity:set(data.movingEntity)
end)

Net.buildingPlacementResult.listen(function(data)
	if data.success then
		print("[Building] placement success")
	else
		print("[Building] placement failed")
	end
end)

return State
