--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MeatSteak = require(ServerScriptService.Server.Game.Ingredient.RawMeatSteak)
local IngredientFurnitureFactory = require(ServerScriptService.Server.Game.Furniture.IngredientFurnitureFactory)

local Furniture = IngredientFurnitureFactory:DefineFurniture({
	FurnitureName = "MeatSteakFridge",
	Template = ServerStorage.Furniture.MeatSteakFridge,
	IngredientPool = MeatSteak.Pool,
	IngredientComponent = MeatSteak.Component,
})

return Furniture
