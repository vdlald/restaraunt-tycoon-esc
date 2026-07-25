--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)
local PlaceHolder = require(ServerScriptService.Server.Components.PlaceHolder)
local PlayerInteractSystem = require(ServerScriptService.Server.Systems.PlayerInteractSystem)
local BuildingSystem = require(ServerScriptService.Server.Systems.BuildingSystem)
local PlayerSystem = require(ServerScriptService.Server.Player.PlayerSystem)

local GuestNpc = require(ServerScriptService.Server.Game.Npc.Guest)

local Flour = require(ServerScriptService.Server.Game.Ingredient.Flour)
local Dough = require(ServerScriptService.Server.Game.Ingredient.Dough)
local RawPie = require(ServerScriptService.Server.Game.Ingredient.RawPie)
local RawMeatSteak = require(ServerScriptService.Server.Game.Ingredient.RawMeatSteak)
local ChoppedMeat = require(ServerScriptService.Server.Game.Ingredient.ChoppedMeat)
local MinceMeat = require(ServerScriptService.Server.Game.Ingredient.MinceMeat)
local Pie = require(ServerScriptService.Server.Game.Dish.Pie)
local Plate = require(ServerScriptService.Server.Game.Items.Plate)

local FlourBag = require(ServerScriptService.Server.Game.Furniture.FlourBag)
local MeatSteakFridge = require(ServerScriptService.Server.Game.Furniture.MeatSteakFridge)
local Trashcan = require(ServerScriptService.Server.Game.Furniture.Trashcan)
local Chair = require(ServerScriptService.Server.Game.Furniture.Chair)
local DiningTable = require(ServerScriptService.Server.Game.Furniture.DiningTable)
local KitchenTable = require(ServerScriptService.Server.Game.Furniture.KitchenTable)

local GameLoop = {}

function GameLoop:Start(processMatchPhaseTransition: () -> ())
	RunService.Heartbeat:Connect(function(deltaTime)
		GameCycle:Process(deltaTime)
		processMatchPhaseTransition()

		PlayerSystem:Process(deltaTime)
		PlayerInteractSystem:Process(deltaTime)
		BuildingSystem:Process(deltaTime)

		GuestNpc.System:Process(deltaTime)

		Trashcan.System:Process(deltaTime)
		FlourBag.System:Process(deltaTime)
		MeatSteakFridge.System:Process(deltaTime)
		Chair.System:Process(deltaTime)
		DiningTable.System:Process(deltaTime)
		KitchenTable.System:Process(deltaTime)

		Flour.System:Process(deltaTime)
		Dough.System:Process(deltaTime)
		RawPie.System:Process(deltaTime)
		RawMeatSteak.System:Process(deltaTime)
		ChoppedMeat.System:Process(deltaTime)
		MinceMeat.System:Process(deltaTime)
		Pie.System:Process(deltaTime)

		Plate.System:Process(deltaTime)
		PlaceHolder.System:Process(deltaTime)
		PlayerInteractSystem:Clear()
	end)
end

return GameLoop
