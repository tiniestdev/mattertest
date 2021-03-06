local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

local Llama = require(ReplicatedStorage.Packages.llama)

return function(world)
    for id, grabbableCR in world:queryChanged(Components.Grabbable) do
        if grabbableCR.new then
            -- we should calculate network owners for everything attached, not just the single part
            local grabbableInstance = grabbableCR.new.grabbableInstance
            local assembly, grabbableIdsSet = grabUtil.getGrabConnections(grabbableInstance, nil, nil, world)

            local function getGrabbableStatus()
                local singularPlayer = nil
                local noGrabbers = true
                for grabbableId, _ in pairs(grabbableIdsSet) do
                    local grabbableC = world:get(grabbableId, Components.Grabbable)
                    local grabberIds = grabbableC.grabberIds
                    if not grabberIds then continue end
                    for grabberId, _ in pairs(grabberIds) do
                        noGrabbers = false
                        local player = matterUtil.getPlayerFromCharacterEntity(grabberId, world)
                        if player then
                            if singularPlayer then
                                singularPlayer = nil
                                return nil, false
                            end
                            singularPlayer = player
                        end
                    end
                end
                return singularPlayer, noGrabbers
            end

            -- apply a quick impulse toward the goal just to snap a sleeping part out of it
            -- local toGoal = state.GoalAttachment.WorldPosition - grabbableInstance.Position
            -- grabbableInstance:ApplyImpulse(toGoal * 10)
            grabbableInstance:ApplyImpulse(Vector3.new(0,1,0) * 10)

            local singularPlayer, noGrabbers = getGrabbableStatus()

            if noGrabbers then
                for id, _ in pairs(grabbableIdsSet) do
                    local networkOwnedC = world:get(id, Components.NetworkOwned)
                    world:insert(id, networkOwnedC:patch({
                        networkOwner = Matter.None,
                        auto = true,
                    }));
                end
            else
                if singularPlayer then
                    -- print("Setting network owner to " .. singularPlayer.Name)
                    for id, _ in pairs(grabbableIdsSet) do
                        local networkOwnedC = world:get(id, Components.NetworkOwned)
                        world:insert(id, networkOwnedC:patch({
                            networkOwner = singularPlayer,
                            auto = false,
                        }));
                    end
                else
                    -- print("Setting network owner to NONE")
                    for id, _ in pairs(grabbableIdsSet) do
                        local networkOwnedC = world:get(id, Components.NetworkOwned)
                        world:insert(id, networkOwnedC:patch({
                            networkOwner = Matter.None,
                            auto = false,
                        }));
                    end
                end
            end

        end
    end
end