--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.Jecs)

-- Player
export type PlayerView = {
	GetPlayer: (self: PlayerView) -> Player,

	GetEquippedTool: (self: PlayerView) -> jecs.Id<nil>?,
	TakeFromHands: (self: PlayerView) -> jecs.Id<nil>?,
	PutInHands: (self: PlayerView, Tool) -> (),

	GetDistance: (self: PlayerView, instance: Instance) -> number,
	GetCharacter: (self: PlayerView) -> Model,
	GetHumanoid: (self: PlayerView) -> Humanoid,
}

return {}
