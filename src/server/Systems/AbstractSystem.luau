--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

-- Объявление системы
local AbstractSystem = Class:defineClass("AbstractSystem")

export type AbstractSystem = {
    Process: (self: AbstractSystem, deltaTime: number) -> (),
    IsThrottled: (self: AbstractSystem, deltaTime: number) -> boolean,
}

function AbstractSystem.new()
	local self = setmetatable({}, AbstractSystem)
    return self
end

function AbstractSystem:Process(deltaTime: number)
    if self:IsThrottled() then
        return
    end
end

function AbstractSystem:IsThrottled(deltaTime: number): boolean
    return false
end

return AbstractSystem