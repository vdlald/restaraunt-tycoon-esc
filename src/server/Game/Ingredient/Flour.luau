--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(ingredientFactory, dough)
	return ingredientFactory:DefineIngredient({
		IngredientName = "Flour",
		Template = ServerStorage.Ingredient.Flour,
		HandsMorphFunc = function(_)
			return dough.Pool:Get()
		end,
	})
end
