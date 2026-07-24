--!strict

--[[
	Чистые функции валидации размещения фурнитуры.
	Используются и на клиенте (предсказание/обратная связь), и на сервере (авторитетная проверка).
]]

local PlacementValidation = {}

export type ValidationResult = {
	IsValid: boolean,
	FloorPart: BasePart?,
	FloorY: number?,
}

local function isCornerInsidePart(worldCorner: Vector3, part: BasePart): boolean
	local localCorner = part.CFrame:PointToObjectSpace(worldCorner)
	local halfSize = part.Size / 2
	local epsilon = 0.01
	return math.abs(localCorner.X) <= halfSize.X + epsilon and math.abs(localCorner.Z) <= halfSize.Z + epsilon
end

function PlacementValidation.IsFootprintInsidePart(
	footprintCFrame: CFrame,
	footprintSize: Vector2,
	part: BasePart
): boolean
	local halfSize = footprintSize / 2
	local corners = {
		Vector3.new(-halfSize.X, 0, -halfSize.Y),
		Vector3.new(-halfSize.X, 0, halfSize.Y),
		Vector3.new(halfSize.X, 0, -halfSize.Y),
		Vector3.new(halfSize.X, 0, halfSize.Y),
	}

	for _, corner in corners do
		local worldCorner = footprintCFrame * corner
		if not isCornerInsidePart(worldCorner, part) then
			return false
		end
	end

	return true
end

function PlacementValidation.FindFloorPart(
	position: Vector3,
	buildZoneParts: { BasePart },
	maxDistance: number?
): BasePart?
	if #buildZoneParts == 0 then
		return nil
	end

	local distance = maxDistance or 100
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = buildZoneParts

	local origin = position + Vector3.new(0, distance, 0)
	local direction = Vector3.new(0, -distance * 2, 0)

	local result = workspace:Raycast(origin, direction, raycastParams)
	if not result then
		return nil
	end

	local hitPart = result.Instance
	if not hitPart:IsA("BasePart") then
		return nil
	end

	return hitPart
end

function PlacementValidation.Validate(
	footprintCFrame: CFrame,
	footprintSize: Vector2,
	buildZoneParts: { BasePart },
	maxHoverHeight: number
): ValidationResult
	local position = footprintCFrame.Position
	local floorPart = PlacementValidation.FindFloorPart(position, buildZoneParts)
	if not floorPart then
		return { IsValid = false, FloorPart = nil, FloorY = nil }
	end

	local floorY = floorPart.Position.Y + floorPart.Size.Y / 2
	local hover = position.Y - floorY
	if hover < -0.1 or hover > maxHoverHeight then
		return { IsValid = false, FloorPart = floorPart, FloorY = floorY }
	end

	if not PlacementValidation.IsFootprintInsidePart(footprintCFrame, footprintSize, floorPart) then
		return { IsValid = false, FloorPart = floorPart, FloorY = floorY }
	end

	return { IsValid = true, FloorPart = floorPart, FloorY = floorY }
end

return PlacementValidation
