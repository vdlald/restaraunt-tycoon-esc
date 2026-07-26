--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Net)
local GameCycle = require(ServerScriptService.Server.Game.GameCycle.GameCycle)

type PlayerDataStore = {
	GetReadOnlyVersion: (
		self: PlayerDataStore,
		player: Player
	) -> { ExperienceEarned: number, ExperienceSpend: number }?,
}

local ClientSessionApplication = {}
ClientSessionApplication.__index = ClientSessionApplication

export type ClientSessionApplication = {
	gameCycle: typeof(GameCycle.new()),
	dataManager: PlayerDataStore,
	SynchronizeClient: (self: ClientSessionApplication, player: Player) -> (),
}

function ClientSessionApplication.new(
	gameCycle: typeof(GameCycle.new()),
	dataManager: PlayerDataStore
): ClientSessionApplication
	return setmetatable({
		gameCycle = gameCycle,
		dataManager = dataManager,
	}, ClientSessionApplication) :: ClientSessionApplication
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
