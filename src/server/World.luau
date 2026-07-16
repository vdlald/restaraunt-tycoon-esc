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

-- Пользователь хочет взаимодействовать, позволяет провалидировать возможность взаимодействия
export type WantsToInteractComponent = jecs.Id<{ target: jecs.Entity<nil>, KeyCode: Enum.KeyCode }>
local wantsToInteractComponent = world:component() :: WantsToInteractComponent

-- Instance получил запрос на взаимодействие
export type PlayerInteractComponent = jecs.Id<{ PlayerView: Types.PlayerView, KeyCode: Enum.KeyCode }>
local playerInteractComponent = world:component() :: PlayerInteractComponent

--
-- Объявление WorldWrapper
--
export type WorldWrapper = {
	-- jecks specific
	GetWorld: (self: WorldWrapper) -> jecs.World,

	GetPlayerComponent: (self: WorldWrapper) -> PlayerComponent,
	GetInstanceComponent: (self: WorldWrapper) -> InstanceComponent,

	GetPlayerInteractComponent: (self: WorldWrapper) -> PlayerInteractComponent,
	GetWantsToInteractComponent: (self: WorldWrapper) -> WantsToInteractComponent,

	GetPlayerInteractableComponent: (self: WorldWrapper) -> PlayerInteractableComponent,

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

function WorldWrapper:GetPlayerInteractComponent(): PlayerInteractComponent
	return playerInteractComponent
end

function WorldWrapper:GetWantsToInteractComponent(): WantsToInteractComponent
	return wantsToInteractComponent
end

function WorldWrapper:GetPlayerInteractableComponent(): PlayerInteractableComponent
	return playerInteractableComponent
end

function WorldWrapper:FindPlayer(playerId: jecs.Entity<nil>): Types.PlayerView?
	local componentData: Types.PlayerView = world:get(playerId, playerComponent)
	if not componentData then
		return nil
	end
	return componentData.PlayerView
end

function WorldWrapper:FindInstance(entityId: jecs.Entity<nil>): Instance?
	local componentData: Instance = world:get(entityId, instanceComponent)
	if not componentData then
		return nil
	end
	return componentData.Instance
end

function WorldWrapper:RegisterPlayer(connectedPlayer: Player): jecs.Entity<nil>
	local entity = world:entity()
	connectedPlayer:SetAttribute(Consts.Attributes.PlayerId, entity)
	world:set(entity, playerComponent, { Player = connectedPlayer, PlayerView = PlayerView.new(connectedPlayer) })
	return entity
end

function WorldWrapper:RegisterInstance(newInstance: Instance, class: string): jecs.Entity<nil>
	local entity = world:entity()
	newInstance:SetAttribute(Consts.Attributes.EntityId, entity)
	world:set(entity, instanceComponent, { Instance = newInstance, Class = class})
	return entity
end

return WorldWrapper :: WorldWrapper
