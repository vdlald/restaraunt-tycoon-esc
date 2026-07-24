--!strict

-- Зависимости
local StarterPlayer = game:GetService("StarterPlayer")
require(StarterPlayer.StarterPlayerScripts.Client.Interaction.FindTargerInteractable)

local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

--
-- Взаимодействие с миром
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- В режиме перемещения фурнитуры E управляется BuildingClient (установка)
	if State.IsInBuildingMode:get() and State.MovingFurnitureEntity:get() ~= 0 then
		return
	end

	local part = State.TargetInteractable:get()
	if not part then
		return
	end

	if Consts.InteractableAllowedKeys[input.KeyCode] then
		local entityId = part:GetAttribute(Consts.Attributes.EntityId)
		if not entityId then
			return
		end
		NetClient:PlayerInteract(entityId, input.KeyCode)
	end
end)

return {}