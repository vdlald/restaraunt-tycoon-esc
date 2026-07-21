--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ChoppedMeat = require(ServerScriptService.Server.Game.Ingredient.ChoppedMeat)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

local Ingredient = IngredientFactory:DefineIngredient({
	IngredientName = "RawMeatSteak",
	Template = ServerStorage.Ingredient.RawMeatSteak,
	HandsMorphFunc = function(_)
		return ChoppedMeat.Pool:Get()
	end,
})

return Ingredient
