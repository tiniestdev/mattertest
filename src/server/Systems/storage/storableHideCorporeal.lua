local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    for id, storableCR in world:queryChanged(Components.Storable) do
        if storableCR.new then
            local corporealC = world:get(id, Components.Corporeal)
            if not corporealC then continue end

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
end