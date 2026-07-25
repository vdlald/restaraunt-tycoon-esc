--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local PartyService = require(script.Parent.PartyService)

local PartyServer = {}
local REQUEST_BUCKET_CAPACITY = 4
local REQUEST_BUCKET_REFILL_PER_SECOND = 1
local START_MATCH_COOLDOWN = 5

type RequestBucket = {
	tokens: number,
	updatedAt: number,
	lastStartAt: number,
}

local requestBuckets = {} :: { [Player]: RequestBucket }
local readyPlayers = {} :: { [Player]: boolean }

local function canHandleRequest(player: Player, action: number): boolean
	local now = os.clock()
	local bucket = requestBuckets[player]
	if not bucket then
		bucket = {
			tokens = REQUEST_BUCKET_CAPACITY,
			updatedAt = now,
			lastStartAt = -math.huge,
		}
		requestBuckets[player] = bucket
	end

	bucket.tokens =
		math.min(REQUEST_BUCKET_CAPACITY, bucket.tokens + (now - bucket.updatedAt) * REQUEST_BUCKET_REFILL_PER_SECOND)
	bucket.updatedAt = now
	if bucket.tokens < 1 then
		return false
	end
	if action == PartyService.Action.Start and now - bucket.lastStartAt < START_MATCH_COOLDOWN then
		return false
	end

	bucket.tokens -= 1
	if action == PartyService.Action.Start then
		bucket.lastStartAt = now
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
		requestBuckets[player] = nil
		readyPlayers[player] = nil
		PartyService:OnPlayerRemoving(player)
	end)
	for _, player in Players:GetPlayers() do
		PartyService:OnPlayerAdded(player)
	end
	Net.clientReady.listen(function(_: table, player: Player)
		if readyPlayers[player] then
			return
		end
		readyPlayers[player] = true
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
