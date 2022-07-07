local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

return function(world)
    -- for id, networkOwnedC in world:query(Components.NetworkOwned) do
    --     if Matter.useThrottle(1, id) then
    --         local instances = networkOwnedC.instances
    --         if instances then
    --             -- print(id, networkOwnedC)
    --             if matterUtil.isNone(networkOwnedC.networkOwner) then
    --                 physicsUtil.DeepSetNetworkOwner(instances, nil)
    --                 print("controlled by NO ONE")
    --             else
    --                 physicsUtil.DeepSetNetworkOwner(instances, networkOwnedC.networkOwner)
    --                 print("controlled by", networkOwnedC.networkOwner)
    --             end
    --         end
    --     end
    -- end

    for id, networkOwnedCR in world:queryChanged(Components.NetworkOwned) do
        if networkOwnedCR.new then
            local networkOwnedC = networkOwnedCR.new
            local instances = networkOwnedC.instances
            if instances then
                -- print(networkOwnedC.networkOwner)
                if matterUtil.isNone(networkOwnedC.networkOwner) then
                    if networkOwnedC.auto then
                        physicsUtil.DeepSetNetworkOwnerAuto(instances)
                    else
                        physicsUtil.DeepSetNetworkOwner(instances, nil)
                    end
                    -- print("controlled by NO ONE")
                else
                    physicsUtil.DeepSetNetworkOwner(instances, networkOwnedC.networkOwner)
                    -- print("controlled by", networkOwnedC.networkOwner)
                    -- task.delay(0.5, function()
                        -- physicsUtil.DeepSetNetworkOwner(instances, networkOwnedC.networkOwner)
                        -- print("controlled by (2) ", networkOwnedC.networkOwner)
                    -- end)
                end
                -- physicsUtil.DeepSetNetworkOwner(instances, networkOwnedC.networkOwner)
            end
        else
            local instances = networkOwnedCR.old.instances
            if instances then
                local success, msg = pcall(function()
                    physicsUtil.DeepTask(instances, function(part)
                        part:SetNetworkOwnershipAuto()
                    end)
                end)
            end
        end
    end
end