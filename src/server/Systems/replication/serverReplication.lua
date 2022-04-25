local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local Remotes = require(ReplicatedStorage.Remotes)

local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)

return function(world)
    local removedReplicatedIds = {}

    -- Automatically replicates changes in an entity's archetypes
    -- like if it wanted to take on a different archetype
    for id, rtcCR in world:queryChanged(Components.ReplicateToClient) do
        if rtcCR.new then
            -- print("RR: detected change of id " .. id)
            -- see what archetypes it is, and then replicate it to everyone
            if rtcCR.new.archetypes == nil then
                -- print("RR: no archetypes found for id " .. id)
                return
            end
            -- print("RR: replicating archetypes ", rtcCR.new.archetypes)
            for _, archetypeName in ipairs(rtcCR.new.archetypes) do
                replicationUtil.replicateServerEntityArchetypeToAll(id, archetypeName, world)
                -- print("RR: replicated entity " .. id .. " to archetype " .. archetypeName)
            end
        else
            table.insert(removedReplicatedIds, id)
            -- print("Despawned id ", id)
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