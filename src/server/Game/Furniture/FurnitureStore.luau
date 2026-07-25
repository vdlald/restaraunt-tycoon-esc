--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FurnitureCatalog = require(ReplicatedStorage.Shared.FurnitureCatalog)
local Net = require(ReplicatedStorage.Shared.Net)
local WorldWrapper = require(ServerScriptService.Server.World)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)

local Chair = require(ServerScriptService.Server.Game.Furniture.Chair)
local DiningTable = require(ServerScriptService.Server.Game.Furniture.DiningTable)
local KitchenTable = require(ServerScriptService.Server.Game.Furniture.KitchenTable)
local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local MeatSteakFridge = require(ServerScriptService.Server.Game.Furniture.MeatSteakFridge)
local Trashcan = require(ServerScriptService.Server.Game.Furniture.Trashcan)

local world = WorldWrapper:GetWorld()

local factories = {
	Chair = Chair,
	DiningTable = DiningTable,
	KitchenTable = KitchenTable,
	FlourBag = FlourBag,
	MeatSteakFridge = MeatSteakFridge,
	Trashcan = Trashcan,
}

local FurnitureStore = {}

local function sendResult(player: Player, furnitureId: string, success: boolean, reason: number)
	Net.furniturePurchaseResult.sendTo({
		furnitureId = furnitureId,
		success = success,
		reason = reason,
	}, player)
end

function FurnitureStore:RequestPurchase(player: Player, furnitureId: string)
	local product = FurnitureCatalog:GetProduct(furnitureId)
	if not product then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.InvalidFurniture)
		return
	end

	if GameCycle.phase ~= GameCycle.Phase.Preparation then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.NotPreparation)
		return
	end
	if GameCycle.countdownTarget then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.CountdownActive)
		return
	end

	local playerEntity = player:GetAttribute("playerId")
	if not playerEntity then
		return
	end
	if world:has(playerEntity, WorldWrapper:GetBuildingMoveStateComponent()) then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.PlacementActive)
		return
	end

	if GameCycle:GetCash() < product.Price then
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.InsufficientCash)
		return
	end

	local factory = factories[product.Id]
	local furnitureEntity, instance = factory.Create()
	instance.Parent = workspace
	world:set(furnitureEntity, WorldWrapper:GetPendingFurniturePurchaseComponent(), {
		BuyerPlayerEntity = playerEntity,
		FurnitureId = product.Id,
		Price = product.Price,
	})

	if not BuildingSystem:StartPurchasePlacement(playerEntity, furnitureEntity) then
		local children = world:get(furnitureEntity, WorldWrapper:GetChildEntitiesComponent())
		if children then
			for _, childEntity in children.Entities do
				world:set(childEntity, WorldWrapper:GetReleaseTargetComponent())
			end
		end
		world:set(furnitureEntity, WorldWrapper:GetReleaseTargetComponent())
		sendResult(player, furnitureId, false, FurnitureCatalog.PurchaseResultReason.PlacementFailed)
		return
	end

	sendResult(player, furnitureId, true, FurnitureCatalog.PurchaseResultReason.None)
end

return FurnitureStore
