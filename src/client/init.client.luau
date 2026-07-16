--!strict

-- Зависимости
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Consts = require(ReplicatedStorage.Shared.Consts)
local PlayerUtils = require(ReplicatedStorage.Shared.PlayerUtils)
local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)

--
-- Общие переменные
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
player.CameraMode = Enum.CameraMode.LockFirstPerson

local closestPart: Instance = PlayerUtils:GetClosestInteractablePartInRadius(player, Consts.InteractablePlayerDistance)

--
-- Впомогательные функции
local function isFirstPerson()
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

--
-- Взаимодействие с миром
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if not closestPart then
		return
	end

	if Consts.InteractableAllowedKeys[input.KeyCode] then
		local entityId = closestPart:GetAttribute(Consts.Attributes.EntityId)
		if not entityId then
			return
		end
		NetClient:PlayerInteract(entityId, input.KeyCode)
	end
end)

--
-- Подсветка ближайшей фурниутры
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 183, 0)
highlight.OutlineColor = Color3.fromRGB(222, 109, 23)
highlight.FillTransparency = 0.75
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = workspace

local timePassed = 0
RunService.Heartbeat:Connect(function(dt)
	if isFirstPerson() then
		return
	end

	timePassed += dt

	if timePassed < 0.1 then
		return
	end

	timePassed -= 0.1

	closestPart = PlayerUtils:GetClosestInteractablePartInRadius(player, Consts.InteractablePlayerDistance)

	if closestPart then
		highlight.Adornee = closestPart
		highlight.Enabled = true
	else
		highlight.Adornee = nil
		highlight.Enabled = false
	end
end)

RunService.RenderStepped:Connect(function(_)
	if not isFirstPerson() then
		return
	end

	-- Начало луча: позиция камеры
	local origin = camera.CFrame.Position
	-- Направление: вперёд от камеры
	local direction = camera.CFrame.LookVector * 6

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character } -- игнорируем себя

	local result = workspace:Raycast(origin, direction, raycastParams)
	if not result or not result.Instance then
		return
	end

	local part: Instance = result.Instance
	if not part:HasTag(Consts.Tags.Interactable) then
		part = part:FindFirstAncestorOfClass("Model") or part:FindFirstAncestorOfClass("Tool")
	end

	if not part or not part:HasTag(Consts.Tags.Interactable) or part:HasTag(Consts.Tags.Placed) then
		return
	end

	closestPart = part

	if closestPart then
		highlight.Adornee = closestPart
		highlight.Enabled = true
	else
		highlight.Adornee = nil
		highlight.Enabled = false
	end
end)
