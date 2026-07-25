--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)

local NetClient = {}

function NetClient:PlayerInteract(entityId: number, keyCode: Enum.KeyCode)
	Net.playerInteract.send({
		entityId = entityId,
		keyCode = keyCode.Value,
	})
end

function NetClient:StartIngredientProcess(entityId: number)
	Net.ingredientProcessStart.send({
		entityId = entityId,
	})
end

function NetClient:StopIngredientProcess()
	Net.ingredientProcessStop.send({})
end

function NetClient:ToggleBuildingMode(enabled: boolean)
	Net.buildingModeToggle.send({
		enabled = enabled,
	})
end

function NetClient:CancelBuildingMove()
	Net.buildingModeCancelMove.send({})
end

function NetClient:BuildingGhostMove(position: Vector3)
	Net.buildingGhostMove.send({
		position = position,
	})
end

function NetClient:BuildingGhostRotate(deltaYaw: number)
	Net.buildingGhostRotate.send({
		deltaYaw = deltaYaw,
	})
end

function NetClient:RequestGamePhaseToggle()
	Net.gamePhaseToggle.send({})
end

function NetClient:RequestEndMatch()
	Net.endMatchRequest.send({})
end

function NetClient:RequestFurniturePurchase(furnitureId: string)
	Net.furniturePurchaseRequest.send({
		furnitureId = furnitureId,
	})
end

function NetClient:CreateParty()
	Net.partyCreateRequest.send({})
end

function NetClient:InviteToParty(userId: number)
	Net.partyInviteRequest.send({ targetUserId = userId })
end

function NetClient:AcceptPartyInvite(partyId: string)
	Net.partyInviteAcceptRequest.send({ partyId = partyId })
end

function NetClient:DeclinePartyInvite(partyId: string)
	Net.partyInviteDeclineRequest.send({ partyId = partyId })
end

function NetClient:LeaveParty()
	Net.partyLeaveRequest.send({})
end

function NetClient:KickFromParty(userId: number)
	Net.partyKickRequest.send({ targetUserId = userId })
end

function NetClient:StartPartyMatch()
	Net.partyStartRequest.send({})
end

return NetClient
