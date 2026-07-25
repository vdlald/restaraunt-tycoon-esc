--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Net)
local DataManager = require(ServerScriptService.Server.Player.DataManager)

local PlayerDataSync = {}

local function sendExperience(player: Player, playerData: DataManager.PlayerData)
	Net.playerDataUpdate.sendTo({
		experience = playerData.ExperienceEarned - playerData.ExperienceSpend,
	}, player)
end

function PlayerDataSync:Start()
	DataManager:OnProfileDataChanged(function(event: DataManager.PlayerDataChangedEvent)
		sendExperience(event.Player, event.Data)
	end)

	DataManager:OnProfileLoaded(function(player, playerData)
		sendExperience(player, playerData)
	end)
end

return PlayerDataSync
