--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)
local Val = require(ReplicatedStorage.Packages.Val)

local State = {
	Coins = Val.new(0),
	IsInBuildingMode = Val.new(false),
	MovingFurnitureEntity = Val.new(0),
}

Net.playerDataUpdate.listen(function(data)
	local coins: number = data.coins
	State.Coins:set(coins)
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
