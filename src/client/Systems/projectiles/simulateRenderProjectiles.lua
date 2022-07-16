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

local bulletsTickIds = {}

return function(world, _, ui)
    -- Cleanup dead projectiles
    for id, projectileCR in world:queryChanged(Components.Projectile) do
        if projectileCR.new then
            if not projectileCR.old and world:get(id, Components.Ours) then
                local creationTagC = world:get(id, Components.CreationTag)
                if not creationTagC then
                    warn("NO CREATION TAG REALLY WTF!!!!!!!!!", id)
                    continue
                end
                local tickId = tick()
                bulletsTickIds[id] = {tickId, creationTagC.creatorId}
                -- translate to server entity
                local serverScopeId = replicationUtil.getScopeIdentifierFromRecipientId(creationTagC.creatorId, world)
                Remotes.Client:Get("ProposeProjectile"):SendToServer(projectileCR.new, tickId, serverScopeId.identifier)
            end
            if projectileCR.new.dead or not projectileCR.new.active then
                projectileUtil.unrenderProjectile(id)
            end
        else
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
            local oursC = world:get(id, Components.Ours)
            if oursC then
                local creatorId = bulletsTickIds[id] and bulletsTickIds[id][2] or nil
                if not creatorId then
                    warn("NO CREATOR ID FOR BULLET!!!!!!!!!", id)
                    continue
                end
                local serverId = replicationUtil.getScopeIdentifierFromRecipientId(creatorId, world)
                Remotes.Client:Get("ProposeProjectileHit"):SendToServer(
                    projectileC,
                    bulletsTickIds[id][1],
                    serverId,
                    stepResults.Instance,
                    stepResults.Position,
                    stepResults.Normal
                )
                bulletsTickIds[id] = nil
            end
            table.insert(deactivate, {id, projectileC, oursC and true})
        end
    end

    for _, pair in ipairs(deactivate) do
        world:insert(pair[1], pair[2]:patch({
            active = false
        }))
        if pair[3] then
            world:despawn(pair[1])
        end
    end
end
