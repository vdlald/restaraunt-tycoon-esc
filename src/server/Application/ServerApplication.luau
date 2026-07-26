--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local FurnitureStore = require(ServerScriptService.Server.Game.Furniture.FurnitureStore)

local BuildingApplication = require(ServerScriptService.Server.Application.Building.BuildingApplication)
local IngredientProcessingApplication =
	require(ServerScriptService.Server.Application.Cooking.IngredientProcessingApplication)
local InteractionApplication = require(ServerScriptService.Server.Application.Interaction.InteractionApplication)
local MatchApplication = require(ServerScriptService.Server.Application.Match.MatchApplication)
local ClientSessionApplication = require(ServerScriptService.Server.Application.Player.ClientSessionApplication)
local GameContext = require(ServerScriptService.Server.GameContext)

local ServerApplication = {}

export type ServerApplication = {
	Building: BuildingApplication.BuildingApplication,
	IngredientProcessing: IngredientProcessingApplication.IngredientProcessingApplication,
	Interaction: InteractionApplication.InteractionApplication,
	Match: MatchApplication.MatchApplication,
	ClientSession: ClientSessionApplication.ClientSessionApplication,
}

function ServerApplication.new(context: GameContext.GameContext): ServerApplication
	local gameCycle = context.GameCycle
	local furnitureStore = FurnitureStore.new(context.Catalog.Furniture)
	context.Building:SetCanFinalizePurchase(function()
		return gameCycle:CanPurchaseFurniture()
	end)
	context.Building:SetPurchaseSpender(function(price: number)
		return gameCycle:TrySpendCash(price)
	end)

	return {
		Building = BuildingApplication.new(context.World, context.Building, gameCycle, furnitureStore),
		IngredientProcessing = IngredientProcessingApplication.new(context.World, gameCycle, context.Catalog),
		Interaction = InteractionApplication.new(context.World, gameCycle, context.Catalog),
		Match = MatchApplication.new(gameCycle),
		ClientSession = ClientSessionApplication.new(gameCycle, DataManager),
	}
end

return ServerApplication
