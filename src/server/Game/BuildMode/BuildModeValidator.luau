--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)
local PlacementQuery = require(ReplicatedStorage.Shared.Placement.PlacementQuery)

local BuildModeValidator = {}

function BuildModeValidator.IsInBuildZone(position: Vector3): boolean
	return PlacementQuery.IsInBuildZone(position)
end

function BuildModeValidator.FindFloorUnder(position: Vector3): RaycastResult?
	return PlacementQuery.FindFloorUnder(position)
end

function BuildModeValidator.IsPlacementReachable(playerPosition: Vector3, targetPosition: Vector3): boolean
	return (playerPosition - targetPosition).Magnitude <= Consts.BuildModeMaxDistance
end

function BuildModeValidator.IsAreaClear(targetCFrame: CFrame, size: Vector3, ignoreList: { Instance }?): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList or {}

	local parts = workspace:GetPartBoundsInBox(targetCFrame, size, params)
	return #parts == 0
end

function BuildModeValidator.SnapPosition(position: Vector3): Vector3
	return PlacementQuery.SnapPosition(position)
end

function BuildModeValidator.ComputePlacementCFrame(aimPoint: Vector3, yaw: number, modelHeight: number): CFrame?
	return PlacementQuery.ComputePlacementCFrame(aimPoint, yaw, modelHeight)
end

return BuildModeValidator
