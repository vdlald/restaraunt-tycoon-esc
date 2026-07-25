--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local RateLimiter = require(ReplicatedStorage.Shared.RateLimiter)
local PartyService = require(script.Parent.PartyService)

local PartyServer = {}
local partyRequestLimiter = RateLimiter.new({
	capacity = 4,
	refillPerSecond = 1,
})
local partyStartLimiter = RateLimiter.new({
	capacity = 1,
	refillPerSecond = 1 / 5,
})
local clientReadyLimiter = RateLimiter.new({
	capacity = 1,
	refillPerSecond = 0,
})

local function canHandleRequest(player: Player, action: number): boolean
	if not partyRequestLimiter:CanConsume(player) then
		return false
	end
	if action == PartyService.Action.Start and not partyStartLimiter:CanConsume(player) then
		return false
	end

	partyRequestLimiter:TryConsume(player)
	if action == PartyService.Action.Start then
		partyStartLimiter:TryConsume(player)
	end
	return true
end

local function handle(player: Player, action: number, callback: () -> (any, number?))
	if not canHandleRequest(player, action) then
		Net.partyActionResult.sendTo({
			action = action,
			success = false,
			reason = PartyService.Error.RateLimited,
		}, player)
		return
	end

	local party, reason = callback()
	local success = party ~= nil or reason == nil
	Net.partyActionResult.sendTo({
		action = action,
		success = success,
		reason = reason or PartyService.Error.None,
	}, player)
	if party then
		PartyService:SendState(player)
	end
end

function PartyServer:Start()
	Players.PlayerAdded:Connect(function(player)
		PartyService:OnPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		partyRequestLimiter:Reset(player)
		partyStartLimiter:Reset(player)
		clientReadyLimiter:Reset(player)
		PartyService:OnPlayerRemoving(player)
	end)
	for _, player in Players:GetPlayers() do
		PartyService:OnPlayerAdded(player)
	end
	Net.clientReady.listen(function(_: table, player: Player)
		if not clientReadyLimiter:TryConsume(player) then
			return
		end
		PartyService:SendInitialState(player)
	end)

	Net.partyCreateRequest.listen(function(_: table, player: Player)
		handle(player, PartyService.Action.Create, function()
			return PartyService:Create(player)
		end)
	end)
	Net.partyInviteRequest.listen(function(data: { targetUserId: number }, player: Player)
		handle(player, PartyService.Action.Invite, function()
			return PartyService:Invite(player, data.targetUserId)
		end)
	end)
	Net.partyInviteAcceptRequest.listen(function(data: { partyId: string }, player: Player)
		handle(player, PartyService.Action.Accept, function()
			return PartyService:AcceptInvite(player, data.partyId)
		end)
	end)
	Net.partyInviteDeclineRequest.listen(function(data: { partyId: string }, player: Player)
		handle(player, PartyService.Action.Decline, function()
			return PartyService:DeclineInvite(player, data.partyId)
		end)
	end)
	Net.partyLeaveRequest.listen(function(_: table, player: Player)
		handle(player, PartyService.Action.Leave, function()
			return PartyService:Leave(player)
		end)
	end)
	Net.partyKickRequest.listen(function(data: { targetUserId: number }, player: Player)
		handle(player, PartyService.Action.Kick, function()
			return PartyService:Kick(player, data.targetUserId)
		end)
	end)
	Net.partyStartRequest.listen(function(_: table, player: Player)
		handle(player, PartyService.Action.Start, function()
			return PartyService:StartMatch(player)
		end)
	end)
end

return PartyServer
