--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)

if PlaceConfig:IsLobbyPlace(game.PlaceId) then
	require(script.Parent.Party.LobbyServer)
	return
end

require(script.Parent.ServerRuntime):Start()
