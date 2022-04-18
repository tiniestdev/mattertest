local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Packages.Net)

local Definitions = {
    ChangeTeam = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60, })
    }),
    RequestRespawn = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 120, })
    }),
    RequestEquipEquippable = Net.Definitions.ServerAsyncFunction({}),
    RequestReplicateArchetype = Net.Definitions.ServerAsyncFunction({}),

    ProposeRagdollState = Net.Definitions.ServerAsyncFunction({}),

    -- REPLICATIONS
    ReplicateArchetype = Net.Definitions.ServerToClientEvent({ }),
    DespawnedEntities = Net.Definitions.ServerToClientEvent({ }),

    ClientToServer = Net.Definitions.ClientToServerEvent({ }),
    ServerToClient = Net.Definitions.ServerToClientEvent({ }),

    Test = Net.Definitions.Namespace({
        SerToCli = Net.Definitions.ServerToClientEvent({ }),
        CliToSer = Net.Definitions.ServerToClientEvent({ }),
    })
}

local Remotes = Net.Definitions.Create(Definitions)

if RunService:IsServer() then
    for remoteName, remoteDef in pairs(Definitions) do
        --print(remoteName, remoteDef, getmetatable(remoteDef))
        pcall(function()
            Remotes.Server:Create(remoteName)
        end)
        -- i hate rbxnet
    end
end
-- else
--     for remoteName, remoteDef in pairs(Definitions) do
--         Remotes.Client:Get(remoteName)
--     end
-- end

return Remotes