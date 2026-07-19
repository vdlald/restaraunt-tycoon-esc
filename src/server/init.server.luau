-- Зависимости
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

-- Login
local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)
	WorldWrapper:RegisterPlayer(player)
end)

-- Serve
local Net = require(ReplicatedStorage.Shared.Net)

Net.playerInteract.listen(function(data: table, player: Player)
	local entityId: number = data.entityId
	local keyCode = Enum.KeyCode:FromValue(data.keyCode)

	-- anti-cheat validations
	if not Consts.InteractableAllowedKeys[keyCode] then
		warn("suspicious player interaction: userId=" .. player.UserId .. ", keyCode=" .. keyCode)
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		error("playerId not found")
		return
	end

	local playerView: Types.PlayerView? = WorldWrapper:FindPlayer(playerId)
	if not playerView then
		error("unknown userId=" .. player.UserId)
		return
	end

	if not world:has(entityId, WorldWrapper:GetPlayerInteractableComponent()) then
		warn("suspicious player interaction, not interactable view: userId=" .. player.UserId)
		return
	end

	if ObjectPool:IsPooled(entityId) then
		warn("suspicious player interaction, interact with pooled view: userId=" .. player.UserId)
		return
	end

	local instance = WorldWrapper:FindInstance(entityId)
	if not instance then
		warn("suspicious player interaction, unknown view: userId=" .. player.UserId .. ", entityId=" .. entityId)
		return
	end

	if instance.Parent == nil then
		warn("suspicious player interaction, view is dead? userId=" .. player.UserId)
		return
	end

	local distance = playerView:GetDistance(instance)
	if distance > Consts.InteractablePlayerDistance + 4 then
		warn("suspicious player interaction, too far: userId=" .. player.UserId .. ", distance=" .. distance)
		return
	end

	-- game specific validations
	world:set(playerId, WorldWrapper:GetWantsToInteractComponent(), { Target = entityId, KeyCode = keyCode })
end)

-- Системы
local RunService = game:GetService("RunService")
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)

local Flour = require(ServerScriptService.Server.Game.Ingridient.Flour)
local Dough = require(ServerScriptService.Server.Game.Ingridient.Dough)
local RawPie = require(ServerScriptService.Server.Game.Ingridient.RawPie)

local Plate = require(ServerScriptService.Server.Game.Items.Plate)

local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local KitchenTable = require(ServerScriptService.Server.Game.Furniture.KitchenTable)

RunService.Heartbeat:Connect(function(deltaTime)
	-- start phase
	PlayerInteractSystem:Process(deltaTime)

	-- middle phase
	FlourBag.System:Process(deltaTime)

	Flour.System:Process(deltaTime)
	Dough.System:Process(deltaTime)
	RawPie.System:Process(deltaTime)

	-- end phase
	PlaceHolder.System:Process(deltaTime)
end)

--
-- Инициализация мира
local _, flourBagInstance = FlourBag.Create()
flourBagInstance.Parent = workspace
flourBagInstance:SetPrimaryPartCFrame(CFrame.new(Vector3.new(3, 1, -2)))

local _, kitchenTableInstance1, _ = KitchenTable.Create()
kitchenTableInstance1.Parent = workspace
kitchenTableInstance1:SetPrimaryPartCFrame(CFrame.new(Vector3.new(-6, 1.5, -3)))

local _, kitchenTableInstance2, _ = KitchenTable.Create()
kitchenTableInstance2.Parent = workspace
kitchenTableInstance2:SetPrimaryPartCFrame(CFrame.new(Vector3.new(-1, 1.5, -3)))

local _, kitchenTableInstance3, placeHolderEntity3 = KitchenTable.Create()
kitchenTableInstance3.Parent = workspace
kitchenTableInstance3:SetPrimaryPartCFrame(CFrame.new(Vector3.new(6, 1.5, -3)))

-- Тарелки
local plateEntity1, _, platePH1 = Plate.Create()
world:set(placeHolderEntity3, PlaceHolder.PlaceCommand, { TargetEntity = plateEntity1 })

-- local plateEntity2, _, platePH2 = Plate.Create()
-- world:set(platePH1, PlaceHolder.PlaceCommand, { TargetEntity = plateEntity2 })

-- local plateEntity3, _, platePH3 = Plate.Create()
-- world:set(platePH2, PlaceHolder.PlaceCommand, { TargetEntity = plateEntity3 })

-- local plateEntity4, _, platePH4 = Plate.Create()
-- world:set(platePH3, PlaceHolder.PlaceCommand, { TargetEntity = plateEntity4 })

