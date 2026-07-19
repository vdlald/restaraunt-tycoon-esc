--!strict

-- Зависимости
local ServerStorage = game:GetService("ServerStorage")

local ServerScriptService = game:GetService("ServerScriptService")
local DishFactory = require(ServerScriptService.Server.Game.Dish.DishFactory)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local RawPie = require(ServerScriptService.Server.Game.Ingridient.RawPie)
local ChoppedMeat = require(ServerScriptService.Server.Game.Ingridient.ChoppedMeat)

--
-- Вспомогательные
function GetByComponent(
    component: jecs.Id<nil>, 
    a: jecs.Entity<nil>, 
    b: jecs.Entity<nil>
): jecs.Entity<nil>?
    if world:has(a, component) then
        return a
    end
    if world:has(b, component) then
        return b
    end
    return nil
end

--
-- Объявление
local Dish = DishFactory:DefineDish({
	DishName = "Pie",
	Template = ServerStorage.Dish.Pie,
    CombineIngridients = function(self, a: jecs.Entity<nil>, b: jecs.Entity<nil>): (jecs.Entity<nil>?, Instance?)
        local rawPieEntity = GetByComponent(RawPie.Component, a, b)
        if not rawPieEntity then
            return nil
        end

        local choppedMeatEntity = GetByComponent(ChoppedMeat.Component, a, b)
        if not choppedMeatEntity then
            return nil
        end

        RawPie.Pool:Release(rawPieEntity)
        ChoppedMeat.Pool:Release(choppedMeatEntity)

        return self.DishPool:Get()
    end,
    CombineDish = function(self, dish: jecs.Entity<nil>, ingridient: jecs.Entity<nil>)
    end
})

return Dish
