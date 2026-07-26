--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)
local Guest = require(ServerScriptService.Server.Game.Npc.Guest)
local Plate = require(ServerScriptService.Server.Game.Items.Plate)

local Chair = require(ServerScriptService.Server.Game.Furniture.Chair)
local DiningTable = require(ServerScriptService.Server.Game.Furniture.DiningTable)
local KitchenTable = require(ServerScriptService.Server.Game.Furniture.KitchenTable)
local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local MeatSteakFridge = require(ServerScriptService.Server.Game.Furniture.MeatSteakFridge)
local Trashcan = require(ServerScriptService.Server.Game.Furniture.Trashcan)

local Flour = require(ServerScriptService.Server.Game.Ingredient.Flour)
local Dough = require(ServerScriptService.Server.Game.Ingredient.Dough)
local RawPie = require(ServerScriptService.Server.Game.Ingredient.RawPie)
local RawMeatSteak = require(ServerScriptService.Server.Game.Ingredient.RawMeatSteak)
local ChoppedMeat = require(ServerScriptService.Server.Game.Ingredient.ChoppedMeat)
local MinceMeat = require(ServerScriptService.Server.Game.Ingredient.MinceMeat)
local Pie = require(ServerScriptService.Server.Game.Dish.Pie)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)
local DishFactory = require(ServerScriptService.Server.Game.Dish.DishFactory)
local IngredientFurnitureFactory = require(ServerScriptService.Server.Game.Furniture.IngredientFurnitureFactory)

local GameplayCatalog = {}

function GameplayCatalog.new(worldWrapper, lifecycleSystem)
	local ingredientFactory = IngredientFactory.new(worldWrapper, lifecycleSystem)
	local rawPie = RawPie(ingredientFactory)
	local dough = Dough(ingredientFactory, rawPie)
	local flour = Flour(ingredientFactory, dough)
	local minceMeat = MinceMeat(ingredientFactory)
	local choppedMeat = ChoppedMeat(ingredientFactory, minceMeat)
	local rawMeatSteak = RawMeatSteak(ingredientFactory, choppedMeat)
	local dishFactory = DishFactory.new(worldWrapper, lifecycleSystem, ingredientFactory)
	local pie = Pie(dishFactory, worldWrapper, rawPie, choppedMeat)
	local ingredientFurnitureFactory = IngredientFurnitureFactory.new(worldWrapper)
	local flourBag = FlourBag(ingredientFurnitureFactory, flour)
	local meatSteakFridge = MeatSteakFridge(ingredientFurnitureFactory, rawMeatSteak)

	local placeHolder = PlaceHolder.new(worldWrapper)
	local diningTable = DiningTable.new(worldWrapper, placeHolder)
	local kitchenTable = KitchenTable.new(worldWrapper, placeHolder)
	local plate = Plate.new(worldWrapper, placeHolder)
	local trashcan = Trashcan.new(worldWrapper, ingredientFactory, dishFactory)
	local guest = Guest.new(worldWrapper, dishFactory)

	local catalog = {
		IngredientFactory = ingredientFactory,
		DishFactory = dishFactory,
		PlaceHolder = placeHolder,
		Guest = guest,
		Plate = plate,
		Furniture = {
			Chair = Chair.new(worldWrapper),
			DiningTable = diningTable,
			KitchenTable = kitchenTable,
			FlourBag = flourBag,
			MeatSteakFridge = meatSteakFridge,
			Trashcan = trashcan,
		},
		Ingredients = {
			Flour = flour,
			Dough = dough,
			RawPie = rawPie,
			RawMeatSteak = rawMeatSteak,
			ChoppedMeat = choppedMeat,
			MinceMeat = minceMeat,
		},
		Dishes = {
			Pie = pie,
		},
	}

	function catalog:IsPooled(entityId)
		for _, ingredient in catalog.Ingredients do
			if ingredient.Pool:IsPooled(entityId) then
				return true
			end
		end
		for _, dish in catalog.Dishes do
			if dish.Pool:IsPooled(entityId) then
				return true
			end
		end
		return false
	end

	function catalog:IsProcessableIngredient(entityId)
		return worldWrapper:GetWorld():has(entityId, ingredientFactory:GetProcessableIngredientComponent())
	end

	return catalog
end

return GameplayCatalog
