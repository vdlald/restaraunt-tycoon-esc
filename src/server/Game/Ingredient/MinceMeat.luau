--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(ingredientFactory)
	return ingredientFactory:DefineIngredient({
		IngredientName = "MinceMeat",
		Template = ServerStorage.Ingredient.MinceMeat,
	})
end
