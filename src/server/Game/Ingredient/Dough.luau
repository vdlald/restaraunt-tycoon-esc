--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RawPie = require(ServerScriptService.Server.Game.Ingredient.RawPie)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

local Ingredient = IngredientFactory:DefineIngredient({
	IngredientName = "Dough",
	Template = ServerStorage.Ingredient.Dough,
	HandsMorphFunc = function(_)
		return RawPie.Pool:Get()
	end,
})

return Ingredient
