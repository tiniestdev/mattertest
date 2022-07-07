local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local randUtil = require(ReplicatedStorage.Util.randUtil)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)

return function(world, _, ui)
    local deadBullets = {}
    local updateBullets = {}
    for id, projectileC in world:query(Components.Projectile) do
        local stepResults = projectileUtil.stepProjectile(id, projectileC, Matter.useDeltaTime(), world)
        if stepResults.destroyed then
            table.insert(deadBullets, id)
            -- projectileUtil.unrenderProjectile(id)
        end
        if stepResults.updateReplication then
            local rtcC = world:get(id, Components.ReplicateToClient)
            if rtcC then
                -- table.insert(updateBullets, {id, rtcC})
                world:insert(id, rtcC:patch({
                    replicateFlag = true,
                }))
            end
        end
        if stepResults.bounceEvents then
            for _, bounceEvent in ipairs(stepResults.bounceEvents) do
                Remotes.Server:Create("BounceFX"):SendToAllPlayers(bounceEvent[1], bounceEvent[2], id)
            end
        end
        -- projectileUtil.renderProjectile(id, projectileC)
    end

    for _, id in ipairs(deadBullets) do
        -- print("Despawning projectile ", id)
        world:despawn(id)
    end

    for _, pair in ipairs(updateBullets) do
        world:insert(pair[1], pair[2]:patch({
            replicateFlag = true,
        }))
    end
end