--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)
local Val = require(ReplicatedStorage.Packages.Val)

local State = {
	Coins = Val.new(0),
}

Net.playerDataUpdate.listen(function(data)
    -- Данные
	local coins: number = data.coins

    -- Обновление состояния
	State.Coins:set(coins)
end)

return State
