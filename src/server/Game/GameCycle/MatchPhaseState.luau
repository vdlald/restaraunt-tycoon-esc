--!strict

-- Compatibility entry point. Match phase rules live in the domain layer.
local ServerScriptService = game:GetService("ServerScriptService")

return require(ServerScriptService.Server.Domain.Match.MatchPhaseState)
