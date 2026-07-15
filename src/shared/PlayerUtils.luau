--!strict

local CollectionService = game:GetService("CollectionService")

local PlayerUtils = {}

function PlayerUtils:GetClosestInteractablePartInRadius(player: Player, radius: number): (Part?, number)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local parts = workspace:GetPartBoundsInRadius(hrp.Position, radius, params)

	local closestPart = nil
	local closestDistance = math.huge

	for _, part: Instance in ipairs(parts) do
		local parent: Instance = part.Parent
		if not parent or parent == workspace then 
			continue
		end 
		if CollectionService:HasTag(parent, "Interactable") and not CollectionService:HasTag(parent, "Placed") then
			local distance = (hrp.Position - part.Position).Magnitude

			if closestDistance > distance then
				closestDistance = distance
				closestPart = parent
			end
		end
	end

	return closestPart, closestDistance
end

return PlayerUtils
