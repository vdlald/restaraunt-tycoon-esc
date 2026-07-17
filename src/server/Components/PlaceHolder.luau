--!strict

-- Зависимости
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)
local Class = require(ReplicatedStorage.Shared.Class)
local Consts = require(ReplicatedStorage.Shared.Consts)

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types)
local AbstractSystem = require(ServerScriptService.Server.Systems.AbstractSystem)

local WorldWrapper = require(ServerScriptService.Server.World)
local world = WorldWrapper:GetWorld()

--
-- Компонент
export type PlaceHolderComponent = jecs.Id<nil>
local placeHolderComponent = world:component() :: PlaceHolderComponent

export type Holds = jecs.Id<nil>
local holds = world:component() :: Holds

--
-- Объявление сущности
function CreatePlaceHolder(instance: Instance): (jecs.Entity<nil>, Instance)
	instance:AddTag(Consts.Tags.Interactable)

	local entity = WorldWrapper:RegisterInstance(instance, "PlaceHolder")
	world:set(entity, placeHolderComponent)
	world:set(entity, WorldWrapper:GetPlayerInteractableComponent())

	return entity, instance
end

--
-- Объявление обработчика
local System = Class.defineClass("PlaceHolderSystem", AbstractSystem)

function System.new()
	local parent = AbstractSystem.new()
	local self = setmetatable(parent, System)
	return self
end

local findEmptyPlaceHoldersQuery = function()
	return world
		:query(WorldWrapper:GetPlayerInteractComponent())
		:with(placeHolderComponent)
		:without(jecs.pair(holds, jecs.Wildcard))
end

local findFilledPlaceHoldersQuery = function()
	return world
		:query(WorldWrapper:GetPlayerInteractComponent())
		:with(placeHolderComponent, jecs.pair(holds, jecs.Wildcard))
end

function System:Process(_: number)
	for entityId, intent in findEmptyPlaceHoldersQuery() do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local ok, err = pcall(function()
			System:processPlace(entityId, playerView, keyCode)
		end)
		if not ok then
			local trace = debug.traceback(err)
			warn(`{self.ClassName}.processPlayerInteract failed\n`, trace)
		end
	end

	for entityId, intent in findFilledPlaceHoldersQuery() do
		world:remove(entityId, WorldWrapper:GetPlayerInteractComponent())

		local keyCode: Enum.KeyCode = intent.KeyCode
		local playerView: Types.PlayerView = intent.PlayerView

		local ok, err = pcall(function()
			System:processTake(entityId, playerView, keyCode)
		end)
		if not ok then
			local trace = debug.traceback(err)
			warn(`{self.ClassName}.processPlayerInteract failed\n`, trace)
		end
	end
end

function System:processPlace(entityId: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if not equippedTool then
		return
	end
 
	playerView:TakeFromHands()

    local placedView = world:get(equippedTool, WorldWrapper:GetInstanceComponent()).Instance
    local primaryPart = world:get(entityId, WorldWrapper:GetInstanceComponent()).Instance

	local plateTop = primaryPart.CFrame * CFrame.new(0, primaryPart.Size.Y / 2, 0)
	local targetCFrame = plateTop * CFrame.new(0, placedView.PrimaryPart.Size.Y / 2, 0)
	placedView:SetPrimaryPartCFrame(targetCFrame)

	local weld = Instance.new("WeldConstraint")
    weld.Part0 = placedView.PrimaryPart
    weld.Part1 = primaryPart
    weld.Parent = primaryPart
    placedView.Parent = workspace

	world:set(entityId, jecs.pair(holds, equippedTool), weld)
end

function System:processTake(entityId: jecs.Entity<nil>, playerView: Types.PlayerView, keyCode: Enum.KeyCode)
	if keyCode ~= Enum.KeyCode.E then
		return
	end

	local equippedTool = playerView:GetEquippedTool()
	if equippedTool then
		return
	end

	local targetEntityId = world:target(entityId, holds)
	world:get(entityId, jecs.pair(holds, targetEntityId)):Destroy()
	world:remove(entityId, jecs.pair(holds, targetEntityId))

	local tool: Tool = world:get(targetEntityId, WorldWrapper:GetInstanceComponent()).Instance
	playerView:PutInHands(tool)
end

--
-- Модуль
return {
	Create = CreatePlaceHolder,
	Component = placeHolderComponent,
	System = System.new() :: AbstractSystem.AbstractSystem,
}
