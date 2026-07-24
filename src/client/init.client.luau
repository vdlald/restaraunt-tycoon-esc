--!strict

-- Зависимости
local StarterPlayer = game:GetService("StarterPlayer")
require(StarterPlayer.StarterPlayerScripts.Client.UI.UI)
require(StarterPlayer.StarterPlayerScripts.Client.BuildingClient)
require(StarterPlayer.StarterPlayerScripts.Client.Interaction.PlayerInteract)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

--
-- Параметры студии
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end
