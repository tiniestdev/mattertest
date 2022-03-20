local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    for id, storableCR, corporealC in world:queryChanged(Components.Storable, Components.Corporeal) do
        print("StorageId of storableCR:", storableCR.new.storageId)
        if storableCR.new.storageId then
            world:insert(id, corporealC:patch({
                purgatory = true
            }))
        else
            world:insert(id, corporealC:patch({
                purgatory = false
            }))
        end
    end
end