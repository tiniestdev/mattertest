local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)

return function(world)
    matterUtil.linkBidirectionalEntityIdRefs("Equipper", "Equippable", world)

    -- for id, equipperC in world:query(Components.Equipper) do
    --     if equipperC.doNotReconcile then
    --         world:insert(id, equipperC:patch({
    --             doNotReconcile = false,
    --         }))
    --         print("RESET:", id, equipperC.doNotReconcile)
    --     end
    -- end
end