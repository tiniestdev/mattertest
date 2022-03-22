local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

local RequestStorageEvent = MatterUtil.NetSignalToEvent("RequestStorage", Remotes)

return function(world)
    -- Replication of character backpack/storage
    -- This only replicates a player's own backpack towards the player and no one else
    for characterId, storageCR, characterC in world:queryChanged(Components.Storage, Components.Character) do
        -- does a player own this?
        local playerC = world:get(characterC.playerId, Components.Player)
        if playerC then
            local player = playerC.player
            local payload = replicationUtil.serializeArchetype("Storage", characterId, replicationUtil.SERVERSCOPE, characterId, world)
            Remotes.Server:Create("ReplicateStorage"):SendToPlayer(player, payload)
        end
    end
    -- Replication of player team

    -- Replication of stats like health or walkspeed

end