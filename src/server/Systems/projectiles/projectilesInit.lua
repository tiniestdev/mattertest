local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local Intercom = require(ReplicatedStorage.Intercom)
local randUtil = require(ReplicatedStorage.Util.randUtil)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)

return function(world, _, ui)
    local deadBullets = {}
    -- local updateBullets = {}

    for id, projectileC in world:query(Components.Projectile) do
        if not projectileC.active then continue end
        local stepResults = projectileUtil.stepProjectile(id, projectileC, Matter.useDeltaTime(), world)
        if stepResults.destroyed then
            table.insert(deadBullets, id)
        end
        if stepResults.updateReplication then
            local rtcC = world:get(id, Components.ReplicateToClient)
            if rtcC then
                world:insert(id, rtcC:patch({
                    replicateFlag = true,
                }))
            end
        end
        if stepResults.interactions then
            Remotes.Server:Create("ProjectileInteractions"):SendToAllPlayers(stepResults.interactions, id)
            Intercom.Get("ProjectileInteractions"):Fire(stepResults.interactions, id)
        end
    end

    for _, id in ipairs(deadBullets) do
        local projC = world:get(id, Components.Projectile)
        if not projC.dead then
            world:insert(id, projC:patch({
                active = false,
                dead = true,
            }))
            task.delay(1, function()
                world:despawn(id)
            end)
        end
    end

    -- for _, pair in ipairs(updateBullets) do
    --     world:insert(pair[1], pair[2]:patch({
    --         replicateFlag = true,
    --     }))
    -- end
end