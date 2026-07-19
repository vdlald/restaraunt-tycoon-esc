--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ChoppedMeat = require(ServerScriptService.Server.Game.Ingridient.ChoppedMeat)
local IngridientFactory = require(ServerScriptService.Server.Game.Ingridient.IngridientFactory)

local Ingridient = IngridientFactory:DefineIngridient({
	IngridientName = "RawMeatSteak",
	Template = ServerStorage.Ingridient.RawMeatSteak,
	HandsMorhpFunc = function(_)
		return ChoppedMeat.Pool:Get()
	end,
})

return Ingridient
