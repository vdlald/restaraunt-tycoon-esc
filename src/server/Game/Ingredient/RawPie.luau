--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(ingredientFactory)
	return ingredientFactory:DefineIngredient({
		IngredientName = "RawPie",
		Template = ServerStorage.Ingredient.RawPie,
	})
end
