--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local ClientSessionHandler = {}

function ClientSessionHandler.Start(gameCycle, dataManager)
	Net.clientReady.listen(function(_: table, player: Player)
		if player.Parent ~= Players then
			return
		end

		gameCycle:SendState(player)
		local playerData = dataManager:GetReadOnlyVersion(player)
		if playerData then
			Net.playerDataUpdate.sendTo({
				experience = playerData.ExperienceEarned - playerData.ExperienceSpend,
			}, player)
		end
	end)
end

return ClientSessionHandler
