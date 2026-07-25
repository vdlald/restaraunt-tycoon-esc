--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)

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

function GameLoop:Start(processMatchPhaseTransition: () -> ())
	RunService.Heartbeat:Connect(function(deltaTime)
		GameCycle:Process(deltaTime)
		processMatchPhaseTransition()

		PlayerInteractSystem:Process(deltaTime)
		BuildingSystem:Process(deltaTime)

		GuestNpc.System:Process(deltaTime)

		Trashcan.System:Process(deltaTime)
		FlourBag.System:Process(deltaTime)
		MeatSteakFridge.System:Process(deltaTime)

		Flour.System:Process(deltaTime)
		Dough.System:Process(deltaTime)
		RawPie.System:Process(deltaTime)
		RawMeatSteak.System:Process(deltaTime)
		ChoppedMeat.System:Process(deltaTime)
		MinceMeat.System:Process(deltaTime)
		Pie.System:Process(deltaTime)

		PlaceHolder.System:Process(deltaTime)
		PlayerInteractSystem:Clear()
	end)
end

return GameLoop
