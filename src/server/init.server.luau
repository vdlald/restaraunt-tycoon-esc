--!strict

-- Зависимости
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Server.Player.DataManager) -- грузим первым DataManager
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

local BuildModeSystem = require(ServerScriptService.Server.Game.BuildMode.BuildModeSystem)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

--
-- Login
local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)
	WorldWrapper:RegisterPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	local playerView = WorldWrapper:FindPlayer(playerId)
	if playerView then
		BuildModeSystem:CancelCarry(playerView)
		if world:has(playerId, WorldWrapper:GetBuildModeActiveComponent()) then
			world:remove(playerId, WorldWrapper:GetBuildModeActiveComponent())
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
		if not playerId then
			return
		end

		local playerView = WorldWrapper:FindPlayer(playerId)
		if playerView then
			BuildModeSystem:CancelCarry(playerView)
		end
	end)
end)

--
-- Serve
local Net = require(ReplicatedStorage.Shared.Net)

-- Обрабатываем взаимодействие пользователя с миром
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

	-- Build mode перехватывает E для перемещения фурнитуры
	if world:has(playerId, WorldWrapper:GetBuildModeActiveComponent()) and keyCode == Enum.KeyCode.E then
		BuildModeSystem:Pickup(playerView, entityId)
		return
	end

	if not world:contains(entityId) then
		warn("suspicious player interaction, unfound entityId=" .. entityId)
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

Net.buildModeSetActive.listen(function(data: table, player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	local playerView = WorldWrapper:FindPlayer(playerId)
	if not playerView then
		return
	end

	BuildModeSystem:SetActive(playerView, data.active)
end)

Net.buildModePlace.listen(function(data: table, player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	local playerView = WorldWrapper:FindPlayer(playerId)
	if not playerView then
		return
	end

	BuildModeSystem:Place(playerView, data.cframe)
end)

-- Синхронизируем изменения данных пользователя
DataManager:OnProfileDataChanged(function(event: DataManager.PlayerDataChangedEvent)
	local player = event.Player
	local playerData = event.Data

	Net.playerDataUpdate.sendTo({
		coins = playerData.CoinsEarned - playerData.CoinsSpend,
	}, player)
end)

--
-- Системы
local RunService = game:GetService("RunService")
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)

local GuestNpc = require(ServerScriptService.Server.Game.Npc.Guest)

local Flour = require(ServerScriptService.Server.Game.Ingredient.Flour)
local Dough = require(ServerScriptService.Server.Game.Ingredient.Dough)
local RawPie = require(ServerScriptService.Server.Game.Ingredient.RawPie)

local RawMeatSteak = require(ServerScriptService.Server.Game.Ingredient.RawMeatSteak)
local ChoppedMeat = require(ServerScriptService.Server.Game.Ingredient.ChoppedMeat)
local MinceMeat = require(ServerScriptService.Server.Game.Ingredient.MinceMeat)

local Pie = require(ServerScriptService.Server.Game.Dish.Pie)

local Plate = require(ServerScriptService.Server.Game.Items.Plate)

local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local MeatSteakFridge = require(ServerScriptService.Server.Game.Furniture.MeatSteakFridge)
local KitchenTable = require(ServerScriptService.Server.Game.Furniture.KitchenTable)
local Trashcan = require(ServerScriptService.Server.Game.Furniture.Trashcan)

RunService.Heartbeat:Connect(function(deltaTime)
	-- start phase
	PlayerInteractSystem:Process(deltaTime)
	BuildModeSystem:Process(deltaTime)

	-- NPC
	GuestNpc.System:Process(deltaTime)

	-- Фурнитура
	Trashcan.System:Process(deltaTime)
	FlourBag.System:Process(deltaTime)
	MeatSteakFridge.System:Process(deltaTime)

	-- Ингредиенты
	Flour.System:Process(deltaTime)
	Dough.System:Process(deltaTime)
	RawPie.System:Process(deltaTime)

	RawMeatSteak.System:Process(deltaTime)
	ChoppedMeat.System:Process(deltaTime)
	MinceMeat.System:Process(deltaTime)

	Pie.System:Process(deltaTime)

	-- end phase
	PlaceHolder.System:Process(deltaTime)

	-- clear
	PlayerInteractSystem:Clear()
end)

--
-- Инициализация мира
local _, trashcanInstance = Trashcan.Create()
trashcanInstance.Parent = workspace
trashcanInstance:SetPrimaryPartCFrame(CFrame.new(Vector3.new(10, 1.5, 3)))

local _, flourBagInstance = FlourBag.Create()
flourBagInstance.Parent = workspace
flourBagInstance:SetPrimaryPartCFrame(CFrame.new(Vector3.new(4, 1.5, 3)))

local _, fridgeInstance = MeatSteakFridge.Create()
fridgeInstance.Parent = workspace
fridgeInstance:SetPrimaryPartCFrame(CFrame.new(Vector3.new(7, 2.5, 0)))

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
local plateEntity1, plateInstance1, platePH1 = Plate.Create()
plateInstance1.Parent = workspace
PlaceHolder.System:Place(placeHolderEntity3, plateEntity1)

local plateEntity2, plateInstance2, platePH2 = Plate.Create()
plateInstance2.Parent = workspace
PlaceHolder.System:Place(platePH1, plateEntity2)

local plateEntity3, plateInstance3, platePH3 = Plate.Create()
plateInstance3.Parent = workspace
PlaceHolder.System:Place(platePH2, plateEntity3)

-- Npc
local guestEntity, guestInstance = GuestNpc.Create()
guestInstance.Parent = workspace
