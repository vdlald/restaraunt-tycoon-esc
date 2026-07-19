--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MeatSteak = require(ServerScriptService.Server.Game.Ingridient.RawMeatSteak)
local IngridientFurnitureFactory = require(ServerScriptService.Server.Game.Furniture.IngridientFurnitureFactory)

local Furniture = IngridientFurnitureFactory:DefineFurniture({
	FurnitureName = "MeatSteakFridge",
	Template = ServerStorage.Furniture.MeatSteakFridge,
	IngridientPool = MeatSteak.Pool,
	IngridientComponent = MeatSteak.Component,
})

return Furniture
