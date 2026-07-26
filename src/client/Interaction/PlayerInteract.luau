--!strict

-- Зависимости
local StarterPlayer = game:GetService("StarterPlayer")
require(StarterPlayer.StarterPlayerScripts.Client.Interaction.FindTargerInteractable)

local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)
local GamePhase = require(ReplicatedStorage.Shared.GamePhase)
local PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)

--
-- Взаимодействие с миром
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local activeIngredientProcessEntity: number? = nil

local function requestMatchStart()
	if
		PlaceConfig:IsLobbyPlace(game.PlaceId) or (RunService:IsStudio() and State.GamePhase:get() == GamePhase.Lobby)
	then
		NetClient:StartPartyMatch()
	else
		NetClient:RequestGamePhaseToggle()
	end
end

local function stopIngredientProcess()
	if not activeIngredientProcessEntity then
		return
	end
	NetClient:StopIngredientProcess()
	activeIngredientProcessEntity = nil
end

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
	if input.KeyCode == Enum.KeyCode.F then
		local entityId = part:GetAttribute(Consts.Attributes.EntityId)
		if entityId then
			activeIngredientProcessEntity = entityId
			NetClient:StartIngredientProcess(entityId)
		end
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

ContextActionService:BindActionAtPriority("StartMatch", function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin or UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end
	requestMatchStart()
	return Enum.ContextActionResult.Sink
end, false, 2_000, Enum.KeyCode.P)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		stopIngredientProcess()
	end
end)

UserInputService.WindowFocusReleased:Connect(stopIngredientProcess)

State.IsInBuildingMode:on(function(isInBuildingMode: boolean)
	if isInBuildingMode then
		stopIngredientProcess()
	end
end)

return {}
