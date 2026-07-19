--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Dough = require(ServerScriptService.Server.Game.Ingridient.Dough)
local IngridientFactory = require(ServerScriptService.Server.Game.Ingridient.IngridientFactory)

local Ingridient = IngridientFactory:DefineIngridient({
	IngridientName = "Flour",
	Template = ServerStorage.Ingridient.Flour,
	HandsMorhpFunc = function(_)
		return Dough.Pool:Get()
	end,
})

return Ingridient
