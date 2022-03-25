local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Packages.Net)

local Remotes = Net.Definitions.Create({
    ChangeTeam = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60, })
    }),
    RequestRespawn = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 120, })
    }),
    
    -- REPLICATIONS
    ReplicateArchetype = Net.Definitions.ServerToClientEvent({ }),
    DespawnedEntities = Net.Definitions.ServerToClientEvent({ }),

    ClientToServer = Net.Definitions.ClientToServerEvent({ }),
    ServerToClient = Net.Definitions.ServerToClientEvent({ }),
})

return Remotes