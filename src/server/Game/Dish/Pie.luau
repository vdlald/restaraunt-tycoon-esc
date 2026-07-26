--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

return function(dishFactory, worldWrapper, rawPie, choppedMeat)
	local world = worldWrapper.Ecs
	local function getByComponent(component: jecs.Id<nil>, a: jecs.Entity<nil>, b: jecs.Entity<nil>): jecs.Entity<nil>?
		if world:has(a, component) then
			return a
		end
		if world:has(b, component) then
			return b
		end
		return nil
	end

	return dishFactory:DefineDish({
		DishName = "Pie",
		Template = ServerStorage.Dish.Pie,
		CombineIngredients = function(self, a: jecs.Entity<nil>, b: jecs.Entity<nil>): (jecs.Entity<nil>?, Instance?)
			local rawPieEntity = getByComponent(rawPie.Component, a, b)
			if not rawPieEntity then
				return nil
			end
			local choppedMeatEntity = getByComponent(choppedMeat.Component, a, b)
			if not choppedMeatEntity then
				return nil
			end
			worldWrapper:RequestDestroy(rawPieEntity)
			worldWrapper:RequestDestroy(choppedMeatEntity)
			return self.DishPool:Get()
		end,
	})
end
