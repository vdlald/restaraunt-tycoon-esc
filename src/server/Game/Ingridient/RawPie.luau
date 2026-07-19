--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local IngridientFactory = require(ServerScriptService.Server.Game.Ingridient.IngridientFactory)

local Ingridient = IngridientFactory:DefineIngridient({
	IngridientName = "RawPie",
	Template = ServerStorage.Ingridient.RawPie,
})

return Ingridient
