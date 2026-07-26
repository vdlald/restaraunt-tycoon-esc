--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local PlayerView = require(ServerScriptService.Server.Player.PlayerView)

-- Jecs
local jecs = require(ReplicatedStorage.Packages.Jecs)

--
-- Компоненты
--

-- Player
export type PlayerComponent = jecs.Id<{ Player: Player, PlayerView: Types.PlayerView }>

-- Instance
export type InstanceComponent = jecs.Id<{ Instance: Instance, Class: string }>

-- PlayerInteractableComponent
export type PlayerInteractableComponent = jecs.Id<nil>

-- Запросы взаимодействия принадлежат игроку. Очередь не позволяет потерять
-- несколько нажатий до следующего тика симуляции.
export type InteractionRequest = {
	Target: jecs.Entity<nil>,
	KeyCode: Enum.KeyCode,
}
export type InteractionQueueComponent = jecs.Id<{ Requests: { InteractionRequest } }>

-- Instance получил запрос на взаимодействие
-- Игрок удерживает кнопку обработки ингредиента
export type IngredientProcessingComponent = jecs.Id<{ Target: jecs.Entity<nil> }>

-- Накопленный прогресс превращения ингредиента
export type IngredientProgressComponent = jecs.Id<{ Elapsed: number, ParticipantCount: number }>

-- ReplaceTarget
export type ReplaceTargetComponent = jecs.Id<{ NewTarget: jecs.Entity<nil> }>

-- DestroyRequested - запрашивает передачу сущности в EntityLifecycleSystem.
export type DestroyRequestedComponent = jecs.Id<nil>

-- BuildingMode - игрок в режиме строительства
export type BuildingModeComponent = jecs.Id<nil>

-- WantsToToggleBuildingMode - запрос на включение/выключение режима строительства
export type WantsToToggleBuildingModeComponent = jecs.Id<{ Enabled: boolean }>

-- BuildingMovable - фурнитуру можно двигать в режиме строительства
export type BuildingMovableComponent = jecs.Id<nil>

-- BuildingLock - бронирование фурнитуры за игроком
export type BuildingLockComponent = jecs.Id<{ OwnerPlayerEntity: jecs.Entity<nil> }>

-- BuildingMoveState - состояние активного перемещения фурнитуры
export type BuildingMoveStateComponent = jecs.Id<{
	FurnitureEntity: jecs.Entity<nil>,
	GhostInstance: Model,
	OriginalCFrame: CFrame,
	OriginalParent: Instance,
	FloorOffset: number,
	YawOffset: number,
}>

-- BuildingGhostTarget - целевая позиция призрака от клиента
export type BuildingGhostTargetComponent = jecs.Id<{ Position: Vector3 }>

-- PendingFurniturePurchase - временная покупка до подтверждения размещения
export type PendingFurniturePurchaseComponent = jecs.Id<{
	BuyerPlayerEntity: jecs.Entity<nil>,
	FurnitureId: string,
	Price: number,
}>

-- ChildEntities - сущности, жизненный цикл которых принадлежит родителю
export type ChildEntitiesComponent = jecs.Id<{ Entities: { jecs.Entity<nil> } }>

