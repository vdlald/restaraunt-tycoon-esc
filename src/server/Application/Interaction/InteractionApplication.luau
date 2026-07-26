--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local jecs = require(ReplicatedStorage.Packages.Jecs)
local Consts = require(ReplicatedStorage.Shared.Consts)
local World = require(ServerScriptService.Server.World)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)

type GameplayCatalog = {
	IsPooled: (self: GameplayCatalog, entityId: jecs.Entity<nil>) -> boolean,
}

local InteractionApplication = {}
InteractionApplication.__index = InteractionApplication

export type InteractionApplication = {
	worldWrapper: World.GameWorld,
	gameCycle: typeof(GameCycle.new()),
	catalog: GameplayCatalog,
	RequestInteraction: (self: InteractionApplication, player: Player, entityId: number, keyCodeValue: number) -> (),
}

function InteractionApplication.new(
	worldWrapper: World.GameWorld,
	gameCycle: typeof(GameCycle.new()),
	catalog: GameplayCatalog
): InteractionApplication
	return setmetatable({
		worldWrapper = worldWrapper,
		gameCycle = gameCycle,
		catalog = catalog,
	}, InteractionApplication) :: InteractionApplication
end

function InteractionApplication:RequestInteraction(player: Player, entityId: number, keyCodeValue: number)
	local keyCode = Enum.KeyCode:FromValue(keyCodeValue)
	if not Consts.InteractableAllowedKeys[keyCode] then
		warn("suspicious player interaction: userId=" .. player.UserId .. ", keyCode=" .. keyCode)
		return
	end

	local playerId = player:GetAttribute(Consts.Attributes.PlayerId)
	if not playerId then
		error("playerId not found")
		return
	end

	local playerView = self.worldWrapper:FindPlayer(playerId)
	if not playerView then
		error("unknown userId=" .. player.UserId)
		return
	end
	if not self.gameCycle:CanInteract() or not self.worldWrapper:Contains(entityId) then
		return
	end
	if not self.worldWrapper:IsPlayerInteractable(entityId) and not self.worldWrapper:IsBuildingMovable(entityId) then
		warn("suspicious player interaction, not interactable view: userId=" .. player.UserId)
		return
	end
	if self.catalog:IsPooled(entityId) then
		warn("suspicious player interaction, interact with pooled view: userId=" .. player.UserId)
		return
	end

	local instance = self.worldWrapper:FindInstance(entityId)
	if not instance or instance.Parent == nil then
		warn("suspicious player interaction, unknown or dead view: userId=" .. player.UserId)
		return
	end

	local distance = playerView:GetDistance(instance)
	if distance > Consts.InteractablePlayerDistance + 4 then
		local lockOwner = self.worldWrapper:GetBuildingLockOwner(entityId)
		local isPlacing = keyCode == Enum.KeyCode.E and lockOwner == playerId
		if not isPlacing then
			warn("suspicious player interaction, too far: userId=" .. player.UserId .. ", distance=" .. distance)
			return
		end
	end

	self.worldWrapper:EnqueueInteraction(playerId, { Target = entityId, KeyCode = keyCode })
end

return InteractionApplication
