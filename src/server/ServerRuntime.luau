--!strict

local ServerScriptService = game:GetService("ServerScriptService")

-- DataManager must load before modules that depend on player profiles.
require(ServerScriptService.Server.Player.DataManager)

local PartyServer = require(ServerScriptService.Server.Party.PartyServer)
local MatchLifecycle = require(ServerScriptService.Server.MatchLifecycle)
local NetworkHandlers = require(ServerScriptService.Server.NetworkHandlers)
local PlayerDataSync = require(ServerScriptService.Server.PlayerDataSync)
local GameLoop = require(ServerScriptService.Server.GameLoop)

local ServerRuntime = {}

function ServerRuntime:Start()
	PartyServer:Start()
	MatchLifecycle:Start()
	NetworkHandlers:Start()
	PlayerDataSync:Start()
	GameLoop:Start(function()
		MatchLifecycle:ProcessPhaseTransition()
	end)
end

return ServerRuntime
