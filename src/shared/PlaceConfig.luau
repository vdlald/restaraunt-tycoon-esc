--!strict

-- Set these values to the published places in the same Roblox universe.
-- PlaceId 0 keeps local Rojo/Studio sessions in Match mode.
local PlaceConfig = {
	LobbyPlaceId = 0,
	MatchPlaceId = 0,
}

function PlaceConfig:IsLobbyPlace(placeId: number): boolean
	return self.LobbyPlaceId ~= 0 and placeId == self.LobbyPlaceId
end

function PlaceConfig:IsMatchPlace(placeId: number): boolean
	return not self:IsLobbyPlace(placeId)
end

return PlaceConfig
