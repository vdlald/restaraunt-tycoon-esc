--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Utils = require(ReplicatedStorage.Shared.Utils)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

-- Объявление системы
local AbstractSystem = Class:defineClass("AbstractSystem")

export type AbstractSystem = {
	Process: (self: AbstractSystem, deltaTime: number) -> (),
	IsThrottled: (self: AbstractSystem, deltaTime: number) -> boolean,
	query: <T>(self: AbstractSystem, ...any) -> QueryExt<T>,
}

function AbstractSystem.new()
	local self = setmetatable({}, AbstractSystem)
	return self
end

function AbstractSystem:Process(deltaTime: number)
	if self:IsThrottled(deltaTime) then
		return
	end
end

function AbstractSystem:IsThrottled(deltaTime: number): boolean
	return false
end

local QueryExt = Class.defineClass("QueryExt", jecs.Query)

export type QueryExt = jecs.Query & {
	forEach: (self: QueryExt, ...any) -> jecs.Entity<nil>?,
}

function QueryExt.new(query)
	local parent = query
	local self = setmetatable(parent, QueryExt)
	return self
end

function QueryExt:forEach(forEachFn: (...any) -> jecs.Entity<nil>?)
	local iter, state, init = self:__iter()
	local iterCarry: IterCarry = function(element: any): ...any
		return iter(state, element)
	end

	local next, _ = Utils:safeCall("QueryExt:ForEach", function()
		return forEachFn(iterCarry(init))
	end)

	while next ~= nil do
		next, _ = Utils:safeCall("QueryExt:ForEach", function()
			return forEachFn(iterCarry(next))
		end)
	end
end

--
-- Подсистемы
type IterCarry = (element: any) -> ...any

function AbstractSystem:query(...): QueryExt
	return QueryExt.new(world:query(...))
end

return AbstractSystem
