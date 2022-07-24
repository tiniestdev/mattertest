local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Constants)
local Remotes = require(ReplicatedStorage.Remotes)
local Components = require(ReplicatedStorage.components)
local randUtil = require(ReplicatedStorage.Util.randUtil)

local ReplicationStart = {}

ReplicationStart.AxisName = "ReplicationStartAxis"
local MatterStart = require(script.Parent.MatterStart)

function ReplicationStart:AxisPrepare()
end

function ReplicationStart:AxisStarted()
    Remotes.Server:OnFunction("ReplicateClientOwnedEntityStates", function(player, entityToComponentsMap)
        local world = MatterStart.World
        local correctionMap = {}

        local allVerified = true
        -- print(player, entityToComponentsMap)
        for serverEntityId, components in pairs(entityToComponentsMap) do
            local serverEntityId = tonumber(serverEntityId)
            if not world:contains(serverEntityId) then
                warn("entity not in world: " .. serverEntityId)
                continue
            end
            for componentName, componentData in pairs(components) do
                -- should probably verify stuff here
                local verify
                local correctData

                verify = true

                if verify then
                    world:insert(serverEntityId, Components[componentName](componentData))
                    -- print("updated client owned entity ", serverEntityId)
                else
                    warn("failed to verify " .. componentName .. " for " .. serverEntityId .. ", correcting")
                    allVerified = false
                    correctionMap[tostring(serverEntityId)] = correctionMap[tostring(serverEntityId)] or {}
                    correctionMap[tostring(serverEntityId)][componentName] = correctData
                    world:insert(serverEntityId, Components[componentName](correctData))
                    print("Corrected " .. componentName .. " for " .. serverEntityId)
                end
            end
        end

        return {allVerified, correctionMap}
    end)
end

return ReplicationStart

