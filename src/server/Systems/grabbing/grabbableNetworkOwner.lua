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
            local noGrabbers = true

            for grabberId, v in pairs(grabberIds) do
                noGrabbers = false
                local player = matterUtil.getPlayerFromCharacterEntity(grabberId, world)
                if player then
                    if singularPlayer then
                        singularPlayer = nil
                        break
                    end
                    singularPlayer = player
                end
            end

            if noGrabbers then
                print("NO GRABBERS, AUTO")
                grabbableInstance:SetNetworkOwnershipAuto()
                world:remove(id, Components.NetworkOwned)
            else
                -- grabbableInstance:SetNetworkOwnershipAuto(false)
                if singularPlayer then
                    print("SINGULAR PLAYER: ", singularPlayer)
                    task.delay(0, function()
                        grabbableInstance:SetNetworkOwner(singularPlayer)
                    end)
                    world:insert(id, Components.NetworkOwned({
                        networkOwner = singularPlayer,
                        instances = grabbableInstance,
                    }));
                    -- Disable server influence and leave it all to the client.
                    -- the alignpositions  are made both on client and server.... we should tag em so server ones are disabled on client
                    for i,v in ipairs(grabUtil.getServerOwnedGrabConnections(grabbableInstance)) do
                        v.Enabled = false
                    end
                else
                    -- Force enable server influence
                    print("NO SINGULAR PLAYER")
                    task.delay(0, function()
                        grabbableInstance:SetNetworkOwner()
                    end)
                    world:insert(id, Components.NetworkOwned({
                        networkOwner = Matter.None,
                        instances = grabbableInstance,
                    }));
                    for i,v in ipairs(grabUtil.getServerOwnedGrabConnections(grabbableInstance)) do
                        v.Enabled = true
                    end
                end
            end

            -- print("singularPlayer: ", singularPlayer)
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