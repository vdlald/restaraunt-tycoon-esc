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
		buildingModeToggle = ByteNet.definePacket({
			value = ByteNet.struct({
				enabled = ByteNet.bool,
			}),
		}),

		buildingModeCancelMove = ByteNet.definePacket({
			value = ByteNet.struct({}),
		}),

		buildingGhostMove = ByteNet.definePacket({
			value = ByteNet.struct({
				position = ByteNet.vec3,
			}),
		}),

		buildingGhostRotate = ByteNet.definePacket({
			value = ByteNet.struct({
				deltaYaw = ByteNet.float32,
			}),
		}),

		buildingModeState = ByteNet.definePacket({
			value = ByteNet.struct({
				enabled = ByteNet.bool,
				movingEntity = ByteNet.int32,
			}),
		}),

		buildingPlacementResult = ByteNet.definePacket({
			value = ByteNet.struct({
				success = ByteNet.bool,
			}),
		}),
	}
end)

return Net
