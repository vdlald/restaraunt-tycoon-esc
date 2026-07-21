--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Flour = require(ServerScriptService.Server.Game.Ingredient.Flour)
local IngredientFurnitureFactory = require(ServerScriptService.Server.Game.Furniture.IngredientFurnitureFactory)

local Furniture = IngredientFurnitureFactory:DefineFurniture({
	FurnitureName = "FlourBag",
	Template = ServerStorage.Furniture.FlourBag,
	IngredientPool = Flour.Pool,
	IngredientComponent = Flour.Component,
})

return Furniture
