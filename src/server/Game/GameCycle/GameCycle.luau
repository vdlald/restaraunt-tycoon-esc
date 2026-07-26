--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Net)
local SharedGamePhase = require(ReplicatedStorage.Shared.GamePhase)

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local Guest = require(ServerScriptService.Server.Game.Npc.Guest)
local GameScene = require(ServerScriptService.Server.Game.GameCycle.GameScene)
local DayEconomy = require(ServerScriptService.Server.Game.GameCycle.DayEconomy)
local MatchPhaseState = require(ServerScriptService.Server.Domain.Match.MatchPhaseState)
local MatchRules = require(ServerScriptService.Server.Domain.Match.MatchRules)

export type GamePhase = SharedGamePhase.GamePhase
export type GameCycleState = {
	phase: GamePhase,
	day: number,
	countdownSeconds: number,
	guestsRemaining: number,
	serviceSecondsRemaining: number,
	cash: number,
	canEndMatch: boolean,
}

export type ReceiptDish = DayEconomy.ReceiptDish
export type DayReceipt = DayEconomy.DayReceipt

local GameCycle = {}
GameCycle.__index = GameCycle

function GameCycle.new()
	return setmetatable({
		Phase = SharedGamePhase,
		CountdownDuration = 3,
		ResultDuration = 5,
		state = MatchPhaseState.new(),
		scene = nil :: GameScene.GameScene?,
		lastSentSecond = -1,
		economy = DayEconomy.new(1),
		owner = nil :: Player?,
		worldWrapper = nil,
	}, GameCycle)
end

function GameCycle:Configure(context)
	self.worldWrapper = context.World
	self.scene = GameScene.new(context.World, context.Building, context.Catalog)
	Guest.SetFedHandler(function(player, guestEntity, dishEntity)
		return self:OnGuestFed(player, guestEntity, dishEntity)
	end)
	Guest.SetExitedHandler(function(guestEntity)
		self:OnGuestExited(guestEntity)
	end)
end

function GameCycle:GetScene(): GameScene.GameScene
	assert(self.scene, "GameCycle must be configured before use")
	return self.scene
end

function GameCycle:GetDayProgression(day: number): (number, number)
	return MatchRules.GetDayProgression(day)
end

function GameCycle:GetState(player: Player?): GameCycleState
	return {
		phase = self.state.phase,
		day = self.state.day,
		countdownSeconds = math.max(0, math.ceil(self.state.countdownSeconds)),
		guestsRemaining = self.state.guestsRemaining,
		serviceSecondsRemaining = math.max(0, math.ceil(self.state.serviceSecondsRemaining)),
		cash = self.economy:GetCash(),
		canEndMatch = player ~= nil and player == self.owner and self.state:CanEndMatch(),
	}
end

function GameCycle:GetPhase(): GamePhase
	return self.state.phase
end

function GameCycle:GetCash(): number
	return self.economy:GetCash()
end

function GameCycle:AddCash(amount: number)
	self.economy:AddCash(amount)
	self:BroadcastState()
end

function GameCycle:TrySpendCash(amount: number): boolean
	if not self.economy:TrySpendCash(amount) then
		return false
	end
	self:BroadcastState()
	return true
end

function GameCycle:StartNewMatch(owner: Player)
	self.owner = owner
	self.economy:StartMatch(20)
end

function GameCycle:SetOwner(owner: Player?)
	self.owner = owner
	self:BroadcastState()
end

function GameCycle:CommitPendingExperience()
	for player, experience in self.economy:DrainPendingExperience() do
		if player.Parent == Players and experience > 0 then
			DataManager:MutateData("completeDayExperience", player, function(data)
				data.ExperienceEarned += experience
			end)
		end
	end
end

function GameCycle:EndMatch()
	self.economy:DiscardPendingExperience()
	self:EnterLobby()
end

function GameCycle:OnPlayerRemoving(player: Player)
	if self.owner == player then
		self.owner = nil
	end
end

