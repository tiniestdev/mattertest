local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Remotes = require(ReplicatedStorage.Remotes)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    local emptyEntitiesData = {}
    for id, emptyC, replicatedC in world:query(Components.EmptyEntity, Components.Replicated) do
        -- check what archetypes that are actually missing
        local missingArchetypes = {}
        for archetypeName, _ in pairs(emptyC.archetypes) do
            if not matterUtil.isArchetype(id, archetypeName, world) then
                table.insert(missingArchetypes, archetypeName)
            else
                print("..archetype " .. archetypeName .. " is present on " .. id)
            end
        end
        if #missingArchetypes > 0 then
            table.insert(emptyEntitiesData, {
                serverId = id,
                missingArchetypes = missingArchetypes,
            })
            print("..ENTITY ", id, "MISSING ARCHETYPES:")
            for _, archetypeName in ipairs(missingArchetypes) do
                print("\tMISSING ", archetypeName)
            end
        end
    end
    if #emptyEntitiesData > 0 then
        print("REQUESTING REPLICATE ARCHETYPES ENTITIES")
        Remotes.Client:Get("RequestReplicateArchetype"):CallServerAsync(emptyEntitiesData):andThen(function(response)
            print("GOT SERVER RESPONSE, ", response)
        end)
    end
end