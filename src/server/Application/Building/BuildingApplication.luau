--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Consts = require(ReplicatedStorage.Shared.Consts)
local Net = require(ReplicatedStorage.Shared.Net)

local BuildingApplication = {}
BuildingApplication.__index = BuildingApplication

export type BuildingApplication = {
	worldWrapper: any,
	buildingSystem: any,
	gameCycle: any,
	furnitureStore: any,
	RequestModeToggle: (self: BuildingApplication, player: Player, enabled: boolean) -> (),
	CancelMove: (self: BuildingApplication, player: Player) -> (),
	MoveGhost: (self: BuildingApplication, player: Player, position: Vector3) -> (),
	RotateGhost: (self: BuildingApplication, player: Player, deltaYaw: number) -> (),
	PurchaseFurniture: (self: BuildingApplication, player: Player, furnitureId: string) -> (),
}

function BuildingApplication.new(worldWrapper, buildingSystem, gameCycle, furnitureStore): BuildingApplication
	return setmetatable({
		worldWrapper = worldWrapper,
		buildingSystem = buildingSystem,
		gameCycle = gameCycle,
		furnitureStore = furnitureStore,
	}, BuildingApplication) :: any
end

function BuildingApplication:RequestModeToggle(player: Player, enabled: boolean)
	if not self.gameCycle:CanBuild() then
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if playerId then
		local world = self.worldWrapper:GetWorld()
		world:set(playerId, self.worldWrapper:GetWantsToToggleBuildingModeComponent(), { Enabled = enabled })
	end
end

function BuildingApplication:CancelMove(player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	local world = self.worldWrapper:GetWorld()
	self.buildingSystem:CancelMove(playerId)
	Net.buildingModeState.sendTo({
		enabled = world:has(playerId, self.worldWrapper:GetBuildingModeComponent()),
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

	local world = self.worldWrapper:GetWorld()
	if world:has(playerId, self.worldWrapper:GetBuildingMoveStateComponent()) then
		self.buildingSystem:RequestRotation(playerId, deltaYaw)
	end
end

function BuildingApplication:PurchaseFurniture(player: Player, furnitureId: string)
	self.furnitureStore:RequestPurchase(player, furnitureId, self.buildingSystem, self.worldWrapper, self.gameCycle)
end

return BuildingApplication
