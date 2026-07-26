--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local LocalPlayerUtils = require(StarterPlayer.StarterPlayerScripts.Client.LocalPlayerUtils)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Val = require(ReplicatedStorage.Packages.Val)
local Consts = require(ReplicatedStorage.Shared.Consts)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

State.TargetInteractable = Val.new()

local function isInteractable(instance: Instance?): boolean
	if not instance then
		return false
	end
	if State.IsInBuildingMode:get() then
		return instance:HasTag(Consts.Tags.BuildingMoveable)
	end
	if not instance:HasTag(Consts.Tags.Interactable) then
		return false
	end

	if instance:HasTag(Consts.Tags.PlaceHolder) and instance:HasTag(Consts.Tags.Holds) then
		return false
	end

	local equipped = LocalPlayerUtils:GetEquippedTool()
	if equipped then
		return instance:HasTag(Consts.Tags.PlaceHolder) and not instance:HasTag(Consts.Tags.Holds)
			or not instance:HasTag(Consts.Tags.PlaceHolder)
	end

	return not instance:HasTag(Consts.Tags.PlaceHolder)
end

local function findInteractable(): Instance?
	if not LocalPlayerUtils:IsFirstPerson() then
		return nil
	end

	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * 6
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character }

	local result = workspace:Raycast(origin, direction, raycastParams)
	if not result then
		return nil
	end

	local part: Instance? = result.Instance
	if not isInteractable(part) then
		part = part:FindFirstAncestorOfClass("Model") or part:FindFirstAncestorOfClass("Tool")
	end
	return if isInteractable(part) then part else nil
end

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function()
	State.TargetInteractable:set(findInteractable())
end)

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 183, 0)
highlight.OutlineColor = Color3.fromRGB(222, 109, 23)
highlight.FillTransparency = 0.75
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = workspace

State.TargetInteractable:on(function(instance: Instance?)
	highlight.Adornee = instance
	highlight.Enabled = instance ~= nil
end)

return {}
