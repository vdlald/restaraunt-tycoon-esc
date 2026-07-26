--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local DayEconomy = require(ServerScriptService.Server.Game.GameCycle.DayEconomy)

describe("DayEconomy", function()
	it("tracks match cash and rejects invalid purchases", function()
		local economy = DayEconomy.new(1)
		economy:StartMatch(100)

		expect(economy:GetCash()).to.equal(100)
		expect(economy:TrySpendCash(40)).to.equal(true)
		expect(economy:GetCash()).to.equal(60)
		expect(economy:TrySpendCash(61)).to.equal(false)
		expect(economy:TrySpendCash(-1)).to.equal(false)
		expect(economy:GetCash()).to.equal(60)
	end)

	it("aggregates dishes into a day receipt", function()
		local economy = DayEconomy.new(2)
		local player = Instance.new("Player")

		economy:RecordDish(player, "Pie", 20)
		economy:RecordDish(player, "Pie", 30)
		economy:RecordDish(player, "Steak", 40)

		local receipt = economy:GetReceipt()
		expect(receipt.day).to.equal(2)
		expect(receipt.total).to.equal(90)
		expect(#receipt.dishes).to.equal(2)
		expect(receipt.dishes[1].dishName).to.equal("Pie")
		expect(receipt.dishes[1].count).to.equal(2)
		expect(receipt.dishes[1].earned).to.equal(50)
		expect(receipt.dishes[2].dishName).to.equal("Steak")
		expect(economy:GetCash()).to.equal(90)

		player:Destroy()
	end)

	it("resets only the receipt when starting a new day", function()
		local economy = DayEconomy.new(1)
		local player = Instance.new("Player")
		economy:StartMatch(50)
		economy:RecordDish(player, "Pie", 20)

		economy:ResetDay(2)

		local receipt = economy:GetReceipt()
		expect(economy:GetCash()).to.equal(70)
		expect(receipt.day).to.equal(2)
		expect(receipt.total).to.equal(0)
		expect(#receipt.dishes).to.equal(0)

		player:Destroy()
	end)

	it("drains pending experience without updating player data", function()
		local economy = DayEconomy.new(1)
		local player = Instance.new("Player")

		economy:RecordDish(player, "Pie", 20)
		economy:RecordDish(player, "Steak", 40)

		local pendingExperience = economy:DrainPendingExperience()
		expect(pendingExperience[player]).to.equal(60)
		expect(next(economy:DrainPendingExperience())).to.equal(nil)

		player:Destroy()
	end)
end)
