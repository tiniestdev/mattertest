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

    local newBulletCFrames = {}
    for id, projectileCR in world:queryChanged(Components.Projectile) do
        if projectileCR.new and not projectileCR.old then
            -- replicate first time bullets
            table.insert(newBulletCFrames, {id, projectileCR.new.cframe})
        end
    end

    if #newBulletCFrames > 0 then
        Remotes.Server:Create("InitialProjectileCFrames"):SendToAllPlayers(newBulletCFrames)
    end

    local stepResultsMap = {}
    for id, projectileC in world:query(Components.Projectile) do
        if not projectileC.active then continue end
        stepResultsMap[id] = projectileUtil.stepProjectile(id, projectileC, Matter.useDeltaTime(), world)
    end
    
    local interactions = {}
    for id, projectileC in world:query(Components.Projectile) do
        if not projectileC.active then continue end
        local stepResults = stepResultsMap[id]

        if stepResults.destroyed then
            table.insert(deadBullets, id)
        end

        if stepResults.updateReplication then
            local rtcC = world:get(id, Components.ReplicateToClient)
            if rtcC then
                world:insert(id,
                    -- projectileC:patch({
                    --     lastCFrame = lastCFrame,
                    -- }),
                    rtcC:patch({
                        replicateFlag = true,
                    })
                )
            end
        end

        if stepResults.interactions then
            table.insert(interactions, {id, stepResults.interactions})
        end
    end

    if #interactions > 0 then
        Remotes.Server:Create("ProjectileInteractions"):SendToAllPlayers(interactions)
        Intercom.Get("ProjectileInteractions"):Fire(interactions)
    end

    for _, id in ipairs(deadBullets) do
        local projC = world:get(id, Components.Projectile)
        if not projC.dead then
            world:insert(id, projC:patch({
                active = false,
                dead = true,
            }))
            -- we JUST died
            local rtcC = world:get(id, Components.ReplicateToClient)
            if rtcC then
                world:insert(id, rtcC:patch({
                    replicateFlag = true,
                }))
            end
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