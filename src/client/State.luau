--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)
local Val = require(ReplicatedStorage.Packages.Val)
local GamePhase = require(ReplicatedStorage.Shared.GamePhase)

export type ReceiptDish = {
	dishName: string,
	count: number,
	earned: number,
}

export type DayReceipt = {
	day: number,
	dishes: { ReceiptDish },
	total: number,
}

export type IngredientProcessState = {
	progress: number,
	participantCount: number,
}

export type FurniturePurchaseResult = {
	furnitureId: string,
	success: boolean,
	reason: number,
}

export type PartyMember = {
	userId: number,
	displayName: string,
	username: string,
	isLeader: boolean,
}

export type PartyState = {
	inParty: boolean,
	partyId: string,
	phase: number,
	members: { PartyMember },
	canStart: boolean,
	canInvite: boolean,
	canKick: boolean,
	canLeave: boolean,
}

export type PartyInvite = {
	partyId: string,
	inviterUserId: number,
	inviterDisplayName: string,
}

local State = {
	GameCash = Val.new(0),
	Experience = Val.new(0),
	IsInBuildingMode = Val.new(false),
	MovingFurnitureEntity = Val.new(0),
	GamePhase = Val.new(GamePhase.Lobby),
	CanEndMatch = Val.new(false),
	GameDay = Val.new(1),
	PhaseCountdown = Val.new(0),
	GuestsRemaining = Val.new(0),
	ServiceTimeRemaining = Val.new(0),
	DayReceipt = Val.new(nil :: DayReceipt?),
	IsFurnitureStoreOpen = Val.new(false),
	FurniturePurchaseResult = Val.new(nil :: FurniturePurchaseResult?),
	IngredientProcessStates = Val.new({} :: { [number]: IngredientProcessState }),
	Party = Val.new({
		inParty = false,
		partyId = "",
		phase = 0,
		members = {},
		canStart = false,
		canInvite = false,
		canKick = false,
		canLeave = false,
	} :: PartyState),
	PartyFriends = Val.new({} :: { any }),
	PartyInvites = Val.new({} :: { PartyInvite }),
	PartyMessage = Val.new(""),
	PartyStartPending = Val.new(false),
}

Net.playerDataUpdate.listen(function(data)
	local experience: number = data.experience
	State.Experience:set(experience)
end)

Net.dayReceipt.listen(function(data)
	State.DayReceipt:set(data :: DayReceipt)
end)

Net.gameCycleState.listen(function(data)
	State.GamePhase:set(data.phase)
	State.CanEndMatch:set(data.canEndMatch)
	State.GameDay:set(data.day)
	State.PhaseCountdown:set(data.countdownSeconds)
	State.GuestsRemaining:set(data.guestsRemaining)
	State.ServiceTimeRemaining:set(data.serviceSecondsRemaining)
	State.GameCash:set(data.cash)
	if data.phase == GamePhase.Lobby then
		State.DayReceipt:set(nil)
	end
	if data.phase ~= GamePhase.Preparation and State.IsInBuildingMode:get() then
		State.IsInBuildingMode:set(false)
		State.MovingFurnitureEntity:set(0)
	end
	if data.phase ~= GamePhase.Preparation or data.countdownSeconds > 0 then
		State.IsFurnitureStoreOpen:set(false)
	end
end)

Net.furniturePurchaseResult.listen(function(data)
	State.FurniturePurchaseResult:set(data :: FurniturePurchaseResult)
	if data.success then
		State.IsFurnitureStoreOpen:set(false)
	end
end)

Net.buildingModeState.listen(function(data)
	State.IsInBuildingMode:set(data.enabled)
	State.MovingFurnitureEntity:set(data.movingEntity)
end)

Net.buildingPlacementResult.listen(function(data)
	if data.success then
		print("[Building] placement success")
	else
		print("[Building] placement failed")
	end
end)

Net.ingredientProcessState.listen(function(data)
	local states = table.clone(State.IngredientProcessStates:get())
	if data.active then
		states[data.entityId] = {
			progress = data.progress,
			participantCount = data.participantCount,
		}
	else
		states[data.entityId] = nil
	end
	State.IngredientProcessStates:set(states)
end)

Net.partyState.listen(function(data)
	State.Party:set(data :: PartyState)
	if not data.canStart then
		State.PartyStartPending:set(false)
	end
end)

Net.partyFriendsState.listen(function(data)
	State.PartyFriends:set(data.friends)
end)

Net.partyInvitesState.listen(function(data)
	State.PartyInvites:set(data.invites :: { PartyInvite })
end)

Net.partyInviteReceived.listen(function(data)
	local invites = table.clone(State.PartyInvites:get())
	table.insert(invites, data :: PartyInvite)
	State.PartyInvites:set(invites)
	State.PartyMessage:set(`Invitation from {data.inviterDisplayName}`)
end)

Net.partyActionResult.listen(function(data)
	if data.action == 7 then
		State.PartyStartPending:set(false)
	end
	if not data.success then
		State.PartyMessage:set(`Party action failed ({data.reason})`)
	end
end)

Net.partyTeleportStatus.listen(function(data)
	State.PartyStartPending:set(false)
	State.PartyMessage:set(({
		[1] = "Reserving server...",
		[2] = "Teleporting...",
		[3] = "Returning to lobby...",
		[4] = "Teleport failed",
	})[data.status] or "")
end)

-- All state listeners are active before requesting the server snapshots.
Net.clientReady.send({})

return State
