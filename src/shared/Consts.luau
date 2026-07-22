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
		InteractableDisabled = "InteractableDisabled",
		Furniture = "Furniture",
		BuildZone = "BuildZone",
	},
	BuildModeMaxDistance = 12,
	BuildModePickupDistance = 6,
	BuildModeGridSize = 1,
	BuildModeRotationStep = math.rad(90),
}

return Consts
