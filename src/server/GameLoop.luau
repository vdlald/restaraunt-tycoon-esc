--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)

local GameLoop = {}

function GameLoop:Start(context, processMatchPhaseTransition: () -> ())
	local registry = context.Systems
	local interactions = context.Interactions
	local catalog = context.Catalog
	local furniture = catalog.Furniture
	local ingredients = catalog.Ingredients
	interactions:Register(context.Building)
	interactions:Register(catalog.Guest.System)
	interactions:Register(furniture.Trashcan.System)
	interactions:Register(furniture.FlourBag.System)
	interactions:Register(furniture.MeatSteakFridge.System)
	interactions:Register(ingredients.Flour.System)
	interactions:Register(ingredients.Dough.System)
	interactions:Register(ingredients.RawPie.System)
	interactions:Register(ingredients.RawMeatSteak.System)
	interactions:Register(ingredients.ChoppedMeat.System)
	interactions:Register(ingredients.MinceMeat.System)
	interactions:Register(catalog.Dishes.Pie.System)
	interactions:Register(catalog.PlaceHolder.System)
	registry:Register("Intent", PlayerInteractSystem.new(context.World, interactions))

	registry:Register("Simulation", context.Building)
	registry:Register("Simulation", catalog.Guest.System)
	registry:Register("Simulation", furniture.Trashcan.System)
	registry:Register("Simulation", furniture.FlourBag.System)
	registry:Register("Simulation", furniture.MeatSteakFridge.System)
	registry:Register("Simulation", ingredients.Flour.System)
	registry:Register("Simulation", ingredients.Dough.System)
	registry:Register("Simulation", ingredients.RawPie.System)
	registry:Register("Simulation", ingredients.RawMeatSteak.System)
	registry:Register("Simulation", ingredients.ChoppedMeat.System)
	registry:Register("Simulation", ingredients.MinceMeat.System)
	registry:Register("Simulation", catalog.Dishes.Pie.System)
	registry:Register("Simulation", catalog.PlaceHolder.System)
	registry:Register("Lifecycle", context.Lifecycle)

	-- Keep the composition root loaded by startup. Legacy systems still access
	-- its World through WorldWrapper while new systems can depend on GameContext.
	assert(context.World ~= nil, "GameContext must provide World")

	RunService.Heartbeat:Connect(function(deltaTime)
		context.GameCycle:Process(deltaTime)
		processMatchPhaseTransition()

		registry:Process("Intent", deltaTime)
		registry:Process("Simulation", deltaTime)
		registry:Process("Lifecycle", deltaTime)
	end)
end

return GameLoop
