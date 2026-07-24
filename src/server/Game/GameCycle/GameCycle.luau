--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Net)
local Consts = require(ReplicatedStorage.Shared.Consts)
local SharedGamePhase = require(ReplicatedStorage.Shared.GamePhase)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)

local Guest = require(ServerScriptService.Server.Game.Npc.Guest)
local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local MeatSteakFridge = require(ServerScriptService.Server.Game.Furniture.MeatSteakFridge)
local Trashcan = require(ServerScriptService.Server.Game.Furniture.Trashcan)
local KitchenTable = require(ServerScriptService.Server.Game.Furniture.KitchenTable)
local Plate = require(ServerScriptService.Server.Game.Items.Plate)
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)

export type GamePhase = SharedGamePhase.GamePhase
export type GameCycleState = {
	phase: GamePhase,
	day: number,
	countdownSeconds: number,
	guestsRemaining: number,
	serviceSecondsRemaining: number,
}

local GameCycle = {
	Phase = SharedGamePhase,
	CountdownDuration = 3,
	ResultDuration = 5,
}

GameCycle.phase = GameCycle.Phase.Lobby
GameCycle.day = 1
GameCycle.countdownSeconds = 0
GameCycle.serviceSecondsRemaining = 0
GameCycle.guestsRemaining = 0
GameCycle.countdownTarget = nil :: GamePhase?
GameCycle.resultSecondsRemaining = 0
GameCycle.sceneInstances = {} :: { Instance }
GameCycle.hasStarterScene = false
GameCycle.lastSentSecond = -1

function GameCycle:GetDayProgression(day: number): (number, number)
	local guests = day + 2
	return guests, 30 + 10 * guests
end

function GameCycle:GetState(): GameCycleState
	return {
		phase = self.phase,
		day = self.day,
		countdownSeconds = math.max(0, math.ceil(self.countdownSeconds)),
		guestsRemaining = self.guestsRemaining,
		serviceSecondsRemaining = math.max(0, math.ceil(self.serviceSecondsRemaining)),
	}
end

function GameCycle:BroadcastState()
	Net.gameCycleState.sendToAll(self:GetState())
end

function GameCycle:SendState(player: Player)
	Net.gameCycleState.sendTo(self:GetState(), player)
end

function GameCycle:CanBuild(): boolean
	return self.phase == self.Phase.Preparation
end

function GameCycle:CanCook(): boolean
	return self.phase == self.Phase.Preparation or self.phase == self.Phase.Service
end

function GameCycle:CanFeedGuests(): boolean
	return self.phase == self.Phase.Service
end

function GameCycle:CanInteract(): boolean
	return self:CanCook()
end

local function track(self, instance: Instance)
	table.insert(self.sceneInstances, instance)
	return instance
end

function GameCycle:DisableBuildingForPlayers()
	for playerEntity in world:query(WorldWrapper:GetWantsToToggleBuildingModeComponent()) do
		world:remove(playerEntity, WorldWrapper:GetWantsToToggleBuildingModeComponent())
	end

	for _, player in Players:GetPlayers() do
		local playerEntity = player:GetAttribute(Consts.Attributes.PlayerId)
		if playerEntity then
			BuildingSystem:CancelMove(playerEntity)
			world:remove(playerEntity, WorldWrapper:GetBuildingModeComponent())
			world:remove(playerEntity, WorldWrapper:GetBuildingGhostTargetComponent())
		end
	end
end

function GameCycle:ClearScene()
	self:DisableBuildingForPlayers()
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

	-- Все сущности игрового мира регистрируются через WorldWrapper. Снимаем с карты
	-- также ингредиенты и блюда, которые были созданы во время обслуживания.
	for _, instanceData in world:query(WorldWrapper:GetInstanceComponent()) do
		if instanceData.Instance.Parent then
			instanceData.Instance.Parent = nil
		end
	end

	for _, instance in self.sceneInstances do
		if instance.Parent then
			instance.Parent = nil
		end
	end
	table.clear(self.sceneInstances)
	self.hasStarterScene = false
	self.guestsRemaining = 0