function GameCycle:BroadcastState()
	for _, player in Players:GetPlayers() do
		self:SendState(player)
	end
end

function GameCycle:SendState(player: Player)
	local state = self:GetState(player)
	Net.gameCycleState.sendTo(state, player)
end

function GameCycle:SendReceipt()
	Net.dayReceipt.sendToAll(self.economy:GetReceipt())
end

function GameCycle:CanBuild(): boolean
	return self.state:CanBuild()
end

function GameCycle:CanPurchaseFurniture(): boolean
	return self.state:CanPurchaseFurniture()
end

function GameCycle:IsPurchaseCountdownActive(): boolean
	return self.state.countdownTarget ~= nil
end

function GameCycle:CanCook(): boolean
	return self.state:CanCook()
end

function GameCycle:CanFeedGuests(): boolean
	return self.state:CanFeedGuests()
end

function GameCycle:CanInteract(): boolean
	return self:CanCook()
end

function GameCycle:EnterLobby()
	self:GetScene():Clear()
	self.state:ResetLobby()
	self.economy:Clear()
	self:BroadcastState()
end

function GameCycle:EnterPreparation()
	local scene = self:GetScene()
	self.state:EnterPreparation()
	self.economy:ResetDay(self.state.day)
	if not scene.hasStarterScene then
		scene:CreateStarterScene()
		scene.hasStarterScene = true
	end
	scene:SetFurnitureAnchored(false)
	self:BroadcastState()
end

function GameCycle:EnterService()
	local scene = self:GetScene()
	scene:DisableBuildingForPlayers()
	scene:SetFurnitureAnchored(true)
	local guestCount, serviceSeconds = self:GetDayProgression(self.state.day)
	self.state:EnterService(guestCount, serviceSeconds)
	scene:SpawnGuests(guestCount)
	self:BroadcastState()
end

function GameCycle:EnterResult(phase: GamePhase)
	if phase == self.Phase.Defeat then
		self.economy:DiscardPendingExperience()
	end
	self.state:EnterResult(phase, self.ResultDuration)
	self:BroadcastState()
end

function GameCycle:RequestPhaseToggle(player: Player)
	if self.owner ~= player then
		return
	end

	if not self.state:RequestToggle(self.CountdownDuration) then
		return
	end
	self:BroadcastState()
end

function GameCycle:RequestEndMatch(player: Player)
	if player ~= self.owner then
		return
	end
	if not self.state:CanEndMatch() then
		return
	end
	self:EnterResult(self.Phase.Defeat)
end

function GameCycle:OnGuestFed(player: Player, _: number, dishEntity: number): number?
	assert(self.worldWrapper, "GameCycle must be configured before use")
	local dish = self.worldWrapper:FindInstance(dishEntity)
	if not dish then
		return nil
	end
	if not self.state:OnGuestFed() then
		return nil
	end
	local dishName = dish.Name
	local earned = MatchRules.GetDishPrice(dishName)
	self.economy:RecordDish(player, dishName, earned)
	self:BroadcastState()
	return earned
end

function GameCycle:OnGuestExited(_: number)
	if not self.state:OnGuestExited() then
		return
	end
	self:SendReceipt()
	if self.state.day >= 20 then
		self:CommitPendingExperience()
		self:EnterResult(self.Phase.Victory)
	else
		self:CommitPendingExperience()
		self.state.day += 1
		self:EnterPreparation()
	end
end

function GameCycle:Process(deltaTime: number)
	local target = self.state:Tick(deltaTime)
	if target then
		if target == self.Phase.Preparation then
			self:EnterPreparation()
		elseif target == self.Phase.Service then
			self:EnterService()
		elseif target == self.Phase.Defeat then
			self:EnterResult(self.Phase.Defeat)
		else
			self:EnterLobby()
		end
		return
	end
	local currentSecond = self.state:GetDisplaySeconds()
	if currentSecond ~= self.lastSentSecond then
		self.lastSentSecond = currentSecond
		self:BroadcastState()
	end
end

return GameCycle
