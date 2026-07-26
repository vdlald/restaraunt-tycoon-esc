--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(ingredientFactory, minceMeat)
	return ingredientFactory:DefineIngredient({
		IngredientName = "ChoppedMeat",
		Template = ServerStorage.Ingredient.ChoppedMeat,
		HandsMorphFunc = function(_)
			return minceMeat.Pool:Get()
		end,
	})
end
