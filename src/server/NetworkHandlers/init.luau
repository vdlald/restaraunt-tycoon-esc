--!strict

local ClientSessionHandler = require(script.ClientSessionHandler)
local InteractionHandler = require(script.InteractionHandler)
local IngredientProcessingHandler = require(script.IngredientProcessingHandler)
local BuildingHandler = require(script.BuildingHandler)
local MatchHandler = require(script.MatchHandler)

local NetworkHandlers = {}

function NetworkHandlers:Start(applications)
	ClientSessionHandler.Start(applications.ClientSession)
	InteractionHandler.Start(applications.Interaction)
	IngredientProcessingHandler.Start(applications.IngredientProcessing)
	BuildingHandler.Start(applications.Building)
	MatchHandler.Start(applications.Match)
end

return NetworkHandlers
