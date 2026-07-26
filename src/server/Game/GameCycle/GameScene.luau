--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Consts = require(ReplicatedStorage.Shared.Consts)
local World = require(ServerScriptService.Server.World)

type BuildingController = {
	CancelMove: (self: BuildingController, playerEntity: number) -> (),
}

type PlaceHolderController = {
	Place: (self: PlaceHolderController, target: number, entity: number) -> (),
}

type SceneCatalog = {
	Guest: {
		CancelAll: () -> (),
		Create: () -> (number, Model),
	},
	Furniture: {
		Trashcan: { Create: () -> (number, Model) },
		FlourBag: { Create: () -> (number, Model) },
		MeatSteakFridge: { Create: () -> (number, Model) },
		KitchenTable: { Create: () -> (number, Model, number) },
	},
	Plate: { Create: () -> (number, Model, number?) },
	PlaceHolder: { System: PlaceHolderController },
}

export type GameScene = {
	instanceRoots: { Instance },
	hasStarterScene: boolean,
	gameWorld: World.GameWorld,
	buildingSystem: BuildingController,
	catalog: SceneCatalog,
	DisableBuildingForPlayers: (self: GameScene) -> (),
	SetFurnitureAnchored: (self: GameScene, anchored: boolean) -> (),
	Clear: (self: GameScene) -> (),
	Prepare: (self: GameScene) -> (),
	StartService: (self: GameScene, guestCount: number) -> (),
}

local GameScene = {}
GameScene.__index = GameScene

function GameScene.new(gameWorld: World.GameWorld, buildingSystem: BuildingController, catalog: SceneCatalog): GameScene
	return setmetatable({
		instanceRoots = {},
		hasStarterScene = false,
		gameWorld = gameWorld,
		buildingSystem = buildingSystem,
		catalog = catalog,
	}, GameScene) :: GameScene
end

local function track(self: GameScene, instance: Instance): Instance
	table.insert(self.instanceRoots, instance)
	return instance
end

function GameScene:DisableBuildingForPlayers()
	local gameWorld = self.gameWorld
	local world = gameWorld.Ecs
	for playerEntity in world:query(gameWorld.Components.WantsToToggleBuildingMode) do
		world:remove(playerEntity, gameWorld.Components.WantsToToggleBuildingMode)
	end
	for playerEntity in world:query(gameWorld.Components.InteractionQueue) do
		world:remove(playerEntity, gameWorld.Components.InteractionQueue)
	end

	for _, player in Players:GetPlayers() do
		local playerEntity = player:GetAttribute(Consts.Attributes.PlayerId)
		if playerEntity then
			self.buildingSystem:CancelMove(playerEntity)
			world:remove(playerEntity, gameWorld.Components.BuildingMode)
			world:remove(playerEntity, gameWorld.Components.BuildingGhostTarget)
		end
	end
end

function GameScene:SetFurnitureAnchored(anchored: boolean)
	local gameWorld = self.gameWorld
	local world = gameWorld.Ecs
	for furnitureEntity in world:query(gameWorld.Components.BuildingMovable) do
		local furniture = gameWorld:FindInstance(furnitureEntity)
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
	local gameWorld = self.gameWorld
	local world = gameWorld.Ecs
	self:DisableBuildingForPlayers()
	self.catalog.Guest.CancelAll()
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
	for entity, instanceData in world:query(gameWorld.Components.Instance) do
		if instanceData.Instance.Parent then
			instanceData.Instance.Parent = nil
		end
		table.insert(sceneEntities, entity)
	end
	for _, entity in sceneEntities do
		gameWorld:RequestDestroy(entity)
	end

	for _, instance in self.instanceRoots do
		if instance.Parent then
			instance.Parent = nil
		end
	end
	table.clear(self.instanceRoots)
	self.hasStarterScene = false
end

function GameScene:Prepare()
	if not self.hasStarterScene then
		self:CreateStarterScene()
		self.hasStarterScene = true
	end
	self:SetFurnitureAnchored(false)
end

function GameScene:StartService(guestCount: number)
	self:DisableBuildingForPlayers()
	self:SetFurnitureAnchored(true)
	self:SpawnGuests(guestCount)
end

function GameScene:CreateStarterScene()
	local _, trashcan = self.catalog.Furniture.Trashcan.Create()
	track(self, trashcan).Parent = workspace
	trashcan:SetPrimaryPartCFrame(CFrame.new(Vector3.new(10, 1.5, 3)))

	local _, flourBag = self.catalog.Furniture.FlourBag.Create()
	track(self, flourBag).Parent = workspace
	flourBag:SetPrimaryPartCFrame(CFrame.new(Vector3.new(4, 1.5, 3)))

	local _, fridge = self.catalog.Furniture.MeatSteakFridge.Create()
	track(self, fridge).Parent = workspace
	fridge:SetPrimaryPartCFrame(CFrame.new(Vector3.new(7, 2.5, 0)))

	local _, kitchenTable1 = self.catalog.Furniture.KitchenTable.Create()
	track(self, kitchenTable1).Parent = workspace
	kitchenTable1:SetPrimaryPartCFrame(CFrame.new(Vector3.new(-6, 1.5, -3)))

	local _, kitchenTable2 = self.catalog.Furniture.KitchenTable.Create()
	track(self, kitchenTable2).Parent = workspace
	kitchenTable2:SetPrimaryPartCFrame(CFrame.new(Vector3.new(-1, 1.5, -3)))

	local _, kitchenTable3, tablePlaceHolder = self.catalog.Furniture.KitchenTable.Create()
	track(self, kitchenTable3).Parent = workspace
	kitchenTable3:SetPrimaryPartCFrame(CFrame.new(Vector3.new(6, 1.5, -3)))

	local plateEntity1, plate1, platePlaceHolder1 = self.catalog.Plate.Create()
	track(self, plate1).Parent = workspace
	self.catalog.PlaceHolder.System:Place(tablePlaceHolder, plateEntity1)

	local plateEntity2, plate2, platePlaceHolder2 = self.catalog.Plate.Create()
	track(self, plate2).Parent = workspace
	self.catalog.PlaceHolder.System:Place(platePlaceHolder1, plateEntity2)

	local plateEntity3, plate3 = self.catalog.Plate.Create()
	track(self, plate3).Parent = workspace
	self.catalog.PlaceHolder.System:Place(platePlaceHolder2, plateEntity3)
end

function GameScene:SpawnGuests(guestCount: number)
	for _ = 1, guestCount do
		local _, guest = self.catalog.Guest.Create()
		track(self, guest).Parent = workspace
	end
end

return GameScene
