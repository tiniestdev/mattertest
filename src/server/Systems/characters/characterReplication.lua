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
    for i, player in Matter.useEvent(RequestStorageEvent, "Event") do
        print("GOT EVENT TO UPDATDSUDJSK STORGAE")
        
    end
    -- Replication of character backpack/storage
    for id, storageCR, characterC in world:queryChanged(Components.Storage, Components.Character) do
        -- does a player own this?
        local playerC = world:get(characterC.playerId, Components.Player)
        if playerC then
            local player = playerC.player
            print("SERIALIZING STORAGE ", id)
            print("STORAGECR:", storageCR)
            local payload = replicationUtil.serializeStorage(id, world)
            print("HERES THE REMOTE. DSHUIDYUIA")
            print(Remotes.Server:Create("ReplicateStorage", payload))
            print("SENDING PAYLOAD")
            Remotes.Server:Create("ReplicateStorage"):SendToPlayer(player, payload)
        end
    end
    -- Replication of player team

    -- Replication of stats like health or walkspeed

end