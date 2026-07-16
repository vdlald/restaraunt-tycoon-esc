--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)

-- Объявление класса
local PlayerView = Class.defineClass("PlayerView")

function PlayerView.new(player: Player): Types.PlayerView
	local self: Types.PlayerView = setmetatable({}, PlayerView)
	self.Player = player
	return self
end

-- Методы

-- Посмотреть инструмент в руках пользователя
function PlayerView:GetEquippedTool(): jecs.Id<nil>?
	local tool = self:GetCharacter():FindFirstChildOfClass("Tool")
	if not tool then
		return nil
	end

	return tool:GetAttribute(Consts.Attributes.EntityId)
end

-- Забрать инструмент из рук пользователя
function PlayerView:TakeFromHands(): jecs.Id<nil>?
	local tool = self:GetEquippedTool()
	if not tool then
		return nil
	end

	self:GetHumanoid():UnequipTools()
	return tool:GetAttribute(Consts.Attributes.EntityId)
end

-- Положить пользователю предмет в руки
function PlayerView:PutInHands(tool: Tool)
	local player: Player = self.Player
	local character = self:GetCharacter()
	local humanoid = self:GetHumanoid()

	if tool.Parent ~= player.Backpack and tool.Parent ~= character then
		tool.Parent = player.Backpack
	end

	humanoid:UnequipTools()
	humanoid:EquipTool(tool)
end

-- Utils
function PlayerView:GetDistance(instance: Instance): number
	local humanoid = self:GetHumanoid()
	local primaryPart = instance.PrimaryPart or instance
	local distance = (humanoid.RootPart.Position - primaryPart.Position).Magnitude
	return distance
end

function PlayerView:GetCharacter(): Model
	local character = self.Player.Character or self.Player.CharacterAdded:Wait()
	return character
end

function PlayerView:GetHumanoid(): Humanoid
    local humanoid = self:GetCharacter():WaitForChild("Humanoid")
	return humanoid
end

function PlayerView:GetPlayer(): Player
	return self.Player
end

return PlayerView
