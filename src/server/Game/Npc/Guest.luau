--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Utils = require(ReplicatedStorage.Shared.Utils)

local DataManager = require(ServerScriptService.Server.Player.DataManager)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)
local Types = require(ServerScriptService.Server.Types)
local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

export type GuestState = "Arriving" | "WaitingForService" | "Leaving"
export type GuestNpcComponent = jecs.Id<{
	State: GuestState,
	MovementId: number,
	MovementStarted: boolean,
}>

local GuestNpcComponent = world:component() :: GuestNpcComponent

local SpawnPosition = Vector3.new(-12, 0, 0)
local ServicePosition = Vector3.new(0, 0, 0)
local ExitPosition = Vector3.new(12, 0, 0)
local MaxPathAttempts = 3

local onFed: (Player, jecs.Entity<nil>, jecs.Entity<nil>) -> number? = function(
	_: Player,
	_: jecs.Entity<nil>,
	_: jecs.Entity<nil>
)
	return nil
end

local onExited: (jecs.Entity<nil>) -> () = function(_: jecs.Entity<nil>) end

local function getGuestModel(entityId: jecs.Entity<nil>): Model?
	local instance = WorldWrapper:FindInstance(entityId)
	if instance and instance:IsA("Model") then
		return instance
	end
	return nil
end

local function isMovementCurrent(entityId: jecs.Entity<nil>, movementId: number, state: GuestState): boolean
	if not world:contains(entityId) then
		return false
	end
	local guestState = world:get(entityId, GuestNpcComponent)
	return guestState ~= nil and guestState.MovementId == movementId and guestState.State == state
end

local function finishArrival(entityId: jecs.Entity<nil>, movementId: number)
	if not isMovementCurrent(entityId, movementId, "Arriving") then
		return
	end

	world:set(entityId, GuestNpcComponent, {
		State = "WaitingForService",
		MovementId = movementId,
		MovementStarted = true,
	})
	local guest = WorldWrapper:FindInstance(entityId)
	if guest then
		guest:AddTag("Interactable")
	end
	world:set(entityId, WorldWrapper:GetPlayerInteractableComponent())
end

local function finishExit(entityId: jecs.Entity<nil>, movementId: number)
	if not isMovementCurrent(entityId, movementId, "Leaving") then
		return
	end

	local guest = WorldWrapper:FindInstance(entityId)
	if guest then
		guest.Parent = nil
	end
	onExited(entityId)
end

local function moveGuest(entityId: jecs.Entity<nil>, movementId: number, state: GuestState, destination: Vector3)
	task.spawn(function()
		local guest = getGuestModel(entityId)
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
			if not isMovementCurrent(entityId, movementId, state) then
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
					if not isMovementCurrent(entityId, movementId, state) then
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
						finishArrival(entityId, movementId)
					else
						finishExit(entityId, movementId)
					end
					return
				end
			end
		end

		if not isMovementCurrent(entityId, movementId, state) then
			return
		end
		warn(`Guest {entityId} could not build a path; using direct movement`)
		humanoid:MoveTo(destination)
		if humanoid.MoveToFinished:Wait() then
			if state == "Arriving" then
				finishArrival(entityId, movementId)
			else
				finishExit(entityId, movementId)
			end
		end
	end)
end

function CreateGuestNpc(): (jecs.Entity<nil>, Instance)
	local instance: Instance = ServerStorage.NPC.Guest:Clone()
	if not instance:IsA("Model") then
		error("ServerStorage.NPC.Guest must be a Model")
	end
	local entity = WorldWrapper:RegisterInstance(instance, "GuestNpc")
	world:set(entity, GuestNpcComponent, {
		State = "Arriving",
		MovementId = 0,
		MovementStarted = false,
	})

	instance:PivotTo(CFrame.new(SpawnPosition))
	return entity, instance
end

local System = Class.defineClass("System", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	self.cachedQuery = world:query(WorldWrapper:GetPlayerInteractComponent()):with(GuestNpcComponent):cached()
	self.guestsQuery = world:query(GuestNpcComponent):cached()
	return self
end

function System:Process(_: number)
	for entityId, guestState in self.guestsQuery do
		if not guestState.MovementStarted then
			local guest = WorldWrapper:FindInstance(entityId)
			if guest and guest.Parent then
				guestState.MovementStarted = true
				world:set(entityId, GuestNpcComponent, guestState)
				moveGuest(entityId, guestState.MovementId, guestState.State, ServicePosition)
			end
		end
	end

	for entityId, intent in self.cachedQuery do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())
		Utils:safeCall(`{self.ClassName}:processPlayerInteract`, function()
			self:processPlayerInteract(entityId, intent.PlayerView, intent.KeyCode)
		end)
	end
end

local DishFactory = require(ServerScriptService.Server.Game.Dish.DishFactory)

function System:processPlayerInteract(entityId: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end
	local guestState = world:get(entityId, GuestNpcComponent)
	if not guestState or guestState.State ~= "WaitingForService" then
		return
	end
	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool or not world:has(equippedTool, DishFactory:GetAbstractDishComponent()) then
		return
	end
	local earned = onFed(playerView:GetPlayer(), entityId, equippedTool)
	if not earned then
		return
	end

	world:set(equippedTool, WorldWrapper:GetReleaseTargetComponent())
	playerView:TakeFromHands()
	DataManager:MutateData("feedGuest", playerView:GetPlayer(), function(data)
		data.CoinsEarned += earned
	end)

	local guest = WorldWrapper:FindInstance(entityId)
	if guest then
		guest:RemoveTag("Interactable")
	end
	world:remove(entityId, WorldWrapper:GetPlayerInteractableComponent())
	world:set(entityId, GuestNpcComponent, {
		State = "Leaving",
		MovementId = guestState.MovementId + 1,
		MovementStarted = true,
	})
	moveGuest(entityId, guestState.MovementId + 1, "Leaving", ExitPosition)
end

return {
	Create = CreateGuestNpc,
	Component = GuestNpcComponent,
	System = System.new(),
	SetFedHandler = function(handler: (Player, jecs.Entity<nil>, jecs.Entity<nil>) -> number?)
		onFed = handler
	end,
	SetExitedHandler = function(handler: (jecs.Entity<nil>) -> ())
		onExited = handler
	end,
	CancelAll = function()
		for entityId, guestState in world:query(GuestNpcComponent) do
			world:set(entityId, GuestNpcComponent, {
				State = guestState.State,
				MovementId = guestState.MovementId + 1,
				MovementStarted = true,
			})
		end
	end,
}
