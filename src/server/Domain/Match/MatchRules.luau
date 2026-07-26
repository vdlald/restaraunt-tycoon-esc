--!strict

local MatchRules = {
	DishPrices = {
		Pie = 10,
	},
}

function MatchRules.GetDayProgression(day: number): (number, number)
	local guests = day + 2
	return guests, 30 + 10 * guests
end

function MatchRules.GetDishPrice(dishName: string): number
	return MatchRules.DishPrices[dishName] or 10
end

return MatchRules
