--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(ingredientFactory, rawPie)
	return ingredientFactory:DefineIngredient({
		IngredientName = "Dough",
		Template = ServerStorage.Ingredient.Dough,
		HandsMorphFunc = function(_)
			return rawPie.Pool:Get()
		end,
	})
end
