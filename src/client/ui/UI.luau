--!strict

-- Зависимости
local StarterPlayer = game:GetService("StarterPlayer")
local MoneyCounter = require(StarterPlayer.StarterPlayerScripts.Client.ui.MoneyCounter)
local ModeIndicator = require(StarterPlayer.StarterPlayerScripts.Client.ui.ModeIndicator)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Монтируем react
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(React.Fragment, nil, {
	MoneyCounter = React.createElement(MoneyCounter),
	ModeIndicator = React.createElement(ModeIndicator),
}))

return {}
