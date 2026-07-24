--!strict

-- Зависимости
local StarterPlayer = game:GetService("StarterPlayer")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local LocalPlayerUtils = require(StarterPlayer.StarterPlayerScripts.Client.LocalPlayerUtils)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Val = require(ReplicatedStorage.Packages.Val)
local Consts = require(ReplicatedStorage.Shared.Consts)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--
-- Объявление
State.TargetInteractable = Val.new()

local function IsInteractable(instance: Instance): boolean
	if not instance then
		return false
	end
	if State.IsInBuildingMode:get() then
		return instance:HasTag(Consts.Tags.BuildingMoveable)
	else
		if not instance:HasTag(Consts.Tags.Interactable) then
			return false
		end

		-- Если это PlaceHolder, на котором уже что-то стоит, то не подсвечиваем
		if instance:HasTag(Consts.Tags.PlaceHolder) and instance:HasTag(Consts.Tags.Holds) then
			return false
		end

		-- Если есть что-то в руках
		local equipped = LocalPlayerUtils:GetEquippedTool()
		if equipped then
			-- И на placeHolder ничего нет
			return instance:HasTag(Consts.Tags.PlaceHolder) and not instance:HasTag(Consts.Tags.Holds)
				or not instance:HasTag(Consts.Tags.PlaceHolder)
		end

		return not instance:HasTag(Consts.Tags.PlaceHolder)
	end
end

function FindInteractable(): Instance?
	if not LocalPlayerUtils:IsFirstPerson() then
		return nil
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
		return nil
	end

	local part: Instance = result.Instance
	if not IsInteractable(part) then
		-- Если с текущей частью нельзя взаимодействовать, то берем родительскую часть
		part = part:FindFirstAncestorOfClass("Model") or part:FindFirstAncestorOfClass("Tool")
	end

	if not IsInteractable(part) then
		-- Если родительская часть не интерактивна - выходим
		return nil
	end

	return part
end

--
-- Обновление
local RunService = game:GetService("RunService")

RunService.RenderStepped:Connect(function(_)
	local interactable = FindInteractable()
	State.TargetInteractable:set(interactable)
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

State.TargetInteractable:on(function(instance: Instance)
	highlight.Adornee = instance
	highlight.Enabled = instance ~= nil
end)

return {}
