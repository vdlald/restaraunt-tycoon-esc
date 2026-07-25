--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)

if PlaceConfig:IsLobbyPlace(game.PlaceId) then
	require(script.Parent.Party.LobbyServer)
	return
end

-- Зависимости
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Server.Player.DataManager) -- грузим первым DataManager
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local IngredientFactory = require(ServerScriptService.Server.Game.Ingredient.IngredientFactory)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local FurnitureStore = require(ServerScriptService.Server.Game.Furniture.FurnitureStore)
local PartyService = require(ServerScriptService.Server.Party.PartyService)
local PartyServer = require(ServerScriptService.Server.Party.PartyServer)

local Consts = require(ReplicatedStorage.Shared.Consts)

--
-- Login
local Players = game:GetService("Players")
PartyServer:Start()

local matchPartyId: string? = nil
local lastGamePhase = GameCycle.phase
local hasStartedMatch = false
PartyService:SetLeaderChangedHandler(function(party, leaderUserId)
	local leader = Players:GetPlayerByUserId(leaderUserId)
	if leader then
		GameCycle:SetOwner(leader)
	end
	matchPartyId = party.id
end)

Players.PlayerAdded:Connect(function(player)
	local party, reason = PartyService:EnterMatch(player, player:GetJoinData().TeleportData)
	if not party then
		player:Kick(`Invalid match entry ({reason or PartyService.Error.InvalidInvite})`)
		return
	end
	matchPartyId = party.id
	WorldWrapper:RegisterPlayer(player)
	if party.leaderUserId == player.UserId then
		GameCycle:StartNewMatch(player)
	end
	-- ByteNet creates a per-player channel in its own PlayerAdded listener.
	-- Deferring ensures that listener completes before we write to the channel.
	task.defer(function()
		if player.Parent == Players then
			GameCycle:SendState(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	BuildingSystem:CancelMove(playerId)
	world:remove(playerId, WorldWrapper:GetBuildingModeComponent())
	world:remove(playerId, WorldWrapper:GetIngredientProcessingComponent())
	world:delete(playerId)
	player:SetAttribute(Consts.Attributes.PlayerId, nil)
end)

DataManager:OnProfileRemoving(function(player)
	GameCycle:OnPlayerRemoving(player)
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

	if not GameCycle:CanInteract() then
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

Net.ingredientProcessStart.listen(function(data: table, player: Player)
	local entityId: number = data.entityId
	if not GameCycle:CanInteract() or not world:contains(entityId) then
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	if
		not world:has(entityId, IngredientFactory:GetProcessableIngredientComponent())
		or not world:has(entityId, WorldWrapper:GetPlayerInteractableComponent())
		or ObjectPool:IsPooled(entityId)
	then
		return
	end

	local playerView: Types.PlayerView? = WorldWrapper:FindPlayer(playerId)
	local instance = WorldWrapper:FindInstance(entityId)
	if not playerView or not instance or instance.Parent == nil then
		return
	end

	local ok, distance = pcall(function()
		return playerView:GetDistance(instance)
	end)
	if not ok or distance > Consts.InteractablePlayerDistance + 4 then
		return
	end

	world:set(playerId, WorldWrapper:GetIngredientProcessingComponent(), { Target = entityId })
end)

Net.ingredientProcessStop.listen(function(_: table, player: Player)
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	world:remove(playerId, WorldWrapper:GetIngredientProcessingComponent())
end)

-- Режим строительства
Net.buildingModeToggle.listen(function(data: table, player: Player)
	if not GameCycle:CanBuild() then
		return
	end
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
	if not GameCycle:CanBuild() then
		return
	end
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	BuildingSystem:SetGhostTarget(playerId, data.position)
end)

Net.buildingGhostRotate.listen(function(data: table, player: Player)
	if not GameCycle:CanBuild() then
		return
	end
	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		return
	end

	if not world:has(playerId, WorldWrapper:GetBuildingMoveStateComponent()) then
		return
	end

	BuildingSystem:RequestRotation(playerId, data.deltaYaw)
end)

Net.furniturePurchaseRequest.listen(function(data: table, player: Player)
	FurnitureStore:RequestPurchase(player, data.furnitureId)
end)

Net.gamePhaseToggle.listen(function(_: table, player: Player)
	GameCycle:RequestPhaseToggle(player)
end)

Net.endMatchRequest.listen(function(_: table, player: Player)
	GameCycle:RequestEndMatch(player)
end)

-- Синхронизируем изменения данных пользователя
DataManager:OnProfileDataChanged(function(event: DataManager.PlayerDataChangedEvent)
	local player = event.Player
	local playerData = event.Data

	Net.playerDataUpdate.sendTo({
		experience = playerData.ExperienceEarned - playerData.ExperienceSpend,
	}, player)
end)

DataManager:OnProfileLoaded(function(player, playerData)
	Net.playerDataUpdate.sendTo({
		experience = playerData.ExperienceEarned - playerData.ExperienceSpend,
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

local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local MeatSteakFridge = require(ServerScriptService.Server.Game.Furniture.MeatSteakFridge)
local Trashcan = require(ServerScriptService.Server.Game.Furniture.Trashcan)

RunService.Heartbeat:Connect(function(deltaTime)
	GameCycle:Process(deltaTime)
	if matchPartyId then
		if GameCycle.phase == GameCycle.Phase.Preparation or GameCycle.phase == GameCycle.Phase.Service then
			hasStartedMatch = true
		end
		if GameCycle.phase == GameCycle.Phase.Service and lastGamePhase ~= GameCycle.Phase.Service then
			PartyService:SetMatchService(matchPartyId)
		elseif
			hasStartedMatch
			and GameCycle.phase == GameCycle.Phase.Lobby
			and lastGamePhase ~= GameCycle.Phase.Lobby
		then
			PartyService:FinishMatch(matchPartyId)
			matchPartyId = nil
		end
	end
	lastGamePhase = GameCycle.phase
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
