--!strict

export type Config = {
	capacity: number,
	refillPerSecond: number,
	clock: (() -> number)?,
}

type Bucket = {
	tokens: number,
	updatedAt: number,
}

export type RateLimiter = {
	capacity: number,
	refillPerSecond: number,
	clock: () -> number,
	buckets: { [any]: Bucket },
	CanConsume: (self: RateLimiter, key: any, cost: number?) -> (boolean, number),
	TryConsume: (self: RateLimiter, key: any, cost: number?) -> (boolean, number),
	Reset: (self: RateLimiter, key: any) -> (),
	ResetAll: (self: RateLimiter) -> (),
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

local function isFinitePositive(value: number): boolean
	return value > 0 and value < math.huge
end

local function getCost(cost: number?): number
	local resolvedCost = cost or 1
	assert(isFinitePositive(resolvedCost), "RateLimiter cost must be a finite positive number")
	return resolvedCost
end

local function refill(self: RateLimiter, key: any): Bucket
	assert(key ~= nil, "RateLimiter key must not be nil")
	local now = self.clock()
	local bucket = self.buckets[key]
	if not bucket then
		bucket = {
			tokens = self.capacity,
			updatedAt = now,
		}
		self.buckets[key] = bucket
		return bucket
	end

	local elapsed = math.max(0, now - bucket.updatedAt)
	if elapsed > 0 then
		bucket.tokens = math.min(self.capacity, bucket.tokens + elapsed * self.refillPerSecond)
		bucket.updatedAt = now
	end
	return bucket
end

function RateLimiter.new(config: Config): RateLimiter
	assert(isFinitePositive(config.capacity), "RateLimiter capacity must be a finite positive number")
	assert(
		config.refillPerSecond >= 0 and config.refillPerSecond < math.huge,
		"RateLimiter refillPerSecond must be a finite non-negative number"
	)
	assert(config.clock == nil or type(config.clock) == "function", "RateLimiter clock must be a function")

	return setmetatable({
		capacity = config.capacity,
		refillPerSecond = config.refillPerSecond,
		clock = config.clock or os.clock,
		buckets = {},
	}, RateLimiter) :: any
end

function RateLimiter:CanConsume(key: any, cost: number?): (boolean, number)
	local resolvedCost = getCost(cost)
	assert(resolvedCost <= self.capacity, "RateLimiter cost must not exceed capacity")

	local bucket = refill(self, key)
	if bucket.tokens >= resolvedCost then
		return true, 0
	end
	if self.refillPerSecond == 0 then
		return false, math.huge
	end
	return false, (resolvedCost - bucket.tokens) / self.refillPerSecond
end

function RateLimiter:TryConsume(key: any, cost: number?): (boolean, number)
	local resolvedCost = getCost(cost)
	local allowed, retryAfter = self:CanConsume(key, resolvedCost)
	if not allowed then
		return false, retryAfter
	end

	self.buckets[key].tokens -= resolvedCost
	return true, 0
end

function RateLimiter:Reset(key: any)
	self.buckets[key] = nil
end

function RateLimiter:ResetAll()
	table.clear(self.buckets)
end

return RateLimiter
