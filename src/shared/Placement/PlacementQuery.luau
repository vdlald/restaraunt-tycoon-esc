--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

local PlacementQuery = {}

local function getBuildZoneParts(): { Instance }
	return CollectionService:GetTagged(Consts.Tags.BuildZone)
end

function PlacementQuery.IsInBuildZone(position: Vector3): boolean
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

function PlacementQuery.FindFloorUnder(aimPoint: Vector3): RaycastResult?
	local zones = getBuildZoneParts()
	if #zones == 0 then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = zones

	return workspace:Raycast(aimPoint + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), params)
end

function PlacementQuery.SnapPosition(position: Vector3): Vector3
	local grid = Consts.BuildModeGridSize
	return Vector3.new(math.round(position.X / grid) * grid, position.Y, math.round(position.Z / grid) * grid)
end

function PlacementQuery.ComputePlacementCFrame(aimPoint: Vector3, yaw: number, modelHeight: number): CFrame?
	if not PlacementQuery.IsInBuildZone(aimPoint) then
		return nil
	end

	local floorResult = PlacementQuery.FindFloorUnder(aimPoint)
	if not floorResult then
		return nil
	end

	local snappedPosition =
		PlacementQuery.SnapPosition(Vector3.new(aimPoint.X, floorResult.Position.Y + modelHeight, aimPoint.Z))
	return CFrame.new(snappedPosition) * CFrame.Angles(0, yaw, 0)
end

return PlacementQuery
