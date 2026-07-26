--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)
local FurnitureStore = require(ServerScriptService.Server.Game.Furniture.FurnitureStore)

local BuildingApplication = require(ServerScriptService.Server.Application.Building.BuildingApplication)
local IngredientProcessingApplication =
	require(ServerScriptService.Server.Application.Cooking.IngredientProcessingApplication)
local InteractionApplication = require(ServerScriptService.Server.Application.Interaction.InteractionApplication)
local MatchApplication = require(ServerScriptService.Server.Application.Match.MatchApplication)
local ClientSessionApplication = require(ServerScriptService.Server.Application.Player.ClientSessionApplication)

local ServerApplication = {}

export type ServerApplication = {
	Building: BuildingApplication.BuildingApplication,
	IngredientProcessing: IngredientProcessingApplication.IngredientProcessingApplication,
	Interaction: InteractionApplication.InteractionApplication,
	Match: MatchApplication.MatchApplication,
	ClientSession: ClientSessionApplication.ClientSessionApplication,
}

function ServerApplication.new(context): ServerApplication
	return {
		Building = BuildingApplication.new(context.World, context.Building, GameCycle, FurnitureStore),
		IngredientProcessing = IngredientProcessingApplication.new(
			context.World,
			GameCycle,
			ObjectPool,
			IngredientFactory
		),
		Interaction = InteractionApplication.new(context.World, GameCycle, ObjectPool),
		Match = MatchApplication.new(GameCycle),
		ClientSession = ClientSessionApplication.new(GameCycle, DataManager),
	}
end

return ServerApplication
