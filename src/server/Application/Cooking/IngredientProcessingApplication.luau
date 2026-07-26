--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Consts = require(ReplicatedStorage.Shared.Consts)

local IngredientProcessingApplication = {}
IngredientProcessingApplication.__index = IngredientProcessingApplication

export type IngredientProcessingApplication = {
	worldWrapper: any,
	gameCycle: any,
	objectPool: any,
	ingredientFactory: any,
	StartProcessing: (self: IngredientProcessingApplication, player: Player, entityId: number) -> (),
	StopProcessing: (self: IngredientProcessingApplication, player: Player) -> (),
}

function IngredientProcessingApplication.new(
	worldWrapper,
	gameCycle,
	objectPool,
	ingredientFactory
): IngredientProcessingApplication
	return setmetatable({
		worldWrapper = worldWrapper,
		gameCycle = gameCycle,
		objectPool = objectPool,
		ingredientFactory = ingredientFactory,
	}, IngredientProcessingApplication) :: any
end

function IngredientProcessingApplication:StartProcessing(player: Player, entityId: number)
	local world = self.worldWrapper:GetWorld()
	if not self.gameCycle:CanInteract() or not world:contains(entityId) then
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end
	if
		not world:has(entityId, self.ingredientFactory:GetProcessableIngredientComponent())
		or not world:has(entityId, self.worldWrapper:GetPlayerInteractableComponent())
		or self.objectPool:IsPooled(entityId)
	then
		return
	end

	local playerView = self.worldWrapper:FindPlayer(playerId)
	local instance = self.worldWrapper:FindInstance(entityId)
	if not playerView or not instance or instance.Parent == nil then
		return
	end

	local ok, distance = pcall(function()
		return playerView:GetDistance(instance)
	end)
	if not ok or distance > Consts.InteractablePlayerDistance + 4 then
		return
	end

	world:set(playerId, self.worldWrapper:GetIngredientProcessingComponent(), { Target = entityId })
end

function IngredientProcessingApplication:StopProcessing(player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if playerId then
		self.worldWrapper:GetWorld():remove(playerId, self.worldWrapper:GetIngredientProcessingComponent())
	end
end

return IngredientProcessingApplication
