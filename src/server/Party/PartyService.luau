--!strict

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Net = require(ReplicatedStorage.Shared.Net)
local PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)

export type PartyPhase = number
export type Party = {
	id: string,
	leaderUserId: number,
	memberUserIds: { number },
	phase: PartyPhase,
	reservedServerAccessCode: string?,
}
export type PartyError = number

local PartyService = {
	Phase = {
		Lobby = 0,
		Teleporting = 1,
		Preparation = 2,
		Service = 3,
	},
	Error = {
		None = 0,
		NotLeader = 1,
		PartyFull = 2,
		InvalidInvite = 3,
		WrongPhase = 4,
		TargetOffline = 5,
		NotInParty = 6,
		TeleportFailed = 7,
		AlreadyInParty = 8,
		RateLimited = 9,
	},
	Action = {
		Create = 1,
		Invite = 2,
		Accept = 3,
		Decline = 4,
		Leave = 5,
		Kick = 6,
		Start = 7,
	},
	TeleportStatus = {
		Reserving = 1,
		Teleporting = 2,
		ReturningToLobby = 3,
		Failed = 4,
	},
}

local function createLocalMap()
	local values = {} :: { [string]: any }
	return {
		GetAsync = function(_: any, mapKey: string)
			return values[mapKey]
		end,
		SetAsync = function(_: any, mapKey: string, value: any)
			values[mapKey] = value
		end,
		RemoveAsync = function(_: any, mapKey: string)
			values[mapKey] = nil
		end,
		UpdateAsync = function(_: any, mapKey: string, transform: (any) -> any)
			local value = transform(values[mapKey])
			values[mapKey] = value
			return value
		end,
	}
end

local parties: any = RunService:IsStudio() and createLocalMap() or MemoryStoreService:GetHashMap("RestaurantPartyV1")
local memberships: any = RunService:IsStudio() and createLocalMap()
	or MemoryStoreService:GetHashMap("RestaurantPartyMemberV1")
local invitations: any = RunService:IsStudio() and createLocalMap()
	or MemoryStoreService:GetHashMap("RestaurantPartyInviteV1")
local incomingInvites: any = RunService:IsStudio() and createLocalMap()
	or MemoryStoreService:GetHashMap("RestaurantPartyIncomingV1")
local presence: any = RunService:IsStudio() and createLocalMap()
	or MemoryStoreService:GetHashMap("RestaurantPartyPresenceV1")
local EXPIRATION = 60 * 60 * 24 * 30
local TOPIC = "RestaurantPartyV1"
local leaderChangedHandler = function(_: Party, _: number) end
local controlledTeleports = {} :: { [number]: boolean }

local function key(userId: number): string
	return tostring(userId)
end

local function inviteKey(userId: number, partyId: string): string
	return `{userId}:{partyId}`
end

local function contains(members: { number }, userId: number): boolean
	return table.find(members, userId) ~= nil
end

local function getPartyById(partyId: string): Party?
	local ok, party = pcall(function()
		return parties:GetAsync(partyId)
	end)
	if ok and party then
		return party :: Party
	end
	return nil
end

function PartyService:GetParty(player: Player): Party?
	local ok, partyId = pcall(function()
		return memberships:GetAsync(key(player.UserId))
	end)
	if not ok or type(partyId) ~= "string" then
		return nil
	end
	return getPartyById(partyId)
end

local function publish(kind: string, payload: { [string]: any })
	pcall(function()
		MessagingService:PublishAsync(TOPIC, { kind = kind, payload = payload })
	end)
end

