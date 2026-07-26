--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(ingredientFactory, choppedMeat)
	return ingredientFactory:DefineIngredient({
		IngredientName = "RawMeatSteak",
		Template = ServerStorage.Ingredient.RawMeatSteak,
		HandsMorphFunc = function(_)
			return choppedMeat.Pool:Get()
		end,
	})
end
