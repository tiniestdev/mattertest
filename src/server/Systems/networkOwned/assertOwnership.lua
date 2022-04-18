local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

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
    for id, networkOwnedCR in world:queryChanged(Components.NetworkOwned) do
        if networkOwnedCR.new then
            -- print("NETWORK CHANGED TO ", networkOwnedCR.new.networkOwner)
            local instanceList = tableUtil.FlipNumeric(networkOwnedCR.new.instances)
            physicsUtil.DeepSetNetworkOwner(instanceList, networkOwnedCR.new.networkOwner)
        else
            -- deleted. just set to auto
            local instanceList = tableUtil.FlipNumeric(networkOwnedCR.old.instances)
            local success, msg = pcall(function()
                physicsUtil.DeepTask(instanceList, function(part)
                    part:SetNetworkOwnershipAuto()
                end)
            end)
        end
    end
end