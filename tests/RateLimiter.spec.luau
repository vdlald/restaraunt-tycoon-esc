--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RateLimiter = require(ReplicatedStorage.Shared.RateLimiter)

describe("RateLimiter", function()
	local now: number
	local function createLimiter(capacity: number, refillPerSecond: number)
		return RateLimiter.new({
			capacity = capacity,
			refillPerSecond = refillPerSecond,
			clock = function()
				return now
			end,
		})
	end

	beforeEach(function()
		now = 0
	end)

	it("allows the configured initial burst", function()
		local limiter = createLimiter(2, 1)
		expect(limiter:TryConsume("player")).to.equal(true)
		expect(limiter:TryConsume("player")).to.equal(true)
		expect(limiter:TryConsume("player")).to.equal(false)
	end)

	it("refills tokens and reports the retry delay", function()
		local limiter = createLimiter(2, 1)
		limiter:TryConsume("player", 2)

		local allowed, retryAfter = limiter:CanConsume("player")
		expect(allowed).to.equal(false)
		expect(retryAfter).to.equal(1)

		now = 0.5
		allowed, retryAfter = limiter:CanConsume("player")
		expect(allowed).to.equal(false)
		expect(retryAfter).to.equal(0.5)

		now = 1
		expect(limiter:TryConsume("player")).to.equal(true)
	end)

	it("supports weighted requests", function()
		local limiter = createLimiter(3, 1)
		expect(limiter:TryConsume("player", 2)).to.equal(true)
		expect(limiter:TryConsume("player", 2)).to.equal(false)
		now = 1
		expect(limiter:TryConsume("player", 2)).to.equal(true)
	end)

	it("does not refill a one-shot limiter", function()
		local limiter = createLimiter(1, 0)
		expect(limiter:TryConsume("player")).to.equal(true)
		now = 100

		local allowed, retryAfter = limiter:CanConsume("player")
		expect(allowed).to.equal(false)
		expect(retryAfter).to.equal(math.huge)
	end)

	it("resets individual keys independently", function()
		local limiter = createLimiter(1, 0)
		limiter:TryConsume("first")
		limiter:TryConsume("second")
		limiter:Reset("first")

		expect(limiter:TryConsume("first")).to.equal(true)
		expect(limiter:TryConsume("second")).to.equal(false)
	end)

	it("resets all keys", function()
		local limiter = createLimiter(1, 0)
		limiter:TryConsume("first")
		limiter:TryConsume("second")
		limiter:ResetAll()

		expect(limiter:TryConsume("first")).to.equal(true)
		expect(limiter:TryConsume("second")).to.equal(true)
	end)
end)
