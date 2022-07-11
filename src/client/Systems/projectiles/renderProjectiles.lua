local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Remotes = require(ReplicatedStorage.Remotes)

local randUtil = require(ReplicatedStorage.Util.randUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local cframeUtil = require(ReplicatedStorage.Util.cframeUtil)

local projRenderEvent = matterUtil.NetSignalToEvent("RenderProjectile", Remotes)

return function(world, _, ui)
    -- Cleanup dead projectiles
    for id, projectileCR in world:queryChanged(Components.Projectile) do
        if not projectileCR.new or projectileCR.new.dead then
            projectileUtil.unrenderProjectile(id)
        end
    end

    -- Render bullets that were created and destroyed very close to eachother
    -- man screw this im just gonna focus on functionality
    -- for id, startPos, endPos in Matter.useEvent(projRenderEvent, "Event") do
    --     projectileUtil.renderProjectile(id, projectileC)
    --     table.insert(deactivate, {id, projectileC})
    --     projectileUtil.renderProjectile(id, projectileC)
    -- end

    -- Deactivate projectiles that should wait for server updates
    local deactivate = {}
    for id, projectileC in world:query(Components.Projectile) do
        if not projectileC.active then continue end
        local stepResults = projectileUtil.stepProjectileUntilHit(id, projectileC, Matter.useDeltaTime(), world)
        projectileUtil.renderProjectile(id, projectileC)
        local shouldDeactivate = stepResults.hit
        if shouldDeactivate then
            table.insert(deactivate, {id, projectileC})
        end
    end
    for _, pair in ipairs(deactivate) do
        world:insert(pair[1], pair[2]:patch({
            active = false
        }))
    end
end
