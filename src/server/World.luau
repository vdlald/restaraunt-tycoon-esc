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
export type InstanceComponent = jecs.Id<{ Instance: Instance }>
local instanceComponent = world:component() :: InstanceComponent

-- Пользователь хочет взаимодействовать
export type WantsToInteractComponent = jecs.Id<{target: jecs.Entity<nil>, KeyCode: Enum.KeyCode}>
local wantsToInteractComponent = world:component() :: WantsToInteractComponent

-- Объявление WorldWrapper
export type WorldWrapper = {
	-- jecks specific
	GetWorld: (self: WorldWrapper) -> jecs.World,
	GetPlayerComponent: (self: WorldWrapper) -> PlayerComponent,
	GetInstanceComponent: (self: WorldWrapper) -> InstanceComponent,
	GetWantsToInteractComponent: (self: WorldWrapper) -> WantsToInteractComponent,

	-- lookup
	FindPlayer: (self: WorldWrapper, playerId: jecs.Entity<nil>) -> Types.PlayerView?,
	FindInstance: (self: WorldWrapper, entityId: jecs.Entity<nil>) -> Instance?,

	-- register
	RegisterPlayer: (self: WorldWrapper, connectedPlayer: Player) -> jecs.Entity<nil>,
	RegisterInstance: (self: WorldWrapper, newInstance: Instance) -> jecs.Entity<nil>,
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

function WorldWrapper:GetWantsToInteractComponent(): WantsToInteractComponent
	return wantsToInteractComponent
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
	connectedPlayer:SetAttribute(Consts.Attributes.EntityId, entity)
	world:set(entity, playerComponent, { Player = connectedPlayer, PlayerView = PlayerView.new(connectedPlayer) })
	return entity
end

function WorldWrapper:RegisterInstance(newInstance: Instance): jecs.Entity<nil>
	local entity = world:entity()
	newInstance:SetAttribute(Consts.Attributes.PlayerId, entity)
	world:set(entity, instanceComponent, { Instance = newInstance })
	return entity
end

return WorldWrapper :: WorldWrapper
