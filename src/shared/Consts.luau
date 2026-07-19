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
    }
}

return Consts