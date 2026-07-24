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

return BuildingValidation
