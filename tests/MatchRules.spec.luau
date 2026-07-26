--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local MatchRules = require(ServerScriptService.Server.Domain.Match.MatchRules)

describe("MatchRules", function()
	it("scales guest count and service duration with the day", function()
		local guests, duration = MatchRules.GetDayProgression(3)

		expect(guests).to.equal(5)
		expect(duration).to.equal(80)
	end)

	it("uses a default price for unknown dishes", function()
		expect(MatchRules.GetDishPrice("Pie")).to.equal(10)
		expect(MatchRules.GetDishPrice("UnknownDish")).to.equal(10)
	end)
end)
