--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Consts = require(ReplicatedStorage.Shared.Consts)
local Net = require(ReplicatedStorage.Shared.Net)
local World = require(ServerScriptService.Server.World)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local FurnitureStore = require(ServerScriptService.Server.Game.Furniture.FurnitureStore)

local BuildingApplication = {}
BuildingApplication.__index = BuildingApplication

export type BuildingApplication = {
	worldWrapper: World.GameWorld,
	buildingSystem: typeof(BuildingSystem.new(World.new())),
	gameCycle: typeof(GameCycle.new()),
	furnitureStore: typeof(FurnitureStore.new({})),
	RequestModeToggle: (self: BuildingApplication, player: Player, enabled: boolean) -> (),
	CancelMove: (self: BuildingApplication, player: Player) -> (),
	MoveGhost: (self: BuildingApplication, player: Player, position: Vector3) -> (),
	RotateGhost: (self: BuildingApplication, player: Player, deltaYaw: number) -> (),
	PurchaseFurniture: (self: BuildingApplication, player: Player, furnitureId: string) -> (),
}

function BuildingApplication.new(
	worldWrapper: World.GameWorld,
	buildingSystem: typeof(BuildingSystem.new(World.new())),
	gameCycle: typeof(GameCycle.new()),
	furnitureStore: typeof(FurnitureStore.new({}))
): BuildingApplication
	return setmetatable({
		worldWrapper = worldWrapper,
		buildingSystem = buildingSystem,
		gameCycle = gameCycle,
		furnitureStore = furnitureStore,
	}, BuildingApplication) :: BuildingApplication
end

function BuildingApplication:RequestModeToggle(player: Player, enabled: boolean)
	if not self.gameCycle:CanBuild() then
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if playerId then
		self.worldWrapper:RequestBuildingMode(playerId, enabled)
	end
end

function BuildingApplication:CancelMove(player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	self.buildingSystem:CancelMove(playerId)
	Net.buildingModeState.sendTo({
		enabled = self.worldWrapper:IsBuildingModeEnabled(playerId),
		movingEntity = 0,
	}, player)
end

function BuildingApplication:MoveGhost(player: Player, position: Vector3)
	if not self.gameCycle:CanBuild() then
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if playerId then
		self.buildingSystem:SetGhostTarget(playerId, position)
	end
end

function BuildingApplication:RotateGhost(player: Player, deltaYaw: number)
	if not self.gameCycle:CanBuild() then
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	if self.worldWrapper:IsBuildingMoveActive(playerId) then
		self.buildingSystem:RequestRotation(playerId, deltaYaw)
	end
end

function BuildingApplication:PurchaseFurniture(player: Player, furnitureId: string)
	self.furnitureStore:RequestPurchase(player, furnitureId, self.buildingSystem, self.worldWrapper, self.gameCycle)
end

return BuildingApplication
