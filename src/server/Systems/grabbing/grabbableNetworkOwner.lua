local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)

local Set = Llama.Set

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

return function(world)
    for id, grabbableCR in world:queryChanged(Components.Grabbable) do
        if grabbableCR.new then
            local grabbableInstance = grabbableCR.new.grabbableInstance
            local grabberIds = grabbableCR.new.grabberIds
            if not grabberIds then continue end

            local singularPlayer = nil
            for grabberId, v in pairs(grabberIds) do
                local player = matterUtil.getPlayerFromCharacterEntity(grabberId, world)
                if player then
                    if singularPlayer then
                        singularPlayer = nil
                        break
                    end
                    singularPlayer = player
                end
            end

            -- print("singularPlayer: ", singularPlayer)
            if singularPlayer then
                grabbableInstance:SetNetworkOwner(singularPlayer)
                -- Disable server influence and leave it all to the client.
                -- the alignpositions  are made both on client and server.... we should tag em so server ones are disabled on client
                for i,v in ipairs(grabUtil.getServerOwnedGrabConnections(grabbableInstance)) do
                    v.Enabled = false
                end
            else
                -- Force enable server influence
                grabbableInstance:SetNetworkOwner(nil)
                for i,v in ipairs(grabUtil.getServerOwnedGrabConnections(grabbableInstance)) do
                    v.Enabled = true
                end
            end
            -- local foundPlayer = matterUtil.getPlayerFromCharacterEntity(grabberId, world)
            -- grabbableInstance:SetNetworkOwner(foundPlayer)
        end
    end
    -- if RunService:IsServer() then
    --     local foundPlayer = matterUtil.getPlayerFromCharacterEntity(grabberId, world)
    --     if foundPlayer then
    --         grabbableInstance:SetNetworkOwner(foundPlayer)
    --     end
    -- end
end