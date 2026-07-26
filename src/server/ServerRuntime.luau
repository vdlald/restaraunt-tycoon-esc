--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.Player.DataManager)

local PartyServer = require(ServerScriptService.Server.Party.PartyServer)
local MatchLifecycle = require(ServerScriptService.Server.MatchLifecycle)
local NetworkHandlers = require(ServerScriptService.Server.NetworkHandlers)
local PlayerDataSync = require(ServerScriptService.Server.PlayerDataSync)
local GameLoop = require(ServerScriptService.Server.GameLoop)
local GameContext = require(ServerScriptService.Server.GameContext)
local ServerApplication = require(ServerScriptService.Server.Application.ServerApplication)

local ServerRuntime = {}

function ServerRuntime:Start()
	DataManager:Start()
	local context = GameContext.new()
	local applications = ServerApplication.new(context)
	PartyServer:Start()
	MatchLifecycle:Start(context)
	NetworkHandlers:Start(applications)
	PlayerDataSync:Start()
	GameLoop:Start(context, function()
		MatchLifecycle:ProcessPhaseTransition()
	end)
end

return ServerRuntime
