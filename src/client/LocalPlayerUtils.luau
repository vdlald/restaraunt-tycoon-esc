--!strict

-- Зависимости
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Функции
local LocalPlayerUtils = {}

function LocalPlayerUtils:GetEquippedTool(): Tool?
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Tool")
end

function LocalPlayerUtils:IsFirstPerson()
	local char = player.Character
	if not char then
		return false
	end

	local head = char:FindFirstChild("Head")
	if not head then
		return false
	end

	local headPos = head.Position
	local cameraPos = camera.CFrame.Position

	local distance = (cameraPos - headPos).Magnitude
	return distance < 1
end

return LocalPlayerUtils