--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)
local Val = require(ReplicatedStorage.Packages.Val)

local State = {
	Coins = Val.new(0),
	BuildModeActive = Val.new(false),
	CarriedFurnitureEntity = Val.new(nil :: number?),
}

Net.playerDataUpdate.listen(function(data)
	-- Данные
	local coins: number = data.coins

	-- Обновление состояния
	State.Coins:set(coins)
end)

Net.buildModeState.listen(function(data)
	State.BuildModeActive:set(data.active)
	State.CarriedFurnitureEntity:set(data.carriedEntityId)
end)

return State
