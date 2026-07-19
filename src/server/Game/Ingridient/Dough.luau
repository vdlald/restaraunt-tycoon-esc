--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RawPie = require(ServerScriptService.Server.Game.Ingridient.RawPie)
local IngridientFactory = require(ServerScriptService.Server.Game.Ingridient.IngridientFactory)

local Ingridient = IngridientFactory:DefineIngridient({
	IngridientName = "Dough",
	Template = ServerStorage.Ingridient.Dough,
	HandsMorhpFunc = function(_)
		return RawPie.Pool:Get()
	end,
})

return Ingridient
