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

function NetClient:BuildModeSetActive(active: boolean)
	Net.buildModeSetActive.send({
		active = active,
	})
end

function NetClient:BuildModePlace(aimPoint: Vector3, yaw: number)
	Net.buildModePlace.send({
		aimPoint = aimPoint,
		yaw = yaw,
	})
end

return NetClient
