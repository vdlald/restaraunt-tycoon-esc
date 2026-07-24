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

		gamePhaseToggle = ByteNet.definePacket({
			value = ByteNet.struct({}),
		}),

		gameCycleState = ByteNet.definePacket({
			value = ByteNet.struct({
				phase = ByteNet.uint8,
				day = ByteNet.uint8,
				countdownSeconds = ByteNet.uint8,
				guestsRemaining = ByteNet.uint8,
				serviceSecondsRemaining = ByteNet.uint16,
			}),
		}),

		dayReceipt = ByteNet.definePacket({
			value = ByteNet.struct({
				day = ByteNet.uint8,
				dishes = ByteNet.array(ByteNet.struct({
					dishName = ByteNet.string,
					count = ByteNet.uint8,
					earned = ByteNet.uint16,
				})),
				total = ByteNet.uint16,
			}),
		}),
	}
end)

return Net
