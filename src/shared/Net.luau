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

		-- Режим строительства
		buildModeSetActive = ByteNet.definePacket({
			value = ByteNet.struct({
				active = ByteNet.bool,
			}),
		}),

		buildModePlace = ByteNet.definePacket({
			value = ByteNet.struct({
				cframe = ByteNet.cframe,
			}),
		}),

		buildModeState = ByteNet.definePacket({
			value = ByteNet.struct({
				active = ByteNet.bool,
				carriedEntityId = ByteNet.optional(ByteNet.int32),
			}),
		}),
	}
end)

return Net
