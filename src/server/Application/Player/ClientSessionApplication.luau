--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local ClientSessionApplication = {}
ClientSessionApplication.__index = ClientSessionApplication

export type ClientSessionApplication = {
	gameCycle: any,
	dataManager: any,
	SynchronizeClient: (self: ClientSessionApplication, player: Player) -> (),
}

function ClientSessionApplication.new(gameCycle, dataManager): ClientSessionApplication
	return setmetatable({
		gameCycle = gameCycle,
		dataManager = dataManager,
	}, ClientSessionApplication) :: any
end

function ClientSessionApplication:SynchronizeClient(player: Player)
	if player.Parent ~= Players then
		return
	end

	self.gameCycle:SendState(player)
	local playerData = self.dataManager:GetReadOnlyVersion(player)
	if playerData then
		Net.playerDataUpdate.sendTo({
			experience = playerData.ExperienceEarned - playerData.ExperienceSpend,
		}, player)
	end
end

return ClientSessionApplication