export type WorldWrapper = {
	-- jecks specific
	Ecs: jecs.World,
	Components: Components,
	GetPlayerComponent: (self: WorldWrapper) -> PlayerComponent,
	GetInstanceComponent: (self: WorldWrapper) -> InstanceComponent,

	GetIngredientProcessingComponent: (self: WorldWrapper) -> IngredientProcessingComponent,
	GetIngredientProgressComponent: (self: WorldWrapper) -> IngredientProgressComponent,
	GetInteractionQueueComponent: (self: WorldWrapper) -> InteractionQueueComponent,

	GetPlayerInteractableComponent: (self: WorldWrapper) -> PlayerInteractableComponent,

	GetReplaceTargetComponent: (self: WorldWrapper) -> ReplaceTargetComponent,

	GetDestroyRequestedComponent: (self: WorldWrapper) -> DestroyRequestedComponent,
	RequestDestroy: (self: WorldWrapper, entityId: jecs.Entity<nil>) -> (),
	EnqueueInteraction: (self: WorldWrapper, playerId: jecs.Entity<nil>, request: InteractionRequest) -> (),

	GetBuildingModeComponent: (self: WorldWrapper) -> BuildingModeComponent,
	GetWantsToToggleBuildingModeComponent: (self: WorldWrapper) -> WantsToToggleBuildingModeComponent,
	GetBuildingMovableComponent: (self: WorldWrapper) -> BuildingMovableComponent,
	GetBuildingLockComponent: (self: WorldWrapper) -> BuildingLockComponent,
	GetBuildingMoveStateComponent: (self: WorldWrapper) -> BuildingMoveStateComponent,
	GetBuildingGhostTargetComponent: (self: WorldWrapper) -> BuildingGhostTargetComponent,
	GetPendingFurniturePurchaseComponent: (self: WorldWrapper) -> PendingFurniturePurchaseComponent,
	GetChildEntitiesComponent: (self: WorldWrapper) -> ChildEntitiesComponent,

	-- lookup
	FindPlayer: (self: WorldWrapper, playerId: jecs.Entity<nil>) -> Types.PlayerView?,
	FindInstance: (self: WorldWrapper, entityId: jecs.Entity<nil>) -> Instance?,
	Contains: (self: WorldWrapper, entityId: jecs.Entity<nil>) -> boolean,
	IsPlayerInteractable: (self: WorldWrapper, entityId: jecs.Entity<nil>) -> boolean,
	IsBuildingMovable: (self: WorldWrapper, entityId: jecs.Entity<nil>) -> boolean,
	GetBuildingLockOwner: (self: WorldWrapper, entityId: jecs.Entity<nil>) -> jecs.Entity<nil>?,
	RequestBuildingMode: (self: WorldWrapper, playerId: jecs.Entity<nil>, enabled: boolean) -> (),
	IsBuildingModeEnabled: (self: WorldWrapper, playerId: jecs.Entity<nil>) -> boolean,
	IsBuildingMoveActive: (self: WorldWrapper, playerId: jecs.Entity<nil>) -> boolean,
	SetIngredientProcessing: (self: WorldWrapper, playerId: jecs.Entity<nil>, target: jecs.Entity<nil>) -> (),
	ClearIngredientProcessing: (self: WorldWrapper, playerId: jecs.Entity<nil>) -> (),

	-- register
	RegisterPlayer: (self: WorldWrapper, connectedPlayer: Player) -> jecs.Entity<nil>,
	RegisterInstance: (self: WorldWrapper, newInstance: Instance, class: string) -> jecs.Entity<nil>,
}

export type Components = {
	Player: PlayerComponent,
	Instance: InstanceComponent,
	PlayerInteractable: PlayerInteractableComponent,
	InteractionQueue: InteractionQueueComponent,
	IngredientProcessing: IngredientProcessingComponent,
	IngredientProgress: IngredientProgressComponent,
	ReplaceTarget: ReplaceTargetComponent,
	DestroyRequested: DestroyRequestedComponent,
	BuildingMode: BuildingModeComponent,
	WantsToToggleBuildingMode: WantsToToggleBuildingModeComponent,
	BuildingMovable: BuildingMovableComponent,
	BuildingLock: BuildingLockComponent,
	BuildingMoveState: BuildingMoveStateComponent,
	BuildingGhostTarget: BuildingGhostTargetComponent,
	PendingFurniturePurchase: PendingFurniturePurchaseComponent,
	ChildEntities: ChildEntitiesComponent,
}

-- GameWorld is the preferred name for the instance-owned ECS boundary.
-- WorldWrapper remains as a compatibility type while systems migrate.
export type GameWorld = WorldWrapper

local World = {}

