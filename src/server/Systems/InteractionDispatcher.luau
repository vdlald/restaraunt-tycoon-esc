--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

export type Handler = {
	HandleInteraction: (
		self: Handler,
		target: jecs.Entity<nil>,
		playerView: Types.PlayerView,
		keyCode: Enum.KeyCode
	) -> boolean,
}

export type InteractionDispatcher = {
	Register: (self: InteractionDispatcher, handler: Handler) -> (),
	Dispatch: (
		self: InteractionDispatcher,
		target: jecs.Entity<nil>,
		playerView: Types.PlayerView,
		keyCode: Enum.KeyCode
	) -> (),
	Clear: (self: InteractionDispatcher) -> (),
	_handlers: { Handler },
}

local InteractionDispatcher = {}
InteractionDispatcher.__index = InteractionDispatcher

function InteractionDispatcher.new(): InteractionDispatcher
	return setmetatable({
		_handlers = {},
	}, InteractionDispatcher) :: InteractionDispatcher
end

function InteractionDispatcher:Register(handler: Handler)
	assert(
		type(handler.HandleInteraction) == "function",
		`Interaction handler {(handler :: any).ClassName or "<unnamed>"} must define HandleInteraction`
	)
	table.insert(self._handlers, handler)
end

function InteractionDispatcher:Dispatch(target: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	for _, handler in self._handlers do
		local ok, handled = xpcall(handler.HandleInteraction, debug.traceback, handler, target, playerView, keyCode)
		if not ok then
			warn(`Interaction handler failed: {handled}`)
		elseif handled then
			return
		end
	end
end

function InteractionDispatcher:Clear()
	table.clear(self._handlers)
end

return InteractionDispatcher