end

function GameCycle:CreateStarterScene()
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

function GameCycle:SpawnGuests()
	local guestCount, serviceSeconds = self:GetDayProgression(self.day)
	self.guestsRemaining = guestCount
	self.serviceSecondsRemaining = serviceSeconds

	for _ = 1, guestCount do
		local _, guest = Guest.Create()
		track(self, guest).Parent = workspace
	end
end

function GameCycle:EnterLobby()
	self:ClearScene()
	self.phase = self.Phase.Lobby
	self.day = 1
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self.serviceSecondsRemaining = 0
	self.resultSecondsRemaining = 0
	self:BroadcastState()
end

function GameCycle:EnterPreparation()
	self.phase = self.Phase.Preparation
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self.serviceSecondsRemaining = 0
	if not self.hasStarterScene then
		self:CreateStarterScene()
		self.hasStarterScene = true
	end
	self:BroadcastState()
end

function GameCycle:EnterService()
	self:DisableBuildingForPlayers()
	self.phase = self.Phase.Service
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self:SpawnGuests()
	self:BroadcastState()
end

function GameCycle:EnterResult(phase: GamePhase)
	self.phase = phase
	self.countdownSeconds = 0
	self.countdownTarget = nil
	self.serviceSecondsRemaining = 0
	self.resultSecondsRemaining = self.ResultDuration
	self:BroadcastState()
end

function GameCycle:RequestPhaseToggle(_: Player)
	if self.countdownTarget then
		self.countdownSeconds = 0
		self.countdownTarget = nil
		self:BroadcastState()
		return
	end

	if self.phase == self.Phase.Lobby then
		self.countdownTarget = self.Phase.Preparation
	elseif self.phase == self.Phase.Preparation then
		self.countdownTarget = self.Phase.Service
	else
		return
	end

	self.countdownSeconds = self.CountdownDuration
	self:BroadcastState()
end

function GameCycle:OnGuestFed(_: Player, guestEntity: number): boolean
	if not self:CanFeedGuests() or self.guestsRemaining <= 0 then
		return false
	end

	local guest = WorldWrapper:FindInstance(guestEntity)
	if guest then
		guest.Parent = nil
	end
	self.guestsRemaining -= 1
	if self.guestsRemaining == 0 then
		if self.day >= 20 then
			self:EnterResult(self.Phase.Victory)
		else
			self.day += 1
			self:EnterPreparation()
		end
	else
		self:BroadcastState()
	end
	return true
end

function GameCycle:Process(deltaTime: number)
	if self.countdownTarget then
		self.countdownSeconds -= deltaTime
		if self.countdownSeconds <= 0 then
			local target = self.countdownTarget
			if target == self.Phase.Preparation then
				self:EnterPreparation()
			else
				self:EnterService()
			end
			return
		end
	elseif self.phase == self.Phase.Service then
		self.serviceSecondsRemaining -= deltaTime
		if self.serviceSecondsRemaining <= 0 then
			self:EnterResult(self.Phase.Defeat)
			return
		end
	elseif self.phase == self.Phase.Victory or self.phase == self.Phase.Defeat then
		self.resultSecondsRemaining -= deltaTime
		if self.resultSecondsRemaining <= 0 then
			self:EnterLobby()
			return
		end
	end

	local currentSecond = math.ceil(
		self.countdownTarget and self.countdownSeconds
			or (self.phase == self.Phase.Service and self.serviceSecondsRemaining or self.resultSecondsRemaining)
	)
	if currentSecond ~= self.lastSentSecond then
		self.lastSentSecond = currentSecond
		self:BroadcastState()
	end
end

Guest.SetFedHandler(function(player, guestEntity)
	return GameCycle:OnGuestFed(player, guestEntity)
end)

return GameCycle
