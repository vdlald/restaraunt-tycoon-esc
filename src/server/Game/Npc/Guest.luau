--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Utils = require(ReplicatedStorage.Shared.Utils)

local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local Types = require(ServerScriptService.Server.Types)
local World = require(ServerScriptService.Server.World)
export type GuestState = "Arriving" | "WaitingForService" | "Leaving"
export type GuestNpcComponent = jecs.Id<{
	State: GuestState,
	MovementId: number,
	MovementStarted: boolean,
}>

type DishFactoryContract = {
	GetAbstractDishComponent: (self: DishFactoryContract) -> jecs.Id<nil>,
}

type GuestContext = {
	worldWrapper: World.GameWorld,
	world: jecs.World,
	dishFactory: DishFactoryContract,
	component: GuestNpcComponent,
	onFed: (Player, jecs.Entity<nil>, jecs.Entity<nil>) -> number?,
	onExited: (jecs.Entity<nil>) -> (),
}

local SpawnPosition = Vector3.new(-12, 0, 0)
local ServicePosition = Vector3.new(0, 0, 0)
local ExitPosition = Vector3.new(12, 0, 0)
local MaxPathAttempts = 3

local defaultOnFed: (Player, jecs.Entity<nil>, jecs.Entity<nil>) -> number? = function(
	_: Player,
	_: jecs.Entity<nil>,
	_: jecs.Entity<nil>
)
	return nil
end

local defaultOnExited: (jecs.Entity<nil>) -> () = function(_: jecs.Entity<nil>) end

local function getGuestModel(context: GuestContext, entityId: jecs.Entity<nil>): Model?
	local instance = context.worldWrapper:FindInstance(entityId)
	if instance and instance:IsA("Model") then
		return instance
	end
	return nil
end

local function isMovementCurrent(
	context: GuestContext,
	entityId: jecs.Entity<nil>,
	movementId: number,
	state: GuestState
): boolean
	if not context.world:contains(entityId) then
		return false
	end
	local guestState = context.world:get(entityId, context.component)
	return guestState ~= nil and guestState.MovementId == movementId and guestState.State == state
end

local function finishArrival(context: GuestContext, entityId: jecs.Entity<nil>, movementId: number)
	if not isMovementCurrent(context, entityId, movementId, "Arriving") then
		return
	end

	context.world:set(entityId, context.component, {
		State = "WaitingForService",
		MovementId = movementId,
		MovementStarted = true,
	})
	context.world:set(entityId, context.worldWrapper:GetPlayerInteractableComponent())
end

local function finishExit(context: GuestContext, entityId: jecs.Entity<nil>, movementId: number)
	if not isMovementCurrent(context, entityId, movementId, "Leaving") then
		return
	end

	local guest = context.worldWrapper:FindInstance(entityId)
	if guest then
		guest.Parent = nil
	end
	context.onExited(entityId)
end

local function moveGuest(
	context: GuestContext,
	entityId: jecs.Entity<nil>,
	movementId: number,
	state: GuestState,
	destination: Vector3
)
	task.spawn(function()
		local guest = getGuestModel(context, entityId)
		if not guest then
			warn(`Guest {entityId} is not a Model`)
			return
		end
		local humanoid = guest:FindFirstChildWhichIsA("Humanoid", true)
		local rootPart = guest:FindFirstChild("HumanoidRootPart", true)
		if not humanoid or not rootPart or not rootPart:IsA("BasePart") then
			warn(`Guest {entityId} must contain Humanoid and HumanoidRootPart`)
			return
		end
		pcall(function()
			rootPart:SetNetworkOwner(nil)
		end)

		for _ = 1, MaxPathAttempts do
			if not isMovementCurrent(context, entityId, movementId, state) then
				return
			end

			local path = PathfindingService:CreatePath()
			local computed = pcall(function()
				path:ComputeAsync(rootPart.Position, destination)
			end)
			if computed and path.Status == Enum.PathStatus.Success then
				local blocked = false
				local blockedConnection = path.Blocked:Connect(function()
					blocked = true
				end)
				local reachedDestination = true
				for _, waypoint in path:GetWaypoints() do
					if not isMovementCurrent(context, entityId, movementId, state) then
						blockedConnection:Disconnect()
						return
					end
					if waypoint.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end
					humanoid:MoveTo(waypoint.Position)
					if not humanoid.MoveToFinished:Wait() or blocked then
						reachedDestination = false
						break
					end
				end
				blockedConnection:Disconnect()
				if reachedDestination then
					if state == "Arriving" then
						finishArrival(context, entityId, movementId)
					else
						finishExit(context, entityId, movementId)
					end
					return
				end
			end
		end

		if not isMovementCurrent(context, entityId, movementId, state) then
			return
		end
		warn(`Guest {entityId} could not build a path; using direct movement`)
		humanoid:MoveTo(destination)
		if humanoid.MoveToFinished:Wait() then
			if state == "Arriving" then
				finishArrival(context, entityId, movementId)
			else
				finishExit(context, entityId, movementId)
			end
		end
	end)
