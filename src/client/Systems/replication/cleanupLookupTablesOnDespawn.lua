local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

return function(world)
    for id, _ in world:queryChanged(Components.Replicated) do
        if not world:contains(id) then
            local senderId = replicationUtil.recipientIdToSenderId(id)
            if senderId then
                -- print("CLEANUP: REMOVING SERVER ", senderId)
                replicationUtil.removeSenderId(senderId)
            end
            
            -- this is prob redundant but whatever
            -- print("CLEANUP: REMOVING ", id)
            replicationUtil.removeRecipientId(id)
        end
    end
end