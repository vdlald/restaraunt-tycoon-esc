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

return NetClient
