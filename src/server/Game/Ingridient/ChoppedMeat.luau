--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MinceMeat = require(ServerScriptService.Server.Game.Ingridient.MinceMeat)
local IngridientFactory = require(ServerScriptService.Server.Game.Ingridient.IngridientFactory)

local Ingridient = IngridientFactory:DefineIngridient({
	IngridientName = "ChoppedMeat",
	Template = ServerStorage.Ingridient.ChoppedMeat,
	HandsMorhpFunc = function(_)
		return MinceMeat.Pool:Get()
	end,
})

return Ingridient
