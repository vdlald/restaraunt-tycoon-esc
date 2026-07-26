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
local started = false
local shutdownRegistered = false

local function stop()
	DataManager:Stop()
end

function ServerRuntime:Start()
	if started then
		return
	end
	started = true
	DataManager:Start()
	if not shutdownRegistered then
		shutdownRegistered = true
		game:BindToClose(stop)
	end
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
