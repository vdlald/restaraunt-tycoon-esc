--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

local Ingredient = IngredientFactory:DefineIngredient({
	IngredientName = "RawPie",
	Template = ServerStorage.Ingredient.RawPie,
})

return Ingredient
