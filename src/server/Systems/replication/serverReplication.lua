local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local Remotes = require(ReplicatedStorage.Remotes)

local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local Archetypes = require(ReplicatedStorage.Archetypes)

local RequestReplicateEntities = matterUtil.NetSignalToEvent("RequestReplicateEntities", Remotes)

local archetypesToReplicate

return function(world)
    local removedReplicatedIds = {}

    if not archetypesToReplicate then
        -- print("INITING")
        archetypesToReplicate = {}
        for i, v in pairs(Archetypes.Catalog) do
            table.insert(archetypesToReplicate, i)
            -- print("!REPLICATING ARCHETYPE: " .. i)
        end
    end
    for i, player, listOfEntityIds in Matter.useEvent(RequestReplicateEntities, "Event") do
        -- print("GOT REQUEST FROM PLAYER TO REPLICATE ENTITIES", player, listOfEntityIds)
        for _, entityId in ipairs(listOfEntityIds) do
            if not world:contains(entityId) then continue end
            local rtcC = world:get(entityId, Components.ReplicateToClient)
            if rtcC then
                for _, archetypeName in ipairs(rtcC.archetypes) do
                    replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
                    -- print("RR EVENT: replicated entity " .. entityId .. " to archetype " .. archetypeName)
                end
            end
        end
    end

    -- force replicate entities that a client is currently missing

    -- Automatically replicates changes in an entity's archetypes
    -- like if it wanted to take on a different archetype
    for id, rtcCR in world:queryChanged(Components.ReplicateToClient) do
        -- print("RR EVENT: changed ReplicateToClient", id, rtcCR)
        if rtcCR.new then
            -- print("RR EVENT: entity " .. id .. " has new ReplicateToClient component")
            -- see what archetypes it is, and then replicate it to everyone
            if rtcCR.new.archetypes == nil then
                -- print("RR EVENT: entity " .. id .. " has no archetypes")
                continue
            end
            -- print("RR EVENT: entity " .. id .. " has " .. #rtcCR.new.archetypes .. " archetypes")
            for _, archetypeName in ipairs(rtcCR.new.archetypes) do

                if not table.find(archetypesToReplicate, archetypeName) then
                    -- print("RR EVENT: replicating entity " .. id .. " to archetype " .. archetypeName)
                    table.insert(archetypesToReplicate, archetypeName)
                    -- print("!REPLICATING FOUND ARCHETYPE: " .. archetypeName)
                end
                -- replicationUtil.replicateServerEntityArchetypeToAll(id, archetypeName, world)
            end
        else
            table.insert(removedReplicatedIds, id)
        end
    end

    -- wait cant we just handle this on a per entity basis?
    -- no, because queryChanged only works on single components
    -- and it's impossible to do a queryChanged like behavior for a single entity :(
    -- so the above code only tracks changes to the ReplicateToClient component itself
    
    for i,v in ipairs(archetypesToReplicate) do
        matterUtil.replicateChangedArchetypes(v, world)
    end

    -- Make sure we replicate all named archetypes.
    -- For single component archetypes, we'll keep track of the ones that need replicating
    -- by adding them to a list as we notice components with the ReplicateToClient component.

    -- some function here that manages every single archetype's changed event
    if #removedReplicatedIds > 0 then
        Remotes.Server:Create("DespawnedEntities"):SendToAllPlayers(removedReplicatedIds)
    end

end