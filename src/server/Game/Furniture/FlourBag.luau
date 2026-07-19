--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Flour = require(ServerScriptService.Server.Game.Ingridient.Flour)
local IngridientFurnitureFactory = require(ServerScriptService.Server.Game.Furniture.IngridientFurnitureFactory)

local Furniture = IngridientFurnitureFactory:DefineFurniture({
	FurnitureName = "FlourBag",
	Template = ServerStorage.Furniture.FlourBag,
	IngridientPool = Flour.Pool,
	IngridientComponent = Flour.Component,
})

return Furniture
