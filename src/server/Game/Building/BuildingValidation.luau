--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Consts = require(ReplicatedStorage.Shared.Consts)
local PlacementValidation = require(ReplicatedStorage.Shared.Building.PlacementValidation)

local BuildingValidation = {}

local function getBuildZoneParts(): { BasePart }
	local parts = {}
	for _, instance in CollectionService:GetTagged(Consts.Tags.BuildZone) do
		if instance:IsA("BasePart") then
			table.insert(parts, instance :: BasePart)
		end
	end
	return parts
end

function BuildingValidation.GetBuildZoneParts(): { BasePart }
	return getBuildZoneParts()
end

function BuildingValidation.ValidateModelPlacement(
	instance: Model,
	targetCFrame: CFrame,
	maxHoverHeight: number?
): PlacementValidation.ValidationResult
	local primaryPart = instance.PrimaryPart
	if not primaryPart then
		return { IsValid = false, FloorPart = nil, FloorY = nil }
	end

	local footprintSize = Vector2.new(primaryPart.Size.X, primaryPart.Size.Z)
	local maxHover = maxHoverHeight or Consts.BuildingMaxHoverHeight

	return PlacementValidation.Validate(targetCFrame, footprintSize, getBuildZoneParts(), maxHover)
end

function BuildingValidation.IsOverlappingPlacedFurniture(instance: Model): boolean
	local boundingBoxCFrame, boundingBoxSize = instance:GetBoundingBox()
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { instance }
	local querySize = Vector3.new(
		math.max(0, boundingBoxSize.X - 0.05),
		math.max(0, boundingBoxSize.Y - 0.05),
		math.max(0, boundingBoxSize.Z - 0.05)
	)

	for _, part in workspace:GetPartBoundsInBox(boundingBoxCFrame, querySize, overlapParams) do
		local target: Instance? = part
		while target and target ~= workspace do
			if target:HasTag(Consts.Tags.BuildingMoveable) then
				return true
			end
			target = target.Parent
		end
	end
	return false
end

return BuildingValidation
