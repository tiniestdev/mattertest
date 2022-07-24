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
    RequestEntitiesDump = Net.Definitions.ServerAsyncFunction({}),
    RequestReplicateArchetype = Net.Definitions.ServerAsyncFunction({}),
    RequestGrab = Net.Definitions.ServerAsyncFunction({}),

    -- This asks for a list of all replicated entities, usually called once per player session.
    RequestReplicatedEntites = Net.Definitions.ServerAsyncFunction({}),
    -- This asks the server to actually *replicate* a list of entities to a specific player.
    RequestReplicateEntities = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60, })
    }),

    -- client to server grabber offset update
    ReplicateGrabberOffset = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = (60 * 1/0.1), })
    }),

    ProposeRagdollState = Net.Definitions.ServerAsyncFunction({}),
    UpdateAimerPitchYaw = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60 * 20, })
    }),

    RenderProjectile = Net.Definitions.ServerToClientEvent({}),
    ProjectileInteractions = Net.Definitions.ServerToClientEvent({ }),
    InitialProjectileCFrames = Net.Definitions.ServerToClientEvent({ }),
    ProposeProjectile = Net.Definitions.ClientToServerEvent({
        -- if a client wants to go brr, they should limit it and send *batch* bullets
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60 * 120, })
    }),
    ProposeProjectileHit = Net.Definitions.ClientToServerEvent({
        Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60 * 120, })
    }),

    -- REPLICATIONS
    ReplicateArchetype = Net.Definitions.ServerToClientEvent({ }),
    -- For client owned entities to propose changes of components to the server
    ReplicateClientOwnedEntityStates = Net.Definitions.ServerAsyncFunction({
        -- Net.Middleware.RateLimit({ MaxRequestsPerMinute = 60 * 2, })
    }),
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