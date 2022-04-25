local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)

return function(world)
    for id, instanceCR, networkOwnedC in world:queryChanged(Components.Instance, Components.NetworkOwned) do
        if instanceCR.new then
            -- new instance, add it
            world:insert(id, networkOwnedC:patch({
                instances = Llama.Set.add(networkOwnedC.instances, unpack(physicsUtil.GetParts(instanceCR.new.instance)))
            }))
            -- print("# ADDED")
            -- print(world:get(id, Components.NetworkOwned).instances)
        else
            -- remove from networkowned list
            world:insert(id, networkOwnedC:patch({
                instances = Llama.Set.subtract(networkOwnedC.instances, unpack(physicsUtil.GetParts(instanceCR.old.instance)))
            }))
            -- print("# REMOVED")
            -- print(world:get(id, Components.NetworkOwned).instances)
        end
    end
    for id, networkOwnedCR, instanceC in world:queryChanged(Components.NetworkOwned, Components.Instance) do
        if not networkOwnedCR.old then
            -- new, add it
            world:insert(id, networkOwnedCR.new:patch({
                instances = Llama.Set.add(networkOwnedCR.new.instances, unpack(physicsUtil.GetParts(instanceC.instance)))
            }))
            -- print("# ADDED NETWONED")
            -- print(world:get(id, Components.NetworkOwned).instances)
        end
        if not networkOwnedCR.new then
            -- do nothing
        end
    end
end