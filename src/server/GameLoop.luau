--!strict

local RunService = game:GetService("RunService")

local GameLoop = {}

function GameLoop:Start(context, processMatchPhaseTransition: () -> ())
	local registry = context.Systems
	context:ConfigureSystems()

	RunService.Heartbeat:Connect(function(deltaTime)
		context.GameCycle:Process(deltaTime)
		processMatchPhaseTransition()

		registry:Process("Intent", deltaTime)
		registry:Process("Simulation", deltaTime)
		registry:Process("Lifecycle", deltaTime)
	end)
end

return GameLoop
