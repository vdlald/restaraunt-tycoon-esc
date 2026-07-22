--!strict

local BuildModePhysics = {}

function BuildModePhysics.Capture(instance: Instance): { [BasePart]: { Anchored: boolean, CanCollide: boolean } }
	local state = {}
	for _, descendant: Instance in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			state[descendant] = {
				Anchored = descendant.Anchored,
				CanCollide = descendant.CanCollide,
			}
		end
	end
	return state
end

function BuildModePhysics.Apply(physicsState: { [BasePart]: { Anchored: boolean, CanCollide: boolean } })
	for part: BasePart, saved in pairs(physicsState) do
		if part.Parent then
			part.Anchored = saved.Anchored
			part.CanCollide = saved.CanCollide
		end
	end
end

function BuildModePhysics.Disable(instance: Instance)
	for _, descendant: Instance in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
end

return BuildModePhysics