end

local System = Class.defineClass("System", AbstractSystem)

function System.new(worldContext: World.GameWorld, context: GuestContext)
	local parent = AbstractSystem.new(worldContext)
	local self = setmetatable(parent, System)
	self.context = context
	self.guestsQuery = self.world:query(context.component):cached()
	return self
end

function System:Process(_: number)
	for entityId, guestState in self.guestsQuery do
		if not guestState.MovementStarted then
			local guest = self.context.worldWrapper:FindInstance(entityId)
			if guest and guest.Parent then
				guestState.MovementStarted = true
				self.world:set(entityId, self.context.component, guestState)
				moveGuest(self.context, entityId, guestState.MovementId, guestState.State, ServicePosition)
			end
		end
	end
end

function System:processPlayerInteract(entityId: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end
	local guestState = self.world:get(entityId, self.context.component)
	if not guestState or guestState.State ~= "WaitingForService" then
		return
	end
	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool or not self.world:has(equippedTool, self.context.dishFactory:GetAbstractDishComponent()) then
		return
	end
	local earned = self.context.onFed(playerView:GetPlayer(), entityId, equippedTool)
	if not earned then
		return
	end

	self.context.worldWrapper:RequestDestroy(equippedTool)
	playerView:TakeFromHands()
	self.world:remove(entityId, self.context.worldWrapper:GetPlayerInteractableComponent())
	self.world:set(entityId, self.context.component, {
		State = "Leaving",
		MovementId = guestState.MovementId + 1,
		MovementStarted = true,
	})
	moveGuest(self.context, entityId, guestState.MovementId + 1, "Leaving", ExitPosition)
end

function System:HandleInteraction(
	entityId: jecs.Entity<nil>,
	playerView: Types.PlayerView,
	keyCode: Enum.KeyCode
): boolean
	if not self.world:has(entityId, self.context.component) then
		return false
	end
	Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
		self:processPlayerInteract(entityId, playerView, keyCode)
	end)
	return true
end

local Guest = {}

function Guest.new(worldContext: World.GameWorld, dishFactory: DishFactoryContract)
	local context: GuestContext = {
		worldWrapper = worldContext,
		world = worldContext:GetWorld(),
		dishFactory = dishFactory,
		component = worldContext:GetWorld():component(),
		onFed = defaultOnFed,
		onExited = defaultOnExited,
	}

	local function createGuestNpc(): (jecs.Entity<nil>, Instance)
		local instance: Instance = ServerStorage.NPC.Guest:Clone()
		if not instance:IsA("Model") then
			error("ServerStorage.NPC.Guest must be a Model")
		end
		local entity = context.worldWrapper:RegisterInstance(instance, "GuestNpc")
		context.world:set(entity, context.component, {
			State = "Arriving",
			MovementId = 0,
			MovementStarted = false,
		})

		instance:PivotTo(CFrame.new(SpawnPosition))
		return entity, instance
	end

	return {
		Create = createGuestNpc,
		Component = context.component,
		System = System.new(worldContext, context),
		SetCallbacks = function(
			onFed: ((Player, jecs.Entity<nil>, jecs.Entity<nil>) -> number?)?,
			onExited: ((jecs.Entity<nil>) -> ())?
		)
			context.onFed = onFed or defaultOnFed
			context.onExited = onExited or defaultOnExited
		end,
		CancelAll = function()
			for entityId, guestState in context.world:query(context.component) do
				context.world:set(entityId, context.component, {
					State = guestState.State,
					MovementId = guestState.MovementId + 1,
					MovementStarted = true,
				})
			end
		end,
	}
end

return Guest
