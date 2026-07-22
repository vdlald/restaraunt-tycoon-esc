--!strict

local CollectionService = game:GetService("CollectionService")
local Consts = require(game:GetService("ReplicatedStorage").Shared.Consts)

local BuildModeValidator = {}

local function getBuildZoneParts(): { Instance }
	return CollectionService:GetTagged(Consts.Tags.BuildZone)
end

function BuildModeValidator.IsInBuildZone(position: Vector3): boolean
	local zones = getBuildZoneParts()
	if #zones == 0 then
		return true
	end

	for _, zone: Instance in ipairs(zones) do
		local part = zone :: BasePart
		local min = part.Position - part.Size / 2
		local max = part.Position + part.Size / 2
		if position.X >= min.X and position.X <= max.X and position.Z >= min.Z and position.Z <= max.Z then
			return true
		end
	end

	return false
end

function BuildModeValidator.FindFloorUnder(position: Vector3): RaycastResult?
	local zones = getBuildZoneParts()
	if #zones == 0 then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = zones

	return workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0), params)
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
	local grid = Consts.BuildModeGridSize
	return Vector3.new(math.round(position.X / grid) * grid, position.Y, math.round(position.Z / grid) * grid)
end

return BuildModeValidator
