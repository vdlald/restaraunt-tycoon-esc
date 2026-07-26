--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FurnitureCatalog = require(ReplicatedStorage.Shared.FurnitureCatalog)
local Net = require(ReplicatedStorage.Shared.Net)

local FurnitureStore = {}
FurnitureStore.__index = FurnitureStore

function FurnitureStore.new(factories)
	return setmetatable({ factories = factories }, FurnitureStore)
end

local function sendResult(player: Player, furnitureId: string, success: boolean, reason: number)
	Net.furniturePurchaseResult.sendTo({
		furnitureId = furnitureId,
		success = success,
		reason = reason,
	}, player)
end

function FurnitureStore:RequestPurchase(player: Player, furnitureId: string, buildingSystem, worldWrapper, gameCycle)
	local world = worldWrapper:GetWorld()
	local product = FurnitureCatalog:GetProduct(furnitureId)
	if not product then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.InvalidFurniture)
		return
	end

	if gameCycle:GetPhase() ~= gameCycle.Phase.Preparation then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.NotPreparation)
		return
	end
	if gameCycle:IsPurchaseCountdownActive() then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.CountdownActive)
		return
	end

	local playerEntity = player:GetAttribute("playerId")
	if not playerEntity then
		return
	end
	if world:has(playerEntity, worldWrapper:GetBuildingMoveStateComponent()) then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.PlacementActive)
		return
	end

	if gameCycle:GetCash() < product.Price then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.InsufficientCash)
		return
	end

	local factory = self.factories[product.Id]
	local furnitureEntity, instance = factory.Create()
	instance.Parent = workspace
	world:set(furnitureEntity, worldWrapper:GetPendingFurniturePurchaseComponent(), {
		BuyerPlayerEntity = playerEntity,
		FurnitureId = product.Id,
		Price = product.Price,
	})

	if not buildingSystem:StartPurchasePlacement(playerEntity, furnitureEntity) then
		local children = world:get(furnitureEntity, worldWrapper:GetChildEntitiesComponent())
		if children then
			for _, childEntity in children.Entities do
				worldWrapper:RequestDestroy(childEntity)
			end
		end
		worldWrapper:RequestDestroy(furnitureEntity)
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.PlacementFailed)
		return
	end

	sendResult(player, furnitureId, true, FurnitureCatalog.PurchaseResultReason.None)
end

return FurnitureStore
