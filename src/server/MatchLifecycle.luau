--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Consts = require(ReplicatedStorage.Shared.Consts)

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local WorldWrapper = require(ServerScriptService.Server.World)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local PartyService = require(ServerScriptService.Server.Party.PartyService)

local world = WorldWrapper:GetWorld()

local MatchLifecycle = {}

local matchPartyId: string? = nil
local lastGamePhase = GameCycle.phase
local hasStartedMatch = false

function MatchLifecycle:Start()
	PartyService:SetLeaderChangedHandler(function(party, leaderUserId)
		local leader = Players:GetPlayerByUserId(leaderUserId)
		if leader then
			GameCycle:SetOwner(leader)
		end
		matchPartyId = party.id
	end)

	Players.PlayerAdded:Connect(function(player)
		local party, reason = PartyService:EnterMatch(player, player:GetJoinData().TeleportData)
		if not party then
			player:Kick(`Invalid match entry ({reason or PartyService.Error.InvalidInvite})`)
			return
		end

		matchPartyId = party.id
		WorldWrapper:RegisterPlayer(player)
		if party.leaderUserId == player.UserId then
			GameCycle:StartNewMatch(player)
		end

		-- The ready handshake is authoritative for initial state. This updates a
		-- client that became ready while EnterMatch was still completing.
		task.defer(function()
			if player.Parent == Players then
				GameCycle:SendState(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		BuildingSystem:CancelMove(playerId)
		world:remove(playerId, WorldWrapper:GetBuildingModeComponent())
		world:remove(playerId, WorldWrapper:GetIngredientProcessingComponent())
		world:set(playerId, WorldWrapper:GetReleaseTargetComponent())
		player:SetAttribute(Consts.Attributes.PlayerId, nil)
	end)

	DataManager:OnProfileRemoving(function(player)
		GameCycle:OnPlayerRemoving(player)
	end)
end

function MatchLifecycle:ProcessPhaseTransition()
	if matchPartyId then
		if GameCycle.phase == GameCycle.Phase.Preparation or GameCycle.phase == GameCycle.Phase.Service then
			hasStartedMatch = true
		end
		if GameCycle.phase == GameCycle.Phase.Service and lastGamePhase ~= GameCycle.Phase.Service then
			PartyService:SetMatchService(matchPartyId)
		elseif
			hasStartedMatch
			and GameCycle.phase == GameCycle.Phase.Lobby
			and lastGamePhase ~= GameCycle.Phase.Lobby
		then
			PartyService:FinishMatch(matchPartyId)
			matchPartyId = nil
		end
	end
	lastGamePhase = GameCycle.phase
end

return MatchLifecycle
