local Consts = {
	InteractablePlayerDistance = 4,
	InteractableAllowedKeys = {
		[Enum.KeyCode.E] = true,
		[Enum.KeyCode.F] = true,
	},
	Attributes = {
		EntityId = "entityId",
		PlayerId = "playerId",
		OwnerFurnitureEntityId = "ownerFurnitureEntityId",
	},
	Tags = {
		Holds = "Holds",
		Placed = "Placed",
		PlaceHolder = "PlaceHolder",
		Interactable = "Interactable",
		Furniture = "Furniture",
		BuildZone = "BuildZone",
	},
	BuildModeMaxDistance = 12,
	BuildModePickupDistance = 6,
	BuildModeGridSize = 1,
	BuildModeRotationStep = math.rad(90),
}

return Consts