function PartyService:GetState(player: Player)
	local party = self:GetParty(player)
	if not party then
		return {
			inParty = false,
			partyId = "",
			phase = self.Phase.Lobby,
			members = {},
			canStart = false,
			canInvite = false,
			canKick = false,
			canLeave = false,
		}
	end

	local members = table.create(#party.memberUserIds)
	for _, userId in party.memberUserIds do
		local target = Players:GetPlayerByUserId(userId)
		table.insert(members, {
			userId = userId,
			displayName = target and target.DisplayName or tostring(userId),
			username = target and target.Name or tostring(userId),
			isLeader = userId == party.leaderUserId,
		})
	end
	local isLeader = party.leaderUserId == player.UserId
	return {
		inParty = true,
		partyId = party.id,
		phase = party.phase,
		members = members,
		canStart = isLeader and party.phase == self.Phase.Lobby,
		canInvite = isLeader and (party.phase == self.Phase.Lobby or party.phase == self.Phase.Preparation),
		canKick = isLeader and (party.phase == self.Phase.Lobby or party.phase == self.Phase.Preparation),
		canLeave = true,
	}
end

function PartyService:SendState(player: Player)
	Net.partyState.sendTo(self:GetState(player), player)
end

function PartyService:SendInvites(player: Player)
	local ids = {} :: { string }
	pcall(function()
		ids = incomingInvites:GetAsync(key(player.UserId)) or {}
	end)
	local result = {}
	for _, partyId in ids do
		local invite = nil
		pcall(function()
			invite = invitations:GetAsync(inviteKey(player.UserId, partyId))
		end)
		if invite then
			table.insert(result, invite)
		end
	end
	Net.partyInvitesState.sendTo({ invites = result }, player)
end

function PartyService:SendFriends(player: Player)
	local friends = {}
	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if ok and pages then
		local page = pages:GetCurrentPage()
		for _, friend in page do
			local online = false
			pcall(function()
				online = presence:GetAsync(key(friend.Id)) ~= nil
			end)
			table.insert(friends, {
				userId = friend.Id,
				displayName = friend.DisplayName,
				username = friend.Username,
				isOnlineInExperience = online,
				canInvite = online,
			})
		end
	end
	Net.partyFriendsState.sendTo({ friends = friends }, player)
end

function PartyService:SendInitialState(player: Player)
	self:SendState(player)
	self:SendInvites(player)
	self:SendFriends(player)
end

function PartyService:BroadcastParty(party: Party)
	for _, player in Players:GetPlayers() do
		if contains(party.memberUserIds, player.UserId) then
			self:SendState(player)
		end
	end
	publish("partyChanged", { partyId = party.id })
end

local function updateParty(partyId: string, mutation: (Party?) -> Party?): Party?
	local updated: Party? = nil
	local ok = pcall(function()
		parties:UpdateAsync(partyId, function(current)
			updated = mutation(current :: Party?)
			return updated
		end, EXPIRATION)
	end)
	if not ok then
		return nil
	end
	return updated
end

function PartyService:Create(player: Player): (Party?, PartyError?)
	if self:GetParty(player) then
		return nil, self.Error.AlreadyInParty
	end
	local party: Party = {
		id = HttpService:GenerateGUID(false),
		leaderUserId = player.UserId,
		memberUserIds = { player.UserId },
		phase = self.Phase.Lobby,
	}
	local ok = pcall(function()
		parties:SetAsync(party.id, party, EXPIRATION)
		memberships:SetAsync(key(player.UserId), party.id, EXPIRATION)
	end)
	if not ok then
		return nil, self.Error.TeleportFailed
	end
	self:BroadcastParty(party)
	return party, nil
end

function PartyService:Invite(leader: Player, targetUserId: number): (Party?, PartyError?)
	local party = self:GetParty(leader)
	if not party then
		return nil, self.Error.NotInParty
	end
	if party.leaderUserId ~= leader.UserId then
		return nil, self.Error.NotLeader
	end
	if party.phase ~= self.Phase.Lobby and party.phase ~= self.Phase.Preparation then
		return nil, self.Error.WrongPhase
	end
	if #party.memberUserIds >= 4 then
		return nil, self.Error.PartyFull
	end
	local isOnline = false
	pcall(function()
		isOnline = presence:GetAsync(key(targetUserId)) ~= nil
	end)
	if not isOnline then
		return nil, self.Error.TargetOffline
	end
	local targetPartyId = nil
	pcall(function()
		targetPartyId = memberships:GetAsync(key(targetUserId))
	end)
	if type(targetPartyId) == "string" then
		return nil, self.Error.AlreadyInParty
	end

	local invitation = { partyId = party.id, inviterUserId = leader.UserId, inviterDisplayName = leader.DisplayName }
	pcall(function()
		invitations:SetAsync(inviteKey(targetUserId, party.id), invitation, EXPIRATION)
		incomingInvites:UpdateAsync(key(targetUserId), function(current)
			local ids = current or {}
			if not table.find(ids, party.id) then
				table.insert(ids, party.id)
			end
			return ids
		end, EXPIRATION)
	end)
	publish("invite", { targetUserId = targetUserId, invitation = invitation })
	return party, nil
end

function PartyService:AcceptInvite(player: Player, partyId: string): (Party?, PartyError?)
	if self:GetParty(player) then
		return nil, self.Error.AlreadyInParty
	end
	local invite = nil
	pcall(function()
		invite = invitations:GetAsync(inviteKey(player.UserId, partyId))
	end)
	if not invite then
		return nil, self.Error.InvalidInvite
	end
	local party = updateParty(partyId, function(current)
		if not current or #current.memberUserIds >= 4 then
			return current
		end
		if current.phase ~= self.Phase.Lobby and current.phase ~= self.Phase.Preparation then
			return current
		end
		if not contains(current.memberUserIds, player.UserId) then
			table.insert(current.memberUserIds, player.UserId)
		end
		return current
	end)
	if not party or not contains(party.memberUserIds, player.UserId) then
		return nil, self.Error.PartyFull
	end
	pcall(function()
		memberships:SetAsync(key(player.UserId), party.id, EXPIRATION)
		invitations:RemoveAsync(inviteKey(player.UserId, partyId))
	end)
	self:BroadcastParty(party)
	if party.phase == self.Phase.Preparation then
		self:TeleportToMatch(player, party)
	end
	return party, nil
end

function PartyService:DeclineInvite(player: Player, partyId: string): (Party?, PartyError?)
	pcall(function()
		invitations:RemoveAsync(inviteKey(player.UserId, partyId))
		incomingInvites:UpdateAsync(key(player.UserId), function(current)
			local ids = current or {}
			local index = table.find(ids, partyId)
			if index then
				table.remove(ids, index)
			end
			return ids
		end, EXPIRATION)
	end)
	self:SendInvites(player)
	return self:GetParty(player), nil
end

function PartyService:RemoveMember(party: Party, userId: number): Party?
	local updated = updateParty(party.id, function(current)
		if not current then
			return nil
		end
		local index = table.find(current.memberUserIds, userId)
		if not index then
			return current
		end
		table.remove(current.memberUserIds, index)
		if current.leaderUserId == userId and #current.memberUserIds > 0 then
			current.leaderUserId = current.memberUserIds[1]
		end
		return current
	end)
	pcall(function()
		memberships:RemoveAsync(key(userId))
	end)
	if updated and party.leaderUserId == userId and updated.leaderUserId ~= userId then
		leaderChangedHandler(updated, updated.leaderUserId)
	end
	return updated
end

function PartyService:SetLeaderChangedHandler(handler: (Party, number) -> ())
	leaderChangedHandler = handler
end

function PartyService:ReturnToLobby(player: Player)
	if PlaceConfig.LobbyPlaceId == 0 then
		return
	end
	Net.partyTeleportStatus.sendTo({ status = self.TeleportStatus.ReturningToLobby }, player)
	controlledTeleports[player.UserId] = true
	local ok = pcall(function()
		TeleportService:TeleportAsync(PlaceConfig.LobbyPlaceId, { player })
	end)
	if not ok then
		controlledTeleports[player.UserId] = nil
	end
end

function PartyService:Leave(player: Player): (Party?, PartyError?)
	local party = self:GetParty(player)
	if not party then
		return nil, self.Error.NotInParty
	end
	local updated = self:RemoveMember(party, player.UserId)
	if updated then
		self:BroadcastParty(updated)
	end
	if party.phase == self.Phase.Preparation or party.phase == self.Phase.Service then
		self:ReturnToLobby(player)
	end
	return updated, nil
end

function PartyService:Kick(leader: Player, targetUserId: number): (Party?, PartyError?)
	local party = self:GetParty(leader)
	if not party then
		return nil, self.Error.NotInParty
	end
	if party.leaderUserId ~= leader.UserId then
		return nil, self.Error.NotLeader
	end
	if party.phase ~= self.Phase.Lobby and party.phase ~= self.Phase.Preparation then
		return nil, self.Error.WrongPhase
	end
	if targetUserId == leader.UserId or not contains(party.memberUserIds, targetUserId) then
		return nil, self.Error.NotInParty
	end
	local updated = self:RemoveMember(party, targetUserId)
	if updated then
		self:BroadcastParty(updated)
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if target and party.phase == self.Phase.Preparation then
		self:ReturnToLobby(target)
	end
	return updated, nil
end

function PartyService:TeleportToMatch(player: Player, party: Party): boolean
	if not party.reservedServerAccessCode or PlaceConfig.MatchPlaceId == 0 then
		return false
	end
	Net.partyTeleportStatus.sendTo({ status = self.TeleportStatus.Teleporting }, player)
	controlledTeleports[player.UserId] = true
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = party.reservedServerAccessCode
	options:SetTeleportData({ partyId = party.id })
	local ok = pcall(function()
		TeleportService:TeleportAsync(PlaceConfig.MatchPlaceId, { player }, options)
	end)
	if not ok then
		controlledTeleports[player.UserId] = nil
	end
	return ok
end

function PartyService:StartMatch(leader: Player): (Party?, PartyError?)
	local party = self:GetParty(leader)
	if not party then
		return nil, self.Error.NotInParty
	end
	if party.leaderUserId ~= leader.UserId then
		return nil, self.Error.NotLeader
	end
	if party.phase ~= self.Phase.Lobby then
		return nil, self.Error.WrongPhase
	end
	if PlaceConfig.MatchPlaceId == 0 then
		return nil, self.Error.TeleportFailed
	end
	Net.partyTeleportStatus.sendTo({ status = self.TeleportStatus.Reserving }, leader)
	local ok, accessCode = pcall(function()
		return TeleportService:ReserveServer(PlaceConfig.MatchPlaceId)
	end)
	if not ok or type(accessCode) ~= "string" then
		return nil, self.Error.TeleportFailed
	end
	local updated = updateParty(party.id, function(current)
		if not current or current.leaderUserId ~= leader.UserId or current.phase ~= self.Phase.Lobby then
			return current
		end
		current.phase = self.Phase.Teleporting
		current.reservedServerAccessCode = accessCode
		return current
	end)
	if not updated or updated.phase ~= self.Phase.Teleporting then
		return nil, self.Error.WrongPhase
	end
	self:BroadcastParty(updated)
	for _, player in Players:GetPlayers() do
		if contains(updated.memberUserIds, player.UserId) then
			self:TeleportToMatch(player, updated)
		end
	end
	return updated, nil
end

function PartyService:EnterMatch(player: Player, teleportData: any): (Party?, PartyError?)
	if RunService:IsStudio() and (type(teleportData) ~= "table" or type(teleportData.partyId) ~= "string") then
		local party, createError = self:Create(player)
		if not party then
			return nil, createError
		end
		party.phase = self.Phase.Preparation
		local updated = updateParty(party.id, function(current)
			if current then
				current.phase = self.Phase.Preparation
			end
			return current
		end)
		return updated, nil
	end
	if type(teleportData) ~= "table" or type(teleportData.partyId) ~= "string" then
		return nil, self.Error.InvalidInvite
	end
	local party = self:GetParty(player)
	if not party or party.id ~= teleportData.partyId then
		return nil, self.Error.NotInParty
	end
	if party.phase == self.Phase.Teleporting then
		party = updateParty(party.id, function(current)
			if current and current.phase == self.Phase.Teleporting then
				current.phase = self.Phase.Preparation
			end
			return current
		end)
	end
	if not party or (party.phase ~= self.Phase.Preparation and party.phase ~= self.Phase.Service) then
		return nil, self.Error.WrongPhase
	end
	self:BroadcastParty(party)
	return party, nil
end

function PartyService:SetMatchService(partyId: string)
	local party = updateParty(partyId, function(current)
		if current and current.phase == self.Phase.Preparation then
			current.phase = self.Phase.Service
		end
		return current
	end)
	if party then
		self:BroadcastParty(party)
	end
end

function PartyService:FinishMatch(partyId: string)
	local party = updateParty(partyId, function(current)
		if not current then
			return nil
		end
		current.phase = self.Phase.Lobby
		current.reservedServerAccessCode = nil
		return current
	end)
	if not party then
		return
	end
	self:BroadcastParty(party)
	if PlaceConfig.LobbyPlaceId == 0 then
		return
	end
	local players = {} :: { Player }
	for _, player in Players:GetPlayers() do
		if contains(party.memberUserIds, player.UserId) then
			Net.partyTeleportStatus.sendTo({ status = self.TeleportStatus.ReturningToLobby }, player)
			table.insert(players, player)
		end
	end
	if #players > 0 then
		for _, player in players do
			controlledTeleports[player.UserId] = true
		end
		local ok = pcall(function()
			TeleportService:TeleportAsync(PlaceConfig.LobbyPlaceId, players)
		end)
		if not ok then
			for _, player in players do
				controlledTeleports[player.UserId] = nil
			end
		end
	end
end

function PartyService:OnPlayerAdded(player: Player)
	pcall(function()
		presence:SetAsync(key(player.UserId), { jobId = game.JobId, placeId = game.PlaceId }, EXPIRATION)
	end)
end

function PartyService:OnPlayerRemoving(player: Player)
	if controlledTeleports[player.UserId] then
		controlledTeleports[player.UserId] = nil
		return
	end
	pcall(function()
		presence:RemoveAsync(key(player.UserId))
	end)
	local party = self:GetParty(player)
	if party then
		local updated = self:RemoveMember(party, player.UserId)
		if updated then
			self:BroadcastParty(updated)
		end
	end
end

TeleportService.TeleportInitFailed:Connect(function(player)
	controlledTeleports[player.UserId] = nil
end)

pcall(function()
	MessagingService:SubscribeAsync(TOPIC, function(message)
		local data = message.Data
		if type(data) ~= "table" then
			return
		end
		if data.kind == "invite" and type(data.payload) == "table" then
			local target = Players:GetPlayerByUserId(data.payload.targetUserId)
			if target then
				Net.partyInviteReceived.sendTo(data.payload.invitation, target)
			end
		elseif data.kind == "partyChanged" and type(data.payload) == "table" then
			for _, player in Players:GetPlayers() do
				local party = PartyService:GetParty(player)
				if party and party.id == data.payload.partyId then
					PartyService:SendState(player)
				end
			end
		end
	end)
end)

return PartyService
