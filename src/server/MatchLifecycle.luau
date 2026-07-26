--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Consts = require(ReplicatedStorage.Shared.Consts)

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local PartyService = require(ServerScriptService.Server.Party.PartyService)

local MatchLifecycle = {}

function MatchLifecycle:Start(context)
	self.gameCycle = context.GameCycle
	self.matchPartyId = nil
	self.lastGamePhase = self.gameCycle:GetPhase()
	self.hasStartedMatch = false

	local worldWrapper = context.World
	local world = worldWrapper:GetWorld()
	local buildingSystem = context.Building
	local gameCycle = self.gameCycle
	PartyService:SetLeaderChangedHandler(function(party, leaderUserId)
		local leader = Players:GetPlayerByUserId(leaderUserId)
		if leader then
			gameCycle:SetOwner(leader)
		end
		self.matchPartyId = party.id
	end)

	Players.PlayerAdded:Connect(function(player)
		local party, reason = PartyService:EnterMatch(player, player:GetJoinData().TeleportData)
		if not party then
			player:Kick(`Invalid match entry ({reason or PartyService.Error.InvalidInvite})`)
			return
		end

		self.matchPartyId = party.id
		worldWrapper:RegisterPlayer(player)
		if party.leaderUserId == player.UserId then
			gameCycle:StartNewMatch(player)
		end

		-- The ready handshake is authoritative for initial state. This updates a
		-- client that became ready while EnterMatch was still completing.
		task.defer(function()
			if player.Parent == Players then
				gameCycle:SendState(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		buildingSystem:CancelMove(playerId)
		world:remove(playerId, worldWrapper:GetBuildingModeComponent())
		world:remove(playerId, worldWrapper:GetIngredientProcessingComponent())
		worldWrapper:RequestDestroy(playerId)
		player:SetAttribute(Consts.Attributes.PlayerId, nil)
	end)

	DataManager:OnProfileRemoving(function(player)
		gameCycle:OnPlayerRemoving(player)
	end)
end

function MatchLifecycle:ProcessPhaseTransition()
	local gameCycle = self.gameCycle
	if self.matchPartyId then
		local gamePhase = gameCycle:GetPhase()
		if gamePhase == gameCycle.Phase.Preparation or gamePhase == gameCycle.Phase.Service then
			self.hasStartedMatch = true
		end
		if gamePhase == gameCycle.Phase.Service and self.lastGamePhase ~= gameCycle.Phase.Service then
			PartyService:SetMatchService(self.matchPartyId)
		elseif
			self.hasStartedMatch
			and gamePhase == gameCycle.Phase.Lobby
			and self.lastGamePhase ~= gameCycle.Phase.Lobby
		then
			PartyService:FinishMatch(self.matchPartyId)
			self.matchPartyId = nil
		end
	end
	self.lastGamePhase = gameCycle:GetPhase()
end

return MatchLifecycle
