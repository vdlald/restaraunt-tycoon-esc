--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local ClientSessionHandler = require(ServerScriptService.Server.NetworkHandlers.ClientSessionHandler)
local InteractionHandler = require(ServerScriptService.Server.NetworkHandlers.InteractionHandler)
local IngredientProcessingHandler = require(ServerScriptService.Server.NetworkHandlers.IngredientProcessingHandler)
local BuildingHandler = require(ServerScriptService.Server.NetworkHandlers.BuildingHandler)
local MatchHandler = require(ServerScriptService.Server.NetworkHandlers.MatchHandler)

local NetworkHandlers = {}

function NetworkHandlers:Start(applications)
	ClientSessionHandler.Start(applications.ClientSession)
	InteractionHandler.Start(applications.Interaction)
	IngredientProcessingHandler.Start(applications.IngredientProcessing)
	BuildingHandler.Start(applications.Building)
	MatchHandler.Start(applications.Match)
end

return NetworkHandlers
