--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.Player.DataManager)

export type ExperienceRewards = {
	GrantExperience: (self: ExperienceRewards, player: Player, amount: number) -> boolean,
}

local ExperienceRewards = {}
ExperienceRewards.__index = ExperienceRewards

function ExperienceRewards.new(): ExperienceRewards
	return setmetatable({}, ExperienceRewards)
end

function ExperienceRewards:GrantExperience(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end
	return DataManager:MutateData("completeDayExperience", player, function(data)
		data.ExperienceEarned += amount
	end)
end

return ExperienceRewards
