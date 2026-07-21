--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MinceMeat = require(ServerScriptService.Server.Game.Ingredient.MinceMeat)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

local Ingredient = IngredientFactory:DefineIngredient({
	IngredientName = "ChoppedMeat",
	Template = ServerStorage.Ingredient.ChoppedMeat,
	HandsMorphFunc = function(_)
		return MinceMeat.Pool:Get()
	end,
})

return Ingredient