function World.new(): GameWorld
	local world: jecs.World = jecs.world()
	local playerComponent = world:component() :: PlayerComponent
	local instanceComponent = world:component() :: InstanceComponent
	local playerInteractableComponent = world:component() :: PlayerInteractableComponent
	local interactionQueueComponent = world:component() :: InteractionQueueComponent
	local ingredientProcessingComponent = world:component() :: IngredientProcessingComponent
	local ingredientProgressComponent = world:component() :: IngredientProgressComponent
	local replaceTargetComponent = world:component() :: ReplaceTargetComponent
	local destroyRequestedComponent = world:component() :: DestroyRequestedComponent
	local buildingModeComponent = world:component() :: BuildingModeComponent
	local wantsToToggleBuildingModeComponent = world:component() :: WantsToToggleBuildingModeComponent
	local buildingMovableComponent = world:component() :: BuildingMovableComponent
	local buildingLockComponent = world:component() :: BuildingLockComponent
	local buildingMoveStateComponent = world:component() :: BuildingMoveStateComponent
	local buildingGhostTargetComponent = world:component() :: BuildingGhostTargetComponent
	local pendingFurniturePurchaseComponent = world:component() :: PendingFurniturePurchaseComponent
	local childEntitiesComponent = world:component() :: ChildEntitiesComponent

	local function setPresentationTag(entityId: jecs.Entity<nil>, tag: string, enabled: boolean)
		local instanceData = world:get(entityId, instanceComponent)
		if not instanceData then
			return
		end
		if enabled then
			instanceData.Instance:AddTag(tag)
		else
			instanceData.Instance:RemoveTag(tag)
		end
	end

	world:set(playerInteractableComponent, jecs.OnAdd, function(entity)
		setPresentationTag(entity, Consts.Tags.Interactable, true)
	end)
	world:set(playerInteractableComponent, jecs.OnRemove, function(entity)
		setPresentationTag(entity, Consts.Tags.Interactable, false)
	end)
	world:set(buildingMovableComponent, jecs.OnAdd, function(entity)
		setPresentationTag(entity, Consts.Tags.BuildingMoveable, true)
	end)
	world:set(buildingMovableComponent, jecs.OnRemove, function(entity)
		setPresentationTag(entity, Consts.Tags.BuildingMoveable, false)
	end)

	local WorldWrapper = {}
	WorldWrapper.world = world
	WorldWrapper.Ecs = world
	WorldWrapper.Components = {
		Player = playerComponent,
		Instance = instanceComponent,
		PlayerInteractable = playerInteractableComponent,
		InteractionQueue = interactionQueueComponent,
		IngredientProcessing = ingredientProcessingComponent,
		IngredientProgress = ingredientProgressComponent,
		ReplaceTarget = replaceTargetComponent,
		DestroyRequested = destroyRequestedComponent,
		BuildingMode = buildingModeComponent,
		WantsToToggleBuildingMode = wantsToToggleBuildingModeComponent,
		BuildingMovable = buildingMovableComponent,
		BuildingLock = buildingLockComponent,
		BuildingMoveState = buildingMoveStateComponent,
		BuildingGhostTarget = buildingGhostTargetComponent,
		PendingFurniturePurchase = pendingFurniturePurchaseComponent,
		ChildEntities = childEntitiesComponent,
	}

	-- Функции
	function WorldWrapper:GetPlayerComponent(): PlayerComponent
		return playerComponent
	end

	function WorldWrapper:GetInstanceComponent(): InstanceComponent
		return instanceComponent
	end

	function WorldWrapper:GetIngredientProcessingComponent(): IngredientProcessingComponent
		return ingredientProcessingComponent
	end

	function WorldWrapper:GetIngredientProgressComponent(): IngredientProgressComponent
		return ingredientProgressComponent
	end

	function WorldWrapper:GetInteractionQueueComponent(): InteractionQueueComponent
		return interactionQueueComponent
	end

	function WorldWrapper:GetPlayerInteractableComponent(): PlayerInteractableComponent
		return playerInteractableComponent
	end

	function WorldWrapper:GetReplaceTargetComponent(): ReplaceTargetComponent
		return replaceTargetComponent
	end

	function WorldWrapper:GetDestroyRequestedComponent(): DestroyRequestedComponent
		return destroyRequestedComponent
	end

	function WorldWrapper:RequestDestroy(entityId: jecs.Entity<nil>)
		world:set(entityId, destroyRequestedComponent)
	end

	function WorldWrapper:EnqueueInteraction(playerId: jecs.Entity<nil>, request: InteractionRequest)
		local queue = world:get(playerId, interactionQueueComponent)
		local requests = if queue then table.clone(queue.Requests) else {}
		if #requests >= Consts.MaxQueuedInteractionRequests then
			return
		end
		table.insert(requests, request)
		world:set(playerId, interactionQueueComponent, { Requests = requests })
	end

	function WorldWrapper:GetBuildingModeComponent(): BuildingModeComponent
		return buildingModeComponent
	end

	function WorldWrapper:GetWantsToToggleBuildingModeComponent(): WantsToToggleBuildingModeComponent
		return wantsToToggleBuildingModeComponent
	end

	function WorldWrapper:GetBuildingMovableComponent(): BuildingMovableComponent
		return buildingMovableComponent
	end

	function WorldWrapper:GetBuildingLockComponent(): BuildingLockComponent
		return buildingLockComponent
	end

	function WorldWrapper:GetBuildingMoveStateComponent(): BuildingMoveStateComponent
		return buildingMoveStateComponent
	end

	function WorldWrapper:GetBuildingGhostTargetComponent(): BuildingGhostTargetComponent
		return buildingGhostTargetComponent
	end

	function WorldWrapper:GetPendingFurniturePurchaseComponent(): PendingFurniturePurchaseComponent
		return pendingFurniturePurchaseComponent
	end

	function WorldWrapper:GetChildEntitiesComponent(): ChildEntitiesComponent
		return childEntitiesComponent
	end

	function WorldWrapper:FindPlayer(playerId: jecs.Entity<nil>): Types.PlayerView?
		local componentData: Types.PlayerView = world:get(playerId, playerComponent)
		if not componentData then
			return nil
		end
		return componentData.PlayerView
	end

	function WorldWrapper:FindInstance(entityId: jecs.Entity<nil>): Instance?
		local componentData = world:get(entityId, instanceComponent)
		if not componentData then
			return nil
		end
		return componentData.Instance
	end

	function WorldWrapper:Contains(entityId: jecs.Entity<nil>): boolean
		return world:contains(entityId)
	end

	function WorldWrapper:IsPlayerInteractable(entityId: jecs.Entity<nil>): boolean
		return world:has(entityId, playerInteractableComponent)
	end

	function WorldWrapper:IsBuildingMovable(entityId: jecs.Entity<nil>): boolean
		return world:has(entityId, buildingMovableComponent)
	end

	function WorldWrapper:GetBuildingLockOwner(entityId: jecs.Entity<nil>): jecs.Entity<nil>?
		local lock = world:get(entityId, buildingLockComponent)
		return if lock then lock.OwnerPlayerEntity else nil
	end

	function WorldWrapper:RequestBuildingMode(playerId: jecs.Entity<nil>, enabled: boolean)
		world:set(playerId, wantsToToggleBuildingModeComponent, { Enabled = enabled })
	end

	function WorldWrapper:IsBuildingModeEnabled(playerId: jecs.Entity<nil>): boolean
		return world:has(playerId, buildingModeComponent)
	end

	function WorldWrapper:IsBuildingMoveActive(playerId: jecs.Entity<nil>): boolean
		return world:has(playerId, buildingMoveStateComponent)
	end

	function WorldWrapper:SetIngredientProcessing(playerId: jecs.Entity<nil>, target: jecs.Entity<nil>)
		world:set(playerId, ingredientProcessingComponent, { Target = target })
	end

	function WorldWrapper:ClearIngredientProcessing(playerId: jecs.Entity<nil>)
		world:remove(playerId, ingredientProcessingComponent)
	end

	function WorldWrapper:RegisterPlayer(connectedPlayer: Player): jecs.Entity<nil>
		local entity = world:entity()
		connectedPlayer:SetAttribute(Consts.Attributes.PlayerId, entity)
		world:set(entity, playerComponent, {
			Player = connectedPlayer,
			PlayerView = PlayerView.new(connectedPlayer),
		})
		return entity
	end

	function WorldWrapper:RegisterInstance(newInstance: Instance, class: string): jecs.Entity<nil>
		local entity = world:entity()
		newInstance:SetAttribute(Consts.Attributes.EntityId, entity)
		world:set(entity, instanceComponent, { Instance = newInstance, Class = class })
		return entity
	end

	return WorldWrapper :: GameWorld
end

return World
