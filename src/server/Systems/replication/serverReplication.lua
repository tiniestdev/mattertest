local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local Remotes = require(ReplicatedStorage.Remotes)

local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)

local RequestReplicateEntities = matterUtil.NetSignalToEvent("RequestReplicateEntities", Remotes)

return function(world)
    local removedReplicatedIds = {}

    -- force replicate entities that a client is currently missing
    for i, player, listOfEntityIds in Matter.useEvent(RequestReplicateEntities, "Event") do
        print("GOT REQUEST FROM PLAYER TO REPLICATE ENTITIES", player, listOfEntityIds)
        for _, entityId in ipairs(listOfEntityIds) do
            local rtcC = world:get(entityId, Components.ReplicateToClient)
            print("1")
            if rtcC then
                print("2")
                for _, archetypeName in ipairs(rtcC.archetypes) do
                    print("3")
                    replicationUtil.replicateServerEntityArchetypeTo(player, entityId, archetypeName, world)
                    print("RR EVENT: replicated entity " .. entityId .. " to archetype " .. archetypeName)
                end
            end
        end
    end

    -- Automatically replicates changes in an entity's archetypes
    -- like if it wanted to take on a different archetype
    for id, rtcCR in world:queryChanged(Components.ReplicateToClient) do
        if rtcCR.new then
            -- see what archetypes it is, and then replicate it to everyone
            if rtcCR.new.archetypes == nil then
                return
            end
            for _, archetypeName in ipairs(rtcCR.new.archetypes) do
                replicationUtil.replicateServerEntityArchetypeToAll(id, archetypeName, world)
            end
        else
            table.insert(removedReplicatedIds, id)
        end
    end

    matterUtil.replicateChangedArchetypes("Alliance", world)
    matterUtil.replicateChangedArchetypes("Team", world)
    matterUtil.replicateChangedArchetypes("PlayerArchetype", world)
    matterUtil.replicateChangedArchetypes("CharacterArchetype", world)

    -- some function here that manages every single archetype's changed event
    if #removedReplicatedIds > 0 then
        Remotes.Server:Create("DespawnedEntities"):SendToAllPlayers(removedReplicatedIds)
    end
end