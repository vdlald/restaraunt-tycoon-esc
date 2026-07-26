--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.Player.DataManager)

export type ReceiptDish = {
	dishName: string,
	count: number,
	earned: number,
}

export type DayReceipt = {
	day: number,
	dishes: { ReceiptDish },
	total: number,
}

export type DayEconomy = {
	cash: number,
	receipt: DayReceipt,
	pendingExperience: { [Player]: number },
	StartMatch: (self: DayEconomy, startingCash: number) -> (),
	ResetDay: (self: DayEconomy, day: number) -> (),
	Clear: (self: DayEconomy) -> (),
	GetCash: (self: DayEconomy) -> number,
	AddCash: (self: DayEconomy, amount: number) -> (),
	TrySpendCash: (self: DayEconomy, amount: number) -> boolean,
	RecordDish: (self: DayEconomy, player: Player, dishName: string, earned: number) -> (),
	GetReceipt: (self: DayEconomy) -> DayReceipt,
	CommitPendingExperience: (self: DayEconomy) -> (),
	DiscardPendingExperience: (self: DayEconomy) -> (),
}

local DayEconomy = {}
DayEconomy.__index = DayEconomy

local function createReceipt(day: number): DayReceipt
	return {
		day = day,
		dishes = {},
		total = 0,
	}
end

function DayEconomy.new(day: number): DayEconomy
	return setmetatable({
		cash = 0,
		receipt = createReceipt(day),
		pendingExperience = {},
	}, DayEconomy) :: any
end

function DayEconomy:StartMatch(startingCash: number)
	self.cash = startingCash
end

function DayEconomy:ResetDay(day: number)
	self.receipt = createReceipt(day)
end

function DayEconomy:Clear()
	self.cash = 0
	self:ResetDay(1)
	self:DiscardPendingExperience()
end

function DayEconomy:GetCash(): number
	return self.cash
end

function DayEconomy:AddCash(amount: number)
	self.cash += amount
end

function DayEconomy:TrySpendCash(amount: number): boolean
	if amount < 0 or self.cash < amount then
		return false
	end
	self.cash -= amount
	return true
end

function DayEconomy:RecordDish(player: Player, dishName: string, earned: number)
	local receiptDish: ReceiptDish? = nil
	for _, line in self.receipt.dishes do
		if line.dishName == dishName then
			receiptDish = line
			break
		end
	end
	if receiptDish then
		receiptDish.count += 1
		receiptDish.earned += earned
	else
		table.insert(self.receipt.dishes, {
			dishName = dishName,
			count = 1,
			earned = earned,
		})
	end
	self.receipt.total += earned
	self.pendingExperience[player] = (self.pendingExperience[player] or 0) + earned
	self:AddCash(earned)
end

function DayEconomy:GetReceipt(): DayReceipt
	return self.receipt
end

function DayEconomy:CommitPendingExperience()
	for player, experience in self.pendingExperience do
		if player.Parent == Players and experience > 0 then
			DataManager:MutateData("completeDayExperience", player, function(data)
				data.ExperienceEarned += experience
			end)
		end
	end
	self:DiscardPendingExperience()
end

function DayEconomy:DiscardPendingExperience()
	table.clear(self.pendingExperience)
end

return DayEconomy
