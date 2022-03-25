local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local Remotes = require(ReplicatedStorage.Remotes)
local Rx = require(ReplicatedStorage.Packages.rx)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

local DespawnedEntitiesEvent = MatterUtil.NetSignalToEvent("DespawnedEntities", Remotes)

return function(world)
    for _, listOfEntities in Matter.useEvent(DespawnedEntitiesEvent, "Event") do
        Rx.from(listOfEntities):Pipe({
            Rx.map(function(entityId)
                local recipientId = replicationUtil.senderIdToRecipientId(entityId)
                if not recipientId then
                    warn("Could not find recipient id for entity id " .. entityId)
                end
                return recipientId
            end),
        }):Subscribe(function(recipientId)
            world:despawn(recipientId)
            print("Despawned local entity ", recipientId)
        end)
    end
end