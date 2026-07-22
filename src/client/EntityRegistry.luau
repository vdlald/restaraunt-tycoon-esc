--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

local EntityRegistry = {}

local entityToInstance: { [number]: Instance } = {}
local instanceToEntity: { [Instance]: number? } = {}

local function updateMapping(instance: Instance)
	local oldId = instanceToEntity[instance]
	local newId: number? = instance:GetAttribute(Consts.Attributes.EntityId)

	if typeof(newId) == "number" then
		if oldId ~= nil and oldId ~= newId then
			entityToInstance[oldId] = nil
		end
		entityToInstance[newId] = instance
		instanceToEntity[instance] = newId
	else
		if oldId ~= nil then
			entityToInstance[oldId] = nil
		end
		instanceToEntity[instance] = nil
	end
end

local function trackInstance(instance: Instance)
	updateMapping(instance)
	instance:GetAttributeChangedSignal(Consts.Attributes.EntityId):Connect(function()
		updateMapping(instance)
	end)
end

for _, instance in ipairs(workspace:GetDescendants()) do
	trackInstance(instance)
end

workspace.DescendantAdded:Connect(trackInstance)

workspace.DescendantRemoving:Connect(function(instance: Instance)
	local oldId = instanceToEntity[instance]
	if oldId ~= nil then
		entityToInstance[oldId] = nil
	end
	instanceToEntity[instance] = nil
end)

function EntityRegistry.GetInstanceByEntityId(entityId: number): Instance?
	return entityToInstance[entityId]
end

return EntityRegistry
