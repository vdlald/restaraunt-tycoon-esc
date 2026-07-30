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
	local character = self:GetCharacter()
	if not character then
		return nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return nil
	end

	return tool:GetAttribute(Consts.Attributes.EntityId)
end

-- Забрать инструмент из рук пользователя
function PlayerView:TakeFromHands(): jecs.Id<nil>?
	local tool = self:GetEquippedTool()
	local humanoid = self:GetHumanoid()
	if not tool or not humanoid then
		return nil
	end

	humanoid:UnequipTools()
	return tool
end

-- Положить пользователю предмет в руки
function PlayerView:PutInHands(tool: Tool)
	local player: Player = self.Player
	local character = self:GetCharacter()
	local humanoid = self:GetHumanoid()
	if not character or not humanoid then
		return
	end

	if tool.Parent ~= player.Backpack and tool.Parent ~= character then
		tool.Parent = player.Backpack
	end

	humanoid:UnequipTools()
	humanoid:EquipTool(tool)
end

-- Utils
function PlayerView:GetDistance(instance: Instance): number?
	local humanoid = self:GetHumanoid()
	if not humanoid or not humanoid.RootPart then
		return nil
	end
	local ok, res = pcall(function()
		return instance.PrimaryPart
	end)

	local primaryPart: BasePart?
	if ok and res and res:IsA("BasePart") then
		primaryPart = res
	elseif instance:IsA("BasePart") then
		primaryPart = instance
	end
	if not primaryPart then
		return nil
	end

	local distance = (humanoid.RootPart.Position - primaryPart.Position).Magnitude
	return distance
end

function PlayerView:GetCharacter(): Model?
	return self.Player.Character
end

function PlayerView:GetHumanoid(): Humanoid?
	local character = self:GetCharacter()
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function PlayerView:GetPlayer(): Player
	return self.Player
end

return PlayerView
