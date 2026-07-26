--!strict

export type ProcessSystem = {
	Process: (self: ProcessSystem, deltaTime: number) -> (),
}

export type Phase = "Intent" | "Simulation" | "Lifecycle"

local SystemRegistry = {}
SystemRegistry.__index = SystemRegistry

function SystemRegistry.new()
	return setmetatable({
		Intent = {} :: { ProcessSystem },
		Simulation = {} :: { ProcessSystem },
		Lifecycle = {} :: { ProcessSystem },
	}, SystemRegistry)
end

function SystemRegistry:Register(phase: Phase, system: ProcessSystem)
	table.insert(self[phase], system)
end

function SystemRegistry:Process(phase: Phase, deltaTime: number)
	for _, system in self[phase] do
		system:Process(deltaTime)
	end
end

return SystemRegistry
