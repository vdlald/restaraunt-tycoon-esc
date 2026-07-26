--!strict

-- Compatibility entry point. Domain code lives outside the GameCycle adapter.
local ServerScriptService = game:GetService("ServerScriptService")

return require(ServerScriptService.Server.Domain.Match.DayEconomy)
