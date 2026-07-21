--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Dough = require(ServerScriptService.Server.Game.Ingredient.Dough)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

local Ingredient = IngredientFactory:DefineIngredient({
	IngredientName = "Flour",
	Template = ServerStorage.Ingredient.Flour,
	HandsMorphFunc = function(_)
		return Dough.Pool:Get()
	end,
})

return Ingredient
