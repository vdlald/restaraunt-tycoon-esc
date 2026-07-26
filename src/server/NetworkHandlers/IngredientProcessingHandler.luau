--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Consts = require(ReplicatedStorage.Shared.Consts)
local Net = require(ReplicatedStorage.Shared.Net)

local IngredientProcessingHandler = {}

function IngredientProcessingHandler.Start(worldWrapper, gameCycle, objectPool, ingredientFactory)
	local world = worldWrapper:GetWorld()

	Net.ingredientProcessStart.listen(function(data: table, player: Player)
		local entityId: number = data.entityId
		if not gameCycle:CanInteract() or not world:contains(entityId) then
			return
		end

		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		if
			not world:has(entityId, ingredientFactory:GetProcessableIngredientComponent())
			or not world:has(entityId, worldWrapper:GetPlayerInteractableComponent())
			or objectPool:IsPooled(entityId)
		then
			return
		end

		local playerView = worldWrapper:FindPlayer(playerId)
		local instance = worldWrapper:FindInstance(entityId)
		if not playerView or not instance or instance.Parent == nil then
			return
		end

		local ok, distance = pcall(function()
			return playerView:GetDistance(instance)
		end)
		if not ok or distance > Consts.InteractablePlayerDistance + 4 then
			return
		end

		world:set(playerId, worldWrapper:GetIngredientProcessingComponent(), { Target = entityId })
	end)

	Net.ingredientProcessStop.listen(function(_: table, player: Player)
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if playerId then
			world:remove(playerId, worldWrapper:GetIngredientProcessingComponent())
		end
	end)
end

return IngredientProcessingHandler
