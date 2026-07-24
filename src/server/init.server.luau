--!strict

-- Зависимости
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Server.Player.DataManager) -- грузим первым DataManager
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)
local CollectionService = game:GetService("CollectionService")

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

	BuildingSystem:CancelMove(playerId)
	world:remove(playerId, WorldWrapper:GetBuildingModeComponent())
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

	if not world:contains(entityId) then
		warn("suspicious player interaction, unfound entityId=" .. entityId)
		return
	end

	if
		not world:has(entityId, WorldWrapper:GetPlayerInteractableComponent())
		and not world:has(entityId, WorldWrapper:GetBuildingMovableComponent())
	then
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
		-- Разрешаем превышение дистанции только при установке фурнитуры, которую игрок уже перемещает
		local isPlacing = keyCode == Enum.KeyCode.E
			and world:has(entityId, WorldWrapper:GetBuildingLockComponent())
			and world:get(entityId, WorldWrapper:GetBuildingLockComponent()).OwnerPlayerEntity == playerId

		if not isPlacing then
			warn("suspicious player interaction, too far: userId=" .. player.UserId .. ", distance=" .. distance)
			return
		end
	end

	-- game specific validations
	world:set(playerId, WorldWrapper:GetWantsToInteractComponent(), { Target = entityId, KeyCode = keyCode })
end)

-- Режим строительства
Net.buildingModeToggle.listen(function(data: table, player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	world:set(playerId, WorldWrapper:GetWantsToToggleBuildingModeComponent(), { Enabled = data.enabled })
end)

Net.buildingModeCancelMove.listen(function(_: table, player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	BuildingSystem:CancelMove(playerId)

	local enabled = world:has(playerId, WorldWrapper:GetBuildingModeComponent())
	Net.buildingModeState.sendTo({ enabled = enabled, movingEntity = 0 }, player)
end)

Net.buildingGhostMove.listen(function(data: table, player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	BuildingSystem:SetGhostTarget(playerId, data.position)
end)

Net.buildingGhostRotate.listen(function(data: table, player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	if not world:has(playerId, WorldWrapper:GetBuildingMoveStateComponent()) then
		return
	end

	BuildingSystem:RequestRotation(playerId, data.deltaYaw)
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
	BuildingSystem:Process(deltaTime)

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

-- BuildZone fallback: если в мире нет зоны строительства, создаём большую невидимую площадку
if #CollectionService:GetTagged(Consts.Tags.BuildZone) == 0 then
	local buildZone = Instance.new("Part")
	buildZone.Name = "BuildZone"
	buildZone.Size = Vector3.new(200, 1, 200)
	buildZone.Position = Vector3.new(0, -0.5, 0)
	buildZone.Anchored = true
	buildZone.CanCollide = true
	buildZone.Transparency = 1
	buildZone:AddTag(Consts.Tags.BuildZone)
	buildZone.Parent = workspace
end
