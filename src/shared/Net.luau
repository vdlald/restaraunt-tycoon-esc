--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage.Packages.ByteNet)

local Net = ByteNet.defineNamespace("Game", function()
	return {
		-- Событие взаимодействия пользователя с View
		playerInteract = ByteNet.definePacket({
			value = ByteNet.struct({
				entityId = ByteNet.int32,
				keyCode = ByteNet.uint8,
			}),
		}),

		-- Обновление данных пользователя
		playerDataUpdate = ByteNet.definePacket({
			value = ByteNet.struct({
				coins = ByteNet.int32,
			}),
		}),
	}
end)

return Net
