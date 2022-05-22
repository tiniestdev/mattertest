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
                if singularPlayer then
                    print("SINGULAR PLAYER: ", singularPlayer)
                    world:insert(id, Components.NetworkOwned({
                        networkOwner = singularPlayer,
                        instances = grabbableInstance,
                    }));
                    for i,v in ipairs(grabUtil.getServerOwnedGrabConnections(grabbableInstance)) do
                        v.Enabled = false
                    end
                else
                    -- Force enable server influence
                    print("NO SINGULAR PLAYER")
                    world:insert(id, Components.NetworkOwned({
                        networkOwner = Matter.None,
                        instances = grabbableInstance,
                    }));
                    for i,v in ipairs(grabUtil.getServerOwnedGrabConnections(grabbableInstance)) do
                        v.Enabled = true
                    end
                end
            end

        end
    end
end