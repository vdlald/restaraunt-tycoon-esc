--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNet = require(ReplicatedStorage.Packages.ByteNet)

local Net = ByteNet.defineNamespace("Game", function()
	-- ByteNet registers structures while defining the namespace. Keeping these
	-- declarations here is required on the client, where schema metadata is read.
	local partyMember = ByteNet.struct({
		userId = ByteNet.uint32,
		displayName = ByteNet.string,
		username = ByteNet.string,
		isLeader = ByteNet.bool,
	})

	local partyInvite = ByteNet.struct({
		partyId = ByteNet.string,
		inviterUserId = ByteNet.uint32,
		inviterDisplayName = ByteNet.string,
	})

	return {
		-- Событие взаимодействия пользователя с View
		playerInteract = ByteNet.definePacket({
			value = ByteNet.struct({
				entityId = ByteNet.int32,
				keyCode = ByteNet.uint8,
			}),
		}),

		ingredientProcessStart = ByteNet.definePacket({
			value = ByteNet.struct({
				entityId = ByteNet.int32,
			}),
		}),

		ingredientProcessStop = ByteNet.definePacket({
			value = ByteNet.struct({}),
		}),

		ingredientProcessState = ByteNet.definePacket({
			value = ByteNet.struct({
				entityId = ByteNet.int32,
				progress = ByteNet.float32,
				participantCount = ByteNet.uint8,
				active = ByteNet.bool,
			}),
		}),

		-- Обновление данных пользователя
		playerDataUpdate = ByteNet.definePacket({
			value = ByteNet.struct({
				experience = ByteNet.int32,
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

		furniturePurchaseRequest = ByteNet.definePacket({
			value = ByteNet.struct({
				furnitureId = ByteNet.string,
			}),
		}),

		furniturePurchaseResult = ByteNet.definePacket({
			value = ByteNet.struct({
				furnitureId = ByteNet.string,
				success = ByteNet.bool,
				reason = ByteNet.uint8,
			}),
		}),

		gamePhaseToggle = ByteNet.definePacket({
			value = ByteNet.struct({}),
		}),

		endMatchRequest = ByteNet.definePacket({
			value = ByteNet.struct({}),
		}),

		gameCycleState = ByteNet.definePacket({
			value = ByteNet.struct({
				phase = ByteNet.uint8,
				day = ByteNet.uint8,
				countdownSeconds = ByteNet.uint8,
				guestsRemaining = ByteNet.uint8,
				serviceSecondsRemaining = ByteNet.uint16,
				cash = ByteNet.int32,
				canEndMatch = ByteNet.bool,
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

		partyCreateRequest = ByteNet.definePacket({ value = ByteNet.struct({}) }),
		partyInviteRequest = ByteNet.definePacket({
			value = ByteNet.struct({ targetUserId = ByteNet.uint32 }),
		}),
		partyInviteAcceptRequest = ByteNet.definePacket({
			value = ByteNet.struct({ partyId = ByteNet.string }),
		}),
		partyInviteDeclineRequest = ByteNet.definePacket({
			value = ByteNet.struct({ partyId = ByteNet.string }),
		}),
		partyLeaveRequest = ByteNet.definePacket({ value = ByteNet.struct({}) }),
		partyKickRequest = ByteNet.definePacket({
			value = ByteNet.struct({ targetUserId = ByteNet.uint32 }),
		}),
		partyStartRequest = ByteNet.definePacket({ value = ByteNet.struct({}) }),

		partyState = ByteNet.definePacket({
			value = ByteNet.struct({
				inParty = ByteNet.bool,
				partyId = ByteNet.string,
				phase = ByteNet.uint8,
				members = ByteNet.array(partyMember),
				canStart = ByteNet.bool,
				canInvite = ByteNet.bool,
				canKick = ByteNet.bool,
				canLeave = ByteNet.bool,
			}),
		}),
		partyFriendsState = ByteNet.definePacket({
			value = ByteNet.struct({
				friends = ByteNet.array(ByteNet.struct({
					userId = ByteNet.uint32,
					displayName = ByteNet.string,
					username = ByteNet.string,
					isOnlineInExperience = ByteNet.bool,
					canInvite = ByteNet.bool,
				})),
			}),
		}),
		partyInvitesState = ByteNet.definePacket({
			value = ByteNet.struct({ invites = ByteNet.array(partyInvite) }),
		}),
		partyInviteReceived = ByteNet.definePacket({ value = partyInvite }),
		partyActionResult = ByteNet.definePacket({
			value = ByteNet.struct({
				action = ByteNet.uint8,
				success = ByteNet.bool,
				reason = ByteNet.uint8,
			}),
		}),
		partyTeleportStatus = ByteNet.definePacket({
			value = ByteNet.struct({ status = ByteNet.uint8 }),
		}),
	}
end)

return Net
