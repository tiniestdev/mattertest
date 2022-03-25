local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local Remotes = require(ReplicatedStorage.Remotes)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    local removedReplicatedIds = {}
    for id, replicatedCR in world:queryChanged(Components.Replicated) do
        -- print(replicatedCR)
        if not replicatedCR.new then
            table.insert(removedReplicatedIds, id)
            print("Despawned id ", id)
        end
    end
    if #removedReplicatedIds > 0 then
        Remotes.Server:Create("DespawnedEntities"):SendToAllPlayers(removedReplicatedIds)
    end
end