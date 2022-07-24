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
local drawUtil = require(ReplicatedStorage.Util.drawUtil)

local projRenderEvent = matterUtil.NetSignalToEvent("RenderProjectile", Remotes)
local initProjEvent = matterUtil.NetSignalToEvent("InitialProjectileCFrames", Remotes)

local getProjectileState = require(ReplicatedStorage.HookStates.getProjectileState)

local bulletsTickIds = {}
local initBulletPos = {}

return function(world, _, ui)

    -- The client will likely have to catch up with the server bullet since it's replicated after the bullet has
    -- moved from its starting point
    -- so it will recieve the true starting position and will use this info to render the entire bullet
    -- once it actually replicates the bullet
    for id, infos in Matter.useEvent(initProjEvent, "Event") do
        for i, info in ipairs(infos) do
            initBulletPos[info[1]] = info[2]
        end
    end

    -- apply init cframes to server created bullets
    -- Cleanup dead projectiles
    local applyInitBullets = {}
    for id, projectileCR in world:queryChanged(Components.Projectile) do
        if projectileCR.new then

            if not projectileCR.old then
                if world:get(id, Components.Ours) then
                    -- This is locally created
                    local creationTagC = world:get(id, Components.CreationTag)
                    if not creationTagC then
                        warn("NO CREATION TAG REALLY WTF!!!!!!!!!", id)
                        continue
                    end
                    local tickId = tick()
                    bulletsTickIds[id] = {tickId, creationTagC.creatorId}
                    -- translate to server entity
                    local serverId = replicationUtil.recipientIdToSenderId(creationTagC.creatorId)
                    Remotes.Client:Get("ProposeProjectile"):SendToServer(projectileCR.new, tickId, serverId)
                    projectileUtil.renderProjectile(id, projectileCR.new)
                else
                    -- This was server created
                    -- If it has an init record, apply it
                    local serverId = replicationUtil.recipientIdToSenderId(id)
                    local initCFrame = initBulletPos[serverId]
                    table.insert(applyInitBullets, {id, projectileCR.new, initCFrame})
                    initBulletPos[id] = nil
                end
            end

            if projectileCR.new.dead or not projectileCR.new.active then
                -- do a quick render of a path
                task.defer(function()
                    -- print("quickrenderbegin")
                    projectileUtil.renderProjectile(id, projectileCR.new)
                    -- local collisionCFrame = projectileCR.new.cframe
                    task.delay(0, function()
                        -- print("unrendering after delay")
                        projectileUtil.unrenderProjectile(id)
                    end)
                end)
                -- local lastPos = projectileCR.old.cframe.Position
                -- local newPos = projectileCR.new.cframe.Position
                -- local 
                -- projectileUtil.unrenderProjectile(id)
            end
        else
            projectileUtil.unrenderProjectile(id)
        end
    end

    for i, info in ipairs(applyInitBullets) do
        local id = info[1]
        local projectileC = info[2]
        local initCFrame = info[3]
        world:insert(id, projectileC:patch({
            cframe = initCFrame,
        }))
        -- print("applied init record to", id)
        -- drawUtil.point(initCFrame.p, Color3.new(0, 0, 1), nil, 0.2)
    end

    -- Render bullets that were created and destroyed very close to eachother
    -- man screw this im just gonna focus on functionality
    -- for id, startPos, endPos in Matter.useEvent(projRenderEvent, "Event") do
    --     projectileUtil.renderProjectile(id, projectileC)
    --     table.insert(deactivate, {id, projectileC})
    --     projectileUtil.renderProjectile(id, projectileC)
    -- end

    local stepResultsMap = {}
    for id, projectileC in world:query(Components.Projectile) do
        if not projectileC.active then continue end
        projectileUtil.renderProjectile(id, projectileC)
        -- if not world:get(id, Components.Ours) then
        --     drawUtil.point(projectileC.cframe, Color3.new(0, 1, 1), nil, 0.5)
        -- end
        stepResultsMap[id] = projectileUtil.stepProjectileUntilHit(id, projectileC, Matter.useDeltaTime(), world)
    end

    -- Deactivate projectiles that should wait for server updates
    local deactivate = {}
    for id, projectileC in world:query(Components.Projectile) do
        if not projectileC.active then continue end
        -- projectileUtil.renderProjectile(id, projectileC)
        
        local stepResults = stepResultsMap[id]
        local shouldDeactivate = stepResults.hit

        if shouldDeactivate then
            local oursC = world:get(id, Components.Ours)
            if oursC then
                -- it's ours, but there is no recorded creatorId, and this happens for a bunch of bullets apparently
                -- ig the true solution is to delete them?
                local creatorId = bulletsTickIds[id] and bulletsTickIds[id][2] or nil
                if not creatorId then
                    warn("NO CREATOR ID FOR BULLET!!!!!!!!!", id)
                    table.insert(deactivate, {id, projectileC, true})
                    continue
                end
                local serverId = replicationUtil.recipientIdToSenderId(creatorId)
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
            -- drawUtil.point(projectileC.cframe.Position, Color3.new(1,0,0))
        -- else
            -- drawUtil.point(projectileC.cframe.Position, Color3.new(1,1,1))
        end
    end

    for _, pair in ipairs(deactivate) do
        world:insert(pair[1], pair[2]:patch({
            active = false
        }))
        if pair[3] then
            -- give it time to draw its path
            task.delay(0.5, function()
                world:despawn(pair[1])
            end)
        end
    end
end
