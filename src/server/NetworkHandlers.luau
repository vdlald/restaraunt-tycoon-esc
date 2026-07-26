--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local FurnitureStore = require(ServerScriptService.Server.Game.Furniture.FurnitureStore)

local ClientSessionHandler = require(ServerScriptService.Server.NetworkHandlers.ClientSessionHandler)
local InteractionHandler = require(ServerScriptService.Server.NetworkHandlers.InteractionHandler)
local IngredientProcessingHandler = require(ServerScriptService.Server.NetworkHandlers.IngredientProcessingHandler)
local BuildingHandler = require(ServerScriptService.Server.NetworkHandlers.BuildingHandler)
local MatchHandler = require(ServerScriptService.Server.NetworkHandlers.MatchHandler)

local NetworkHandlers = {}

function NetworkHandlers:Start(context)
	ClientSessionHandler.Start(GameCycle, DataManager)
	InteractionHandler.Start(context.World, GameCycle, ObjectPool)
	IngredientProcessingHandler.Start(context.World, GameCycle, ObjectPool, IngredientFactory)
	BuildingHandler.Start(context.World, context.Building, GameCycle, FurnitureStore)
	MatchHandler.Start(GameCycle)
end

return NetworkHandlers
