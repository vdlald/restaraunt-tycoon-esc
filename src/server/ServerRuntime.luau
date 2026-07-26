--!strict

local ServerScriptService = game:GetService("ServerScriptService")

-- DataManager must load before modules that depend on player profiles.
require(ServerScriptService.Server.Player.DataManager)

local PartyServer = require(ServerScriptService.Server.Party.PartyServer)
local MatchLifecycle = require(ServerScriptService.Server.MatchLifecycle)
local NetworkHandlers = require(ServerScriptService.Server.NetworkHandlers)
local PlayerDataSync = require(ServerScriptService.Server.PlayerDataSync)
local GameLoop = require(ServerScriptService.Server.GameLoop)
local GameContext = require(ServerScriptService.Server.GameContext)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)

local ServerRuntime = {}

function ServerRuntime:Start()
	local context = GameContext.new()
	GameCycle:Configure(context)
	PartyServer:Start()
	MatchLifecycle:Start(context)
	NetworkHandlers:Start(context)
	PlayerDataSync:Start()
	GameLoop:Start(context, function()
		MatchLifecycle:ProcessPhaseTransition()
	end)
end

return ServerRuntime
