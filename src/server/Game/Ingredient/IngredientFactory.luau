--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)
local Net = require(ReplicatedStorage.Shared.Net)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local ObjectPool = require(ServerScriptService.Server.ObjectPool)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- IngredientForm
export type IngredientForm = {
	IngredientName: string,
	Template: Tool,
	HandsMorphFunc: ((jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance))?, -- функция превращения из одного ингредиента в другой
	ProcessDurationSeconds: number?,
}

--
-- Обработчик
local IngredientSystem = Class.defineClass("IngredientSystem", AbstractSystem)

function IngredientSystem.new(
	ingredientPool, -- пул объектов
	ingredientComponent, -- система для компонента
	handsMorphFunc: ((jecs.Entity<nil>) -> (jecs.Entity<nil>, Instance))?,
	processDurationSeconds: number
): AbstractSystem.AbstractSystem
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, IngredientSystem)

	self.ingredientPool = ingredientPool
	self.ingredientComponent = ingredientComponent
	self.handsMorphFunc = handsMorphFunc
	self.processDurationSeconds = processDurationSeconds
	self.stateSyncElapsed = 0

	return self
end

function IngredientSystem:sendProcessState(
	target: jecs.Entity<nil>,
	elapsed: number,
	participantCount: number,
	active: boolean
)
	Net.ingredientProcessState.sendToAll({
		entityId = target,
		progress = math.clamp(elapsed / self.processDurationSeconds, 0, 1),
		participantCount = participantCount,
		active = active,
	})
end

function IngredientSystem:clearParticipants(target: jecs.Entity<nil>)
	self:query(WorldWrapper:GetIngredientProcessingComponent()):forEach(function(playerEntity, processing)
		if not playerEntity then
			return
		end
		if processing.Target == target then
			world:remove(playerEntity, WorldWrapper:GetIngredientProcessingComponent())
		end
		return playerEntity
	end)
end

function IngredientSystem:clearProcessState(target: jecs.Entity<nil>)
	self:clearParticipants(target)
	local progress = world:get(target, WorldWrapper:GetIngredientProgressComponent())
	if progress then
		world:remove(target, WorldWrapper:GetIngredientProgressComponent())
		self:sendProcessState(target, progress.Elapsed, 0, false)
	end
end

function IngredientSystem:isValidParticipant(playerView: Types.PlayerView, target: jecs.Entity<nil>): boolean
	local player = playerView:GetPlayer()
	if player.Parent == nil then
		return false
	end

	local instance = WorldWrapper:FindInstance(target)
	if not instance or instance.Parent == nil then
		return false
	end

	local ok, distance = pcall(function()
		return playerView:GetDistance(instance)
	end)
	return ok and distance <= Consts.InteractablePlayerDistance + 4
end

function IngredientSystem:getParticipantCount(target: jecs.Entity<nil>): number
	local count = 0
	self:query(WorldWrapper:GetPlayerComponent(), WorldWrapper:GetIngredientProcessingComponent())
		:forEach(function(playerEntity, playerComponent, processing)
			if not playerEntity then
				return
			end
			if processing.Target ~= target then
				return playerEntity
			end

			if self:isValidParticipant(playerComponent.PlayerView, target) then
				count += 1
			else
				world:remove(playerEntity, WorldWrapper:GetIngredientProcessingComponent())
			end
			return playerEntity
		end)
	return count
end

function IngredientSystem:processIngredient(target: jecs.Entity<nil>, deltaTime: number, shouldSync: boolean)
	if not self.handsMorphFunc then
		return
	end

	local participantCount = self:getParticipantCount(target)
	local progress = world:get(target, WorldWrapper:GetIngredientProgressComponent())
	if participantCount == 0 then
		if progress and progress.ParticipantCount > 0 then
			world:set(target, WorldWrapper:GetIngredientProgressComponent(), {
				Elapsed = progress.Elapsed,
				ParticipantCount = 0,
			})
			self:sendProcessState(target, progress.Elapsed, 0, true)
		end
		return
	end

	local elapsed = (if progress then progress.Elapsed else 0) + deltaTime * participantCount
	if elapsed >= self.processDurationSeconds then
		local nextEntity, nextInstance = self.handsMorphFunc(target)
		nextInstance.Parent = workspace
		world:set(target, WorldWrapper:GetReplaceTargetComponent(), { NewTarget = nextEntity })
		world:set(target, WorldWrapper:GetReleaseTargetComponent())
		return
	end

	world:set(target, WorldWrapper:GetIngredientProgressComponent(), {
		Elapsed = elapsed,
		ParticipantCount = participantCount,
	})
	if not progress or progress.ParticipantCount ~= participantCount or shouldSync then
		self:sendProcessState(target, elapsed, participantCount, true)
	end
end

function IngredientSystem:Process(deltaTime: number)
	self.stateSyncElapsed += deltaTime
	local shouldSync = self.stateSyncElapsed >= Consts.IngredientProcessStateInterval
	if shouldSync then
		self.stateSyncElapsed = 0
	end

	if self.handsMorphFunc then
		self:query(self.ingredientComponent):forEach(function(entityId)
			if entityId then
				self:processIngredient(entityId, deltaTime, shouldSync)
			end
			return entityId
		end)
	end

	self:query(WorldWrapper:GetReleaseTargetComponent())
		:with(self.ingredientComponent)
		:forEach(function(entityId: jecs.Entity<nil>, _)
			if not entityId then
				return
			end
			world:remove(entityId, WorldWrapper:GetReleaseTargetComponent())
			self.ingredientPool:Release(entityId)
		end)
end

--
-- Фабрика
local IngredientFactory = Class.defineClass("IngredientFactory")

local abstractIngredientComponent = world:component()
local processableIngredientComponent = world:component()

function IngredientFactory:GetAbstractIngredientComponent(): jecs.Id<nil>
	return abstractIngredientComponent
end

function IngredientFactory:GetProcessableIngredientComponent(): jecs.Id<nil>
	return processableIngredientComponent
end

function IngredientFactory:DefineIngredient(ingredientForm: IngredientForm)
	local module = {}

	local ingredientComponent = world:component()

	module.Component = ingredientComponent

	module.Pool = ObjectPool.new(function()
		local instance: Tool = ingredientForm.Template:Clone()
		instance:AddTag(Consts.Tags.Interactable)

		local entity = WorldWrapper:RegisterInstance(instance, ingredientForm.IngredientName)
		world:set(entity, abstractIngredientComponent)
		world:set(entity, ingredientComponent)
		if ingredientForm.HandsMorphFunc then
			world:set(entity, processableIngredientComponent)
		end
		world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

		return entity, instance
	end, 5)

	module.System = IngredientSystem.new(
		module.Pool,
		ingredientComponent,
		ingredientForm.HandsMorphFunc,
		ingredientForm.ProcessDurationSeconds or Consts.IngredientProcessDurationSeconds
	)
	module.Pool:SetReleaseCallback(function(entityId)
		module.System:clearProcessState(entityId)
	end)

	return module
end

return IngredientFactory
