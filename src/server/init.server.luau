--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)

if PlaceConfig:IsLobbyPlace(game.PlaceId) then
	require(ServerScriptService.Server.Party.LobbyServer)
	return
end

require(ServerScriptService.Server.ServerRuntime):Start()
