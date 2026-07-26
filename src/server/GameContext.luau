--!strict

-- Transitional composition root for server gameplay. New systems receive their
-- dependencies from here; WorldWrapper remains an adapter for legacy modules.
local ServerScriptService = game:GetService("ServerScriptService")
local World = require(ServerScriptService.Server.World)
local SystemRegistry = require(ServerScriptService.Server.Systems.SystemRegistry)
local InteractionDispatcher = require(ServerScriptService.Server.Systems.InteractionDispatcher)
local EntityLifecycleSystem = require(ServerScriptService.Server.Systems.EntityLifecycleSystem)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local GameplayCatalog = require(ServerScriptService.Server.Game.GameplayCatalog)

local GameContext = {}

export type GameContext = {
	World: World.WorldWrapper,
	Building: typeof(BuildingSystem.new(World)),
	GameCycle: typeof(GameCycle.new()),
	Catalog: typeof(GameplayCatalog.new(World, EntityLifecycleSystem.new(World))),
	Systems: typeof(SystemRegistry.new()),
	Interactions: InteractionDispatcher.InteractionDispatcher,
	Lifecycle: typeof(EntityLifecycleSystem.new(World)),
}

function GameContext.new(): GameContext
	local lifecycle = EntityLifecycleSystem.new(World)
	return {
		World = World,
		Lifecycle = lifecycle,
		Building = BuildingSystem.new(World),
		GameCycle = GameCycle.new(),
		Catalog = GameplayCatalog.new(World, lifecycle),
		Systems = SystemRegistry.new(),
		Interactions = InteractionDispatcher.new(),
	}
end

return GameContext
