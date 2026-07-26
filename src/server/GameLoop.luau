--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)
local EntityLifecycleSystem = require(ServerScriptService.Server.Systems.EntityLifecycleSystem)

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

local GameLoop = {}

function GameLoop:Start(context, processMatchPhaseTransition: () -> ())
	local registry = context.Systems
	local interactions = context.Interactions
	interactions:Register(context.Building)
	interactions:Register(GuestNpc.System)
	interactions:Register(Trashcan.System)
	interactions:Register(FlourBag.System)
	interactions:Register(MeatSteakFridge.System)
	interactions:Register(Flour.System)
	interactions:Register(Dough.System)
	interactions:Register(RawPie.System)
	interactions:Register(RawMeatSteak.System)
	interactions:Register(ChoppedMeat.System)
	interactions:Register(MinceMeat.System)
	interactions:Register(Pie.System)
	interactions:Register(PlaceHolder.System)
	registry:Register("Intent", PlayerInteractSystem.new(context.World, interactions))

	registry:Register("Simulation", context.Building)
	registry:Register("Simulation", GuestNpc.System)
	registry:Register("Simulation", Trashcan.System)
	registry:Register("Simulation", FlourBag.System)
	registry:Register("Simulation", MeatSteakFridge.System)
	registry:Register("Simulation", Flour.System)
	registry:Register("Simulation", Dough.System)
	registry:Register("Simulation", RawPie.System)
	registry:Register("Simulation", RawMeatSteak.System)
	registry:Register("Simulation", ChoppedMeat.System)
	registry:Register("Simulation", MinceMeat.System)
	registry:Register("Simulation", Pie.System)
	registry:Register("Simulation", PlaceHolder.System)
	registry:Register("Lifecycle", EntityLifecycleSystem)

	-- Keep the composition root loaded by startup. Legacy systems still access
	-- its World through WorldWrapper while new systems can depend on GameContext.
	assert(context.World ~= nil, "GameContext must provide World")

	RunService.Heartbeat:Connect(function(deltaTime)
		GameCycle:Process(deltaTime)
		processMatchPhaseTransition()

		registry:Process("Intent", deltaTime)
		registry:Process("Simulation", deltaTime)
		registry:Process("Lifecycle", deltaTime)
	end)
end

return GameLoop
