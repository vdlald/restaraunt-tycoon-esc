--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GamePhase = require(ReplicatedStorage.Shared.GamePhase)
local MatchPhaseState = require(ServerScriptService.Server.Game.GameCycle.MatchPhaseState)

describe("MatchPhaseState", function()
	it("transitions from lobby to preparation after the countdown", function()
		local state = MatchPhaseState.new()

		expect(state:RequestToggle(3)).to.equal(true)
		expect(state.phase).to.equal(GamePhase.Lobby)
		expect(state:GetDisplaySeconds()).to.equal(3)
		expect(state:CanPurchaseFurniture()).to.equal(false)
		expect(state:Tick(2)).to.equal(nil)
		expect(state:Tick(1)).to.equal(GamePhase.Preparation)
	end)

	it("cancels a pending phase toggle", function()
		local state = MatchPhaseState.new()

		state:RequestToggle(3)
		expect(state:RequestToggle(3)).to.equal(true)
		expect(state.countdownSeconds).to.equal(0)
		expect(state:Tick(3)).to.equal(nil)
		expect(state.phase).to.equal(GamePhase.Lobby)
	end)

	it("requires all fed guests to exit before ending service", function()
		local state = MatchPhaseState.new()
		state:EnterService(2, 60)

		expect(state:OnGuestFed()).to.equal(true)
		expect(state:OnGuestFed()).to.equal(true)
		expect(state:OnGuestFed()).to.equal(false)
		expect(state:OnGuestExited()).to.equal(false)
		expect(state:OnGuestExited()).to.equal(true)
		expect(state.guestsRemaining).to.equal(0)
		expect(state.guestsLeaving).to.equal(0)
	end)

	it("reports defeat when service time expires while guests remain", function()
		local state = MatchPhaseState.new()
		state:EnterService(1, 1)

		expect(state:Tick(0.5)).to.equal(nil)
		expect(state:Tick(0.5)).to.equal(GamePhase.Defeat)
	end)

	it("returns to lobby after a result timeout", function()
		local state = MatchPhaseState.new()
		state:EnterResult(GamePhase.Victory, 1)

		expect(state:Tick(1)).to.equal(GamePhase.Lobby)
	end)
end)
