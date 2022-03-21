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
    RequestStorage = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60, })
    }),
    ReplicateStorage = Net.Definitions.ServerToClientEvent({ }),

    ClientToServer = Net.Definitions.ClientToServerEvent({ }),
    ServerToClient = Net.Definitions.ServerToClientEvent({ }),
    --ReplicateBackpack = Net.Definitions.ServerToClientEvent({ }),
})

return Remotes