--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local PlayerView = require(ServerScriptService.Server.Player.PlayerView)

-- Jecs
local jecs = require(ReplicatedStorage.Packages.Jecs)
local world: jecs.World = jecs.world()

--
-- Компоненты
--

-- Player
export type PlayerComponent = jecs.Id<{ Player: Player, PlayerView: Types.PlayerView }>
local playerComponent = world:component() :: PlayerComponent

-- Instance
export type InstanceComponent = jecs.Id<{ Instance: Instance, Class: string }>
local instanceComponent = world:component() :: InstanceComponent

-- PlayerInteractableComponent
export type PlayerInteractableComponent = jecs.Id<nil>
local playerInteractableComponent = world:component() :: PlayerInteractableComponent

-- Запросы взаимодействия принадлежат игроку. Очередь не позволяет потерять
-- несколько нажатий до следующего тика симуляции.
export type InteractionRequest = {
	Target: jecs.Entity<nil>,
	KeyCode: Enum.KeyCode,
}
export type InteractionQueueComponent = jecs.Id<{ Requests: { InteractionRequest } }>
local interactionQueueComponent = world:component() :: InteractionQueueComponent

-- Instance получил запрос на взаимодействие
-- Игрок удерживает кнопку обработки ингредиента
export type IngredientProcessingComponent = jecs.Id<{ Target: jecs.Entity<nil> }>
local ingredientProcessingComponent = world:component() :: IngredientProcessingComponent

-- Накопленный прогресс превращения ингредиента
export type IngredientProgressComponent = jecs.Id<{ Elapsed: number, ParticipantCount: number }>
local ingredientProgressComponent = world:component() :: IngredientProgressComponent

-- ReplaceTarget
export type ReplaceTargetComponent = jecs.Id<{ NewTarget: jecs.Entity<nil> }>
local replaceTargetComponent = world:component() :: ReplaceTargetComponent

-- DestroyRequested - запрашивает передачу сущности в EntityLifecycleSystem.
export type DestroyRequestedComponent = jecs.Id<nil>
local destroyRequestedComponent = world:component() :: DestroyRequestedComponent

-- BuildingMode - игрок в режиме строительства
export type BuildingModeComponent = jecs.Id<nil>
local buildingModeComponent = world:component() :: BuildingModeComponent

-- WantsToToggleBuildingMode - запрос на включение/выключение режима строительства
export type WantsToToggleBuildingModeComponent = jecs.Id<{ Enabled: boolean }>
local wantsToToggleBuildingModeComponent = world:component() :: WantsToToggleBuildingModeComponent

-- BuildingMovable - фурнитуру можно двигать в режиме строительства
export type BuildingMovableComponent = jecs.Id<nil>
local buildingMovableComponent = world:component() :: BuildingMovableComponent

-- BuildingLock - бронирование фурнитуры за игроком
export type BuildingLockComponent = jecs.Id<{ OwnerPlayerEntity: jecs.Entity<nil> }>
local buildingLockComponent = world:component() :: BuildingLockComponent

-- BuildingMoveState - состояние активного перемещения фурнитуры
export type BuildingMoveStateComponent = jecs.Id<{
	FurnitureEntity: jecs.Entity<nil>,
	GhostInstance: Model,
	OriginalCFrame: CFrame,
	OriginalParent: Instance,
	FloorOffset: number,
	YawOffset: number,
}>
local buildingMoveStateComponent = world:component() :: BuildingMoveStateComponent

-- BuildingGhostTarget - целевая позиция призрака от клиента
export type BuildingGhostTargetComponent = jecs.Id<{ Position: Vector3 }>
local buildingGhostTargetComponent = world:component() :: BuildingGhostTargetComponent

-- PendingFurniturePurchase - временная покупка до подтверждения размещения
export type PendingFurniturePurchaseComponent = jecs.Id<{
	BuyerPlayerEntity: jecs.Entity<nil>,
	FurnitureId: string,
	Price: number,
}>
local pendingFurniturePurchaseComponent = world:component() :: PendingFurniturePurchaseComponent

-- ChildEntities - сущности, жизненный цикл которых принадлежит родителю
export type ChildEntitiesComponent = jecs.Id<{ Entities: { jecs.Entity<nil> } }>
local childEntitiesComponent = world:component() :: ChildEntitiesComponent

-- Presentation tags are projections of ECS capabilities. Gameplay reads the
-- components; tags only expose those capabilities to Roblox clients.
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

--
-- Объявление WorldWrapper
--
export type WorldWrapper = {
	-- jecks specific
	GetWorld: (self: WorldWrapper) -> jecs.World,

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

	-- register
	RegisterPlayer: (self: WorldWrapper, connectedPlayer: Player) -> jecs.Entity<nil>,
	RegisterInstance: (self: WorldWrapper, newInstance: Instance, class: string) -> jecs.Entity<nil>,
}

local WorldWrapper = {}
WorldWrapper.world = world

-- Функции
function WorldWrapper:GetWorld(): jecs.World
	return self.world
end

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

return WorldWrapper :: WorldWrapper
