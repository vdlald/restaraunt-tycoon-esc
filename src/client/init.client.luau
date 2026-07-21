--!strict

-- Зависимости
local StarterPlayer = game:GetService("StarterPlayer")
local UI = require(StarterPlayer.StarterPlayerScripts.Client.ui.UI)
local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Val = require(ReplicatedStorage.Packages.Val)
local Consts = require(ReplicatedStorage.Shared.Consts)
local PlayerUtils = require(ReplicatedStorage.Shared.PlayerUtils)

--
-- Общие переменные
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
-- player.CameraMode = Enum.CameraMode.LockFirstPerson

local closestPart = Val.new(PlayerUtils:GetClosestInteractablePartInRadius(player, Consts.InteractablePlayerDistance))

--
-- Впомогательные функции
local function getEquippedTool(): Tool?
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Tool")
end

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

	local part = closestPart:get()
	if not part then
		return
	end

	if Consts.InteractableAllowedKeys[input.KeyCode] then
		local entityId = part:GetAttribute(Consts.Attributes.EntityId)
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

closestPart:on(function(instance: Instance)
	highlight.Adornee = instance
	highlight.Enabled = instance ~= nil
end)

function IsInteractable(instance: Instance): boolean
	if not instance or not instance:HasTag(Consts.Tags.Interactable) then
		return false
	end

	-- Если это PlaceHolder, на котором уже что-то стоит, то не подсвечиваем
	if instance:HasTag(Consts.Tags.PlaceHolder) and instance:HasTag(Consts.Tags.Holds) then
		return false
	end

	-- Если есть что-то в руках
	local equipped = getEquippedTool()
	if equipped then
		-- И на placeHolder ничего нет
		return instance:HasTag(Consts.Tags.PlaceHolder) and not instance:HasTag(Consts.Tags.Holds)
			or not instance:HasTag(Consts.Tags.PlaceHolder)
	end

	return not instance:HasTag(Consts.Tags.PlaceHolder)
end

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

	closestPart:set(PlayerUtils:GetClosestInteractablePartInRadius(player, Consts.InteractablePlayerDistance))
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
		-- Ни на что не смотрим
		closestPart:set(nil)
		return
	end

	local part: Instance = result.Instance
	if not IsInteractable(part) then
		-- Если с текущей частью нельзя взаимодействовать, то берем родительскую часть
		part = part:FindFirstAncestorOfClass("Model") or part:FindFirstAncestorOfClass("Tool")
	end

	if not IsInteractable(part) then
		-- Если родительская часть не интерактивна - выходим
		closestPart:set(nil)
		return
	end

	closestPart:set(part)
end)
