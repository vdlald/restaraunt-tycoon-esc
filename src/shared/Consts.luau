local Consts = {
	InteractablePlayerDistance = 4,
	InteractableAllowedKeys = {
		[Enum.KeyCode.E] = true,
		[Enum.KeyCode.F] = true,
	},
	Attributes = {
		EntityId = "entityId",
		PlayerId = "playerId",
	},
	Tags = {
		Holds = "Holds",
		Placed = "Placed",
		PlaceHolder = "PlaceHolder",
		Interactable = "Interactable",
		BuildZone = "BuildZone",
		BuildingGhost = "BuildingGhost",
	},

	BuildingMaxCarryDistance = 20,
	BuildingMaxHoverHeight = 0.5,
	BuildingFloorSnapTolerance = 0.1,
	BuildingGhostTransparency = 0.5,
	BuildingGhostSendInterval = 1 / 30,
	BuildingGhostSendThreshold = 0.05,
	BuildingGhostServerRateLimit = 1 / 30,
}

return Consts
