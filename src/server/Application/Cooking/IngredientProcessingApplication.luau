--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local jecs = require(ReplicatedStorage.Packages.Jecs)
local Consts = require(ReplicatedStorage.Shared.Consts)
local World = require(ServerScriptService.Server.World)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

type GameplayCatalog = {
	IngredientFactory: typeof(IngredientFactory.new(World.new(), nil)),
	IsPooled: (self: GameplayCatalog, entityId: jecs.Entity<nil>) -> boolean,
	IsProcessableIngredient: (self: GameplayCatalog, entityId: jecs.Entity<nil>) -> boolean,
}

local IngredientProcessingApplication = {}
IngredientProcessingApplication.__index = IngredientProcessingApplication

export type IngredientProcessingApplication = {
	worldWrapper: World.GameWorld,
	gameCycle: typeof(GameCycle.new()),
	catalog: GameplayCatalog,
	StartProcessing: (self: IngredientProcessingApplication, player: Player, entityId: number) -> (),
	StopProcessing: (self: IngredientProcessingApplication, player: Player) -> (),
}

function IngredientProcessingApplication.new(
	worldWrapper: World.GameWorld,
	gameCycle: typeof(GameCycle.new()),
	catalog: GameplayCatalog
): IngredientProcessingApplication
	return setmetatable({
		worldWrapper = worldWrapper,
		gameCycle = gameCycle,
		catalog = catalog,
	}, IngredientProcessingApplication) :: IngredientProcessingApplication
end

function IngredientProcessingApplication:StartProcessing(player: Player, entityId: number)
	if not self.gameCycle:CanInteract() or not self.worldWrapper:Contains(entityId) then
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end
	if
		not self.catalog:IsProcessableIngredient(entityId)
		or not self.worldWrapper:IsPlayerInteractable(entityId)
		or self.catalog:IsPooled(entityId)
	then
		return
	end

	local playerView = self.worldWrapper:FindPlayer(playerId)
	local instance = self.worldWrapper:FindInstance(entityId)
	if not playerView or not instance or instance.Parent == nil then
		return
	end

	local distance = playerView:GetDistance(instance)
	if not distance or distance > Consts.InteractablePlayerDistance + 4 then
		return
	end

	self.worldWrapper:SetIngredientProcessing(playerId, entityId)
end

function IngredientProcessingApplication:StopProcessing(player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if playerId then
		self.worldWrapper:ClearIngredientProcessing(playerId)
	end
end

return IngredientProcessingApplication
