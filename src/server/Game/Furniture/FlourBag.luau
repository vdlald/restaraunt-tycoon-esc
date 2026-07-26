--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")
return function(factory, flour)
	return factory:DefineFurniture({
		FurnitureName = "FlourBag",
		Template = ServerStorage.Furniture.FlourBag,
		IngredientPool = flour.Pool,
		IngredientComponent = flour.Component,
	})
end
