--!strict

-- Transitional composition root for server gameplay. New systems receive their
-- dependencies from here; WorldWrapper remains an adapter for legacy modules.
local ServerScriptService = game:GetService("ServerScriptService")
local World = require(ServerScriptService.Server.World)
local SystemRegistry = require(ServerScriptService.Server.Systems.SystemRegistry)
local InteractionDispatcher = require(ServerScriptService.Server.Systems.InteractionDispatcher)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)

local GameContext = {}

export type GameContext = {
	World: World.WorldWrapper,
	Building: typeof(BuildingSystem),
	Systems: typeof(SystemRegistry.new()),
	Interactions: InteractionDispatcher.InteractionDispatcher,
}

function GameContext.new(): GameContext
	return {
		World = World,
		Building = BuildingSystem,
		Systems = SystemRegistry.new(),
		Interactions = InteractionDispatcher.new(),
	}
end

return GameContext
