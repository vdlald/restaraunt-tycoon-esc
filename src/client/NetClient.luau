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

return NetClient
