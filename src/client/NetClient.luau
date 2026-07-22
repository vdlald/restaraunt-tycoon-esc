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

function NetClient:BuildModePlace(cframe: CFrame)
	Net.buildModePlace.send({
		cframe = cframe,
	})
end

return NetClient
