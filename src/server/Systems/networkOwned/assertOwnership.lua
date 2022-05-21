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
    -- for id, networkOwnedC, characterC in world:query(Components.NetworkOwned, Components.Character) do
    --     if Matter.useThrottle(5) then
    --         if networkOwnedC.networkOwner then
    --             world:insert(id, networkOwnedC:patch({
    --                 networkOwner = Matter.None,
    --             }))
    --         else
    --             world:insert(id, networkOwnedC:patch({
    --                 networkOwner = world:get(characterC.playerId, Components.Player).player,
    --             }))
    --         end
    --         print("gave back control to", world:get(id, Components.NetworkOwned).networkOwner)
    --     end
    -- end
    for id, networkOwnedC in world:query(Components.NetworkOwned) do
        if Matter.useThrottle(0.5) then
            local instances = networkOwnedC.instances
            if instances then
                if networkOwnedC.networkOwner == Llama.None or networkOwnedC.networkOwner == Matter.None or
                (not networkOwnedC.networkOwner) then
                -- typeof(networkOwnedC.networkOwner) == "Instance" and networkOwnedC.networkOwner:IsA("Player") then
                    physicsUtil.DeepSetNetworkOwner(instances, nil)
                    print("controlled by NO ONE")
                else
                    physicsUtil.DeepSetNetworkOwner(instances, networkOwnedC.networkOwner)
                    print("controlled by", networkOwnedC.networkOwner)
                end
            end
        end
    end

    for id, networkOwnedCR in world:queryChanged(Components.NetworkOwned) do
        if networkOwnedCR.new then
            -- print("NETWORK CHANGED TO ", networkOwnedCR.new.networkOwner)
            -- local instanceList = tableUtil.FlipNumeric(networkOwnedCR.new.instances)
            local instances = networkOwnedCR.new.instances
            if instances then
                physicsUtil.DeepSetNetworkOwner(instances, networkOwnedCR.new.networkOwner)
            end
        else
            -- deleted. just set to auto
            -- local instances = tableUtil.FlipNumeric(networkOwnedCR.old.instances)
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