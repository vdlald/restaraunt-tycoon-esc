--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Consts = require(ReplicatedStorage.Shared.Consts)

local Guest = require(ServerScriptService.Server.Game.Npc.Guest)
local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local MeatSteakFridge = require(ServerScriptService.Server.Game.Furniture.MeatSteakFridge)
local Trashcan = require(ServerScriptService.Server.Game.Furniture.Trashcan)
local KitchenTable = require(ServerScriptService.Server.Game.Furniture.KitchenTable)
local Plate = require(ServerScriptService.Server.Game.Items.Plate)
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)

export type GameScene = {
	instanceRoots: { Instance },
	hasStarterScene: boolean,
	worldWrapper: any,
	buildingSystem: any,
	DisableBuildingForPlayers: (self: GameScene) -> (),
	SetFurnitureAnchored: (self: GameScene, anchored: boolean) -> (),
	Clear: (self: GameScene) -> (),
	CreateStarterScene: (self: GameScene) -> (),
	SpawnGuests: (self: GameScene, guestCount: number) -> (),
}

local GameScene = {}
GameScene.__index = GameScene

function GameScene.new(worldWrapper, buildingSystem): GameScene
	return setmetatable({
		instanceRoots = {},
		hasStarterScene = false,
		worldWrapper = worldWrapper,
		buildingSystem = buildingSystem,
	}, GameScene) :: any
end

local function track(self: GameScene, instance: Instance): Instance
	table.insert(self.instanceRoots, instance)
	return instance
end

function GameScene:DisableBuildingForPlayers()
	local world = self.worldWrapper:GetWorld()
	for playerEntity in world:query(self.worldWrapper:GetWantsToToggleBuildingModeComponent()) do
		world:remove(playerEntity, self.worldWrapper:GetWantsToToggleBuildingModeComponent())
	end
	for playerEntity in world:query(self.worldWrapper:GetInteractionQueueComponent()) do
		world:remove(playerEntity, self.worldWrapper:GetInteractionQueueComponent())
	end

	for _, player in Players:GetPlayers() do
		local playerEntity = player:GetAttribute(Consts.Attributes.PlayerId)
		if playerEntity then
			self.buildingSystem:CancelMove(playerEntity)
			world:remove(playerEntity, self.worldWrapper:GetBuildingModeComponent())
			world:remove(playerEntity, self.worldWrapper:GetBuildingGhostTargetComponent())
		end
	end
end

function GameScene:SetFurnitureAnchored(anchored: boolean)
	local world = self.worldWrapper:GetWorld()
	for furnitureEntity in world:query(self.worldWrapper:GetBuildingMovableComponent()) do
		local furniture = self.worldWrapper:FindInstance(furnitureEntity)
		if furniture then
			local parts = furniture:GetDescendants()
			table.insert(parts, furniture)
			for _, part in parts do
				if part:IsA("BasePart") then
					part.Anchored = anchored
				end
			end
		end
	end
end

function GameScene:Clear()
	local world = self.worldWrapper:GetWorld()
	self:DisableBuildingForPlayers()
	Guest.CancelAll()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			for _, tool in character:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute(Consts.Attributes.EntityId) then
					tool.Parent = nil
				end
			end
		end
		for _, tool in player.Backpack:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute(Consts.Attributes.EntityId) then
				tool.Parent = nil
			end
		end
	end

	local sceneEntities = {}
	for entity, instanceData in world:query(self.worldWrapper:GetInstanceComponent()) do
		if instanceData.Instance.Parent then
			instanceData.Instance.Parent = nil
		end
		table.insert(sceneEntities, entity)
	end
	for _, entity in sceneEntities do
		self.worldWrapper:RequestDestroy(entity)
	end

	for _, instance in self.instanceRoots do
		if instance.Parent then
			instance.Parent = nil
		end
	end
	table.clear(self.instanceRoots)
	self.hasStarterScene = false
end

function GameScene:CreateStarterScene()
	local _, trashcan = Trashcan.Create()
	track(self, trashcan).Parent = workspace
	trashcan:SetPrimaryPartCFrame(CFrame.new(Vector3.new(10, 1.5, 3)))

	local _, flourBag = FlourBag.Create()
	track(self, flourBag).Parent = workspace
	flourBag:SetPrimaryPartCFrame(CFrame.new(Vector3.new(4, 1.5, 3)))

	local _, fridge = MeatSteakFridge.Create()
	track(self, fridge).Parent = workspace
	fridge:SetPrimaryPartCFrame(CFrame.new(Vector3.new(7, 2.5, 0)))

	local _, kitchenTable1 = KitchenTable.Create()
	track(self, kitchenTable1).Parent = workspace
	kitchenTable1:SetPrimaryPartCFrame(CFrame.new(Vector3.new(-6, 1.5, -3)))

	local _, kitchenTable2 = KitchenTable.Create()
	track(self, kitchenTable2).Parent = workspace
	kitchenTable2:SetPrimaryPartCFrame(CFrame.new(Vector3.new(-1, 1.5, -3)))

	local _, kitchenTable3, tablePlaceHolder = KitchenTable.Create()
	track(self, kitchenTable3).Parent = workspace
	kitchenTable3:SetPrimaryPartCFrame(CFrame.new(Vector3.new(6, 1.5, -3)))

	local plateEntity1, plate1, platePlaceHolder1 = Plate.Create()
	track(self, plate1).Parent = workspace
	PlaceHolder.System:Place(tablePlaceHolder, plateEntity1)

	local plateEntity2, plate2, platePlaceHolder2 = Plate.Create()
	track(self, plate2).Parent = workspace
	PlaceHolder.System:Place(platePlaceHolder1, plateEntity2)

	local plateEntity3, plate3 = Plate.Create()
	track(self, plate3).Parent = workspace
	PlaceHolder.System:Place(platePlaceHolder2, plateEntity3)
end

function GameScene:SpawnGuests(guestCount: number)
	for _ = 1, guestCount do
		local _, guest = Guest.Create()
		track(self, guest).Parent = workspace
	end
end

return GameScene
