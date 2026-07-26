--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local World = require(ServerScriptService.Server.World)
local SystemRegistry = require(ServerScriptService.Server.Systems.SystemRegistry)
local InteractionDispatcher = require(ServerScriptService.Server.Systems.InteractionDispatcher)
local EntityLifecycleSystem = require(ServerScriptService.Server.Systems.EntityLifecycleSystem)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local GameplayCatalog = require(ServerScriptService.Server.Game.GameplayCatalog)
local ExperienceRewards = require(ServerScriptService.Server.Application.Player.ExperienceRewards)
local MatchReplication = require(ServerScriptService.Server.Application.Match.MatchReplication)

local GameContext = {}

export type GameContext = {
	World: World.GameWorld,
	Building: typeof(BuildingSystem.new(World.new())),
	GameCycle: typeof(GameCycle.new(
		World.new(),
		BuildingSystem.new(World.new()),
		GameplayCatalog.new(World.new(), EntityLifecycleSystem.new(World.new())),
		ExperienceRewards.new(),
		MatchReplication.new()
	)),
	Catalog: typeof(GameplayCatalog.new(World.new(), EntityLifecycleSystem.new(World.new()))),
	Systems: typeof(SystemRegistry.new()),
	Interactions: InteractionDispatcher.InteractionDispatcher,
	Lifecycle: typeof(EntityLifecycleSystem.new(World.new())),
	SystemsConfigured: boolean,
	ConfigureSystems: (self: GameContext) -> (),
}

function GameContext.new(): GameContext
	local world = World.new()
	local lifecycle = EntityLifecycleSystem.new(world)
	local catalog = GameplayCatalog.new(world, lifecycle)
	local building = BuildingSystem.new(world)
	local context = {
		World = world,
		Lifecycle = lifecycle,
		Building = building,
		GameCycle = GameCycle.new(world, building, catalog, ExperienceRewards.new(), MatchReplication.new()),
		Catalog = catalog,
		Systems = SystemRegistry.new(),
		Interactions = InteractionDispatcher.new(),
		SystemsConfigured = false,
	}
	return setmetatable(context, { __index = GameContext }) :: GameContext
end

function GameContext:ConfigureSystems()
	if self.SystemsConfigured then
		return
	end
	self.SystemsConfigured = true

	local catalog = self.Catalog
	local furniture = catalog.Furniture
	local ingredients = catalog.Ingredients
	local interactions = self.Interactions
	local registry = self.Systems

	interactions:Register(self.Building)
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
	registry:Register("Intent", PlayerInteractSystem.new(self.World, interactions))

	registry:Register("Simulation", self.Building)
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
	registry:Register("Lifecycle", self.Lifecycle)
end

return GameContext
