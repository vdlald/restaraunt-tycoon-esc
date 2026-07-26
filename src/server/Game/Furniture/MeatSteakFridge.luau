--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(factory, meatSteak)
	return factory:DefineFurniture({
		FurnitureName = "MeatSteakFridge",
		Template = ServerStorage.Furniture.MeatSteakFridge,
		IngredientPool = meatSteak.Pool,
		IngredientComponent = meatSteak.Component,
	})
end
