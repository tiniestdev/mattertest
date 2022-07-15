local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Constants = require(ReplicatedStorage.Constants)
local Assets = ReplicatedStorage.Assets

local RoundInfos = require(ReplicatedStorage.RoundInfos)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local randUtil = require(ReplicatedStorage.Util.randUtil)
local vecUtil = require(ReplicatedStorage.Util.vecUtil)
local cframeUtil = require(ReplicatedStorage.Util.cframeUtil)

local projectileUtil = {}

function projectileUtil.fireRound(cframe, velocity, roundName, ignoreList, world)
    roundName = roundName or "Default"
    local roundInfo = RoundInfos.Catalog[roundName]
    assert(roundInfo, "No round info for " .. roundName)

    local id = world:spawn()
    for componentName, componentInfo in pairs(roundInfo) do
        local componentInfo = tableUtil.CopyShallow(componentInfo)

        if componentName == "Projectile" then
            componentInfo.active = true -- this should stay enabled on server
            -- the client can disable this though
            componentInfo.cframe = cframe
            componentInfo.velocity = velocity

            componentInfo.life = 0
            componentInfo.bounces = 0
            componentInfo.traveledDistance = 0
            componentInfo.penetratedDistance = 0

		    componentInfo.ignoreList = ignoreList or {}
            componentInfo.trailWidth = componentInfo.trailWidth or 0.1
            componentInfo.gravity = componentInfo.gravity or Vector3.new(0, -workspace.Gravity, 0)
            componentInfo.lifetime = componentInfo.lifetime or 10
            componentInfo.maxDistance = componentInfo.maxDistance or 500
            componentInfo.minBounces = componentInfo.minBounces or 0
            componentInfo.bounceChance = componentInfo.bounceChance or 0.1
            componentInfo.maxBounces = componentInfo.maxBounces or 1
            componentInfo.elasticity = componentInfo.elasticity or 0.7
            componentInfo.penetration = componentInfo.penetration or 0.5
            componentInfo.collisionGroup = componentInfo.collisionGroup or "Default"
        end
        -- for i,v in pairs(componentInfo) do
        --     if typeof(v) == "Instance" then
        --         componentInfo[i] = v:Clone()
        --     end
        -- end

        world:insert(id, Components[componentName](componentInfo))
    end
    world:insert(id, Components.ReplicateToClient({
        archetypes = {"BulletArchetype"},
        disabled = true,
        replicateFlag = true, -- should immeidately replicate to client upon spawn
    }))

    return id
end

function projectileUtil.castResultOfProjectile(projectileId, projectileC, overrideCurrCFrame, overrideCurrVelocity, timeDelta, params)
    if not params then
        params = RaycastParams.new()
        params.CollisionGroup = projectileC.collisionGroup
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = projectileC.ignoreList
    end
    local newOffset = (overrideCurrVelocity or projectileC.velocity) * timeDelta
    return workspace:Raycast((overrideCurrCFrame.Position or projectileC.cframe.Position), newOffset, params) or {
        Position = (overrideCurrCFrame.Position or projectileC.cframe.Position) + newOffset,
    }
end

function projectileUtil.stepProjectileUntilHit(projectileId, projectileC, timeDelta, world)
    if projectileC.traveledDistance >= projectileC.maxDistance then
        return {
            hit = true,
        }
    end

    local totalStepTravelDistance = projectileC.velocity.Magnitude * timeDelta
    local distanceToTravel = totalStepTravelDistance
    local MAX_ITERS = projectileC.maxBounces + 10
    local iters = 0

    local currCFrame = projectileC.cframe
    local currVelocity = projectileC.velocity
    local gravity = projectileC.gravity
    local life = projectileC.life

    -- local events = {}
    local hit = false
    local castResult
    local params = RaycastParams.new()
    params.CollisionGroup = projectileC.collisionGroup
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = projectileC.ignoreList

    while (not hit) and (distanceToTravel > 0) and (iters < MAX_ITERS) do
        castResult = projectileUtil.castResultOfProjectile(projectileId, projectileC, currCFrame, currVelocity, timeDelta, params)
        local finalPos = castResult.Position
        if castResult.Instance then
            hit = true
        end

        local actualDistanceTraveled = (finalPos - currCFrame.Position).Magnitude
        distanceToTravel = distanceToTravel - actualDistanceTraveled

        currCFrame = CFrame.new(finalPos, finalPos + currVelocity)
        currVelocity = currVelocity + (gravity * timeDelta)
        iters = iters + 1
    end

    world:insert(projectileId, projectileC:patch({
        cframe = currCFrame,
        velocity = currVelocity,
        traveledDistance = totalStepTravelDistance,
        life = life + timeDelta,
    }))

    return {
        hit = hit,
    }
end

function projectileUtil.stepProjectile(projectileId, projectileC, timeDelta, world)
    if projectileC.traveledDistance >= projectileC.maxDistance then
        -- print("destroying due to distance")
        return {
            updateReplication = true,
            destroyed = true,
        }
    end

    local totalStepTravelDistance = projectileC.velocity.Magnitude * timeDelta
    local distanceToTravel = totalStepTravelDistance
    local MAX_ITERS = projectileC.maxBounces + 20
    local iters = 0

    local currCFrame = projectileC.cframe
    local currVelocity = projectileC.velocity
    local gravity = projectileC.gravity
    local bounces = projectileC.bounces
    local life = projectileC.life
    local currPenetration = projectileC.penetratedDistance

    local interactions = {}
    local destroyed = false
    local updateReplication = false
    local params = RaycastParams.new()
    params.CollisionGroup = projectileC.collisionGroup
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = projectileC.ignoreList

    while (not destroyed) and (distanceToTravel > 0) and (iters < MAX_ITERS) do
        local castResult = projectileUtil.castResultOfProjectile(projectileId, projectileC, currCFrame, currVelocity, timeDelta, params)
        local finalPos = castResult.Position

        if castResult.Instance then
            finalPos = castResult.Position
            updateReplication = true
            local surfaceNormal = castResult.Normal
            -- EVENT MOMENT????????

            if (bounces < projectileC.maxBounces and randUtil.getChance(projectileC.bounceChance))
            or (bounces < projectileC.minBounces) then

                -- reflect like a mirror, but roughen up surfaceNormal
                local normalCFrame = CFrame.new(finalPos, finalPos + surfaceNormal)
                local maxAngleOffset = math.rad(15)
                local theta = randUtil.getNum() * math.pi * 2
                local phi = maxAngleOffset * randUtil.getNum(-1,1)
                surfaceNormal = (normalCFrame * CFrame.Angles(0, phi, theta)).LookVector
                
                table.insert(interactions, {
                    hitPos = finalPos,
                    hitNormal = surfaceNormal,
                    hitInstance = castResult.Instance,
                    hitVelocity = currVelocity,
                    projectileMass = projectileC.mass,
                    hitDied = false,
                })

                -- theta is any angle chosen to reflect in the direction towards
                -- phi is the angle it should deviate from the normal
                -- rotate the normal by theta
                currVelocity = cframeUtil.reflectOffNormal(currVelocity, surfaceNormal) * projectileC.elasticity
                -- nudge the finalPos outward in preparation for reflecting
                finalPos = finalPos + (currVelocity * Constants.EPSILON)
                -- currVelocity = Vector3.new(0,500,0)
                bounces = bounces + 1
            elseif currPenetration < projectileC.penetration then
                -- attempt to penetrate
                -- TODO
                -- print("destroyed from penetrated")
                destroyed = true
                table.insert(interactions, {
                    hitPos = finalPos,
                    hitNormal = surfaceNormal,
                    hitInstance = castResult.Instance,
                    hitVelocity = currVelocity,
                    projectileMass = projectileC.mass,
                    hitDied = true,
                })
                -- local castResult = workspace:Raycast(currCFrame.Position, newOffset, params)
            else
                -- can't penetrate, can't bounce
                -- print("destroyed from interaction")
                destroyed = true
                table.insert(interactions, {
                    hitPos = finalPos,
                    hitNormal = surfaceNormal,
                    hitInstance = castResult.Instance,
                    hitVelocity = currVelocity,
                    projectileMass = projectileC.mass,
                    hitDied = true,
                })
            end
        end

        local actualDistanceTraveled = (finalPos - currCFrame.Position).Magnitude
        -- local timeDeltaUsedUp = timeDelta * (actualDistanceTraveled / totalStepTravelDistance)
        -- there's probably some edge case here about actualDistanceTraveled being
        -- more than needed to satisfy distanceToTravel but whatever idc
        distanceToTravel = distanceToTravel - actualDistanceTraveled

        currCFrame = CFrame.new(finalPos, finalPos + currVelocity)
        currVelocity = currVelocity + (gravity * timeDelta)

        iters = iters + 1
    end

    world:insert(projectileId, projectileC:patch({
        cframe = currCFrame,
        velocity = currVelocity,
        traveledDistance = projectileC.traveledDistance + totalStepTravelDistance,
        bounces = bounces,
        life = life + timeDelta,
    }))

    return {
        updateReplication = updateReplication,
        destroyed = destroyed,
        interactions = interactions,
    }
end

local bulletStores = {}
local function cleanupStorage(id)
    if bulletStores[id] then
        bulletStores[id].destroyed = true
        local storage = bulletStores[id]
        storage.Beam:Destroy()

        if storage.Trail then
            task.delay(storage.Trail.Lifetime, function()
                -- storage.Trail:Destroy()
                for i,v in pairs(storage) do
                    if typeof(v) == "Instance" then
                        v:Destroy()
                    end
                end
            end)
        end
        bulletStores[id] = nil
    -- else
        -- warn("Tried to cleanup storage for non-existent bullet ".. id)
    end
end
local function getBulletStorage(id)
    if not bulletStores[id] then
        bulletStores[id] = {}
    end
    return bulletStores[id]
end

local fxAtt = Instance.new("Attachment")
fxAtt.Parent = workspace.Terrain
local cachedFx = {}

function projectileUtil.applyImpulseFromProjectile(instance, projectileVelocity, projectileMass)
    projectileMass = projectileMass or 0
    instance:ApplyImpulse(projectileVelocity * projectileMass)
end

function projectileUtil.getParticleEffectOnFXAtt(name)
    -- local particleEffect = fxAtt:FindFirstChild(name)
    local particleEffect = cachedFx[name]
    if not particleEffect then
        local fx = Assets.Particles[name]:Clone()
        fx.Parent = fxAtt
        particleEffect = fx
        particleEffect.Enabled = false
        cachedFx[name] = particleEffect
    end
    return particleEffect
end
function projectileUtil.getNewParticleEffectOnFXAtt(name, overrideFxAtt)
    -- get the
    local fx = Assets.Particles[name]:Clone()
    fx.Parent = overrideFxAtt or fxAtt
    fx.Enabled = false
    return fx
end
function projectileUtil.getNewFXAtt()
    local newFX = Instance.new("Attachment")
    newFX.Parent = workspace.Terrain
    return newFX
end

function projectileUtil.emitOnPosNormal(identifier, pos, normal, emitAmount, overrideFxAtt)
    normal = normal or Vector3.new(0,1,0)
    local att = overrideFxAtt or fxAtt
    att.WorldCFrame = CFrame.new(pos, pos + normal)
    if typeof(identifier) == "string" then
        projectileUtil.getParticleEffectOnFXAtt(identifier):Emit(emitAmount)
    elseif typeof(identifier) == "Instance" then
        identifier:Emit(emitAmount)
    else
        warn("Idk")
    end
end

function projectileUtil.deathFX(pos)
    projectileUtil.emitOnPosNormal("Death", pos, nil, 10)
end

function projectileUtil.bulletHitFX(interaction, colorOverride)
    local newFxAtt = projectileUtil.getNewFXAtt()
    local puffFx = projectileUtil.getNewParticleEffectOnFXAtt("BulletHitPuff", newFxAtt)
    local shootFx = projectileUtil.getNewParticleEffectOnFXAtt("BulletHitShootcloud", newFxAtt)
    local hitColor = colorOverride or interaction.hitInstance.Color
    local intensity = math.max(0.2, interaction.hitVelocity.Magnitude / 1000 * interaction.projectileMass / 0.5)


    puffFx.Lifetime = NumberRange.new(
        0.05 + intensity*0.1,
        0.2 + intensity*0.2
    )
    puffFx.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, math.max(0, 0.5 - intensity*1), 0.2),
        NumberSequenceKeypoint.new(0.5,0.5,0.3),
        NumberSequenceKeypoint.new(1,1,0),
    })
    puffFx.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0,0),
        NumberSequenceKeypoint.new(1,2 + intensity*1,0.5),
    })
    puffFx.Color = ColorSequence.new(hitColor)


    shootFx.Lifetime = NumberRange.new(
        0.2 + intensity*1,
        0.5 + intensity*2
    )
    shootFx.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, math.max(0, 0.8 - intensity*0.2), 0.2),
        NumberSequenceKeypoint.new(0.4,1,0.3),
        NumberSequenceKeypoint.new(1,2,0),
    })
    shootFx.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0,0),
        NumberSequenceKeypoint.new(0.05,1 + intensity*1,0.2),
        NumberSequenceKeypoint.new(1,3 + intensity*1,0.5),
    })
    shootFx.Speed = NumberRange.new(
        50,
        100 + intensity*100
    )
    shootFx.Color = ColorSequence.new(hitColor)


    projectileUtil.emitOnPosNormal(puffFx, interaction.hitPos, interaction.hitNormal, 3, newFxAtt)
    projectileUtil.emitOnPosNormal(shootFx, interaction.hitPos, interaction.hitNormal, 4, newFxAtt)
    projectileUtil.emitOnPosNormal(shootFx, interaction.hitPos, cframeUtil.reflectOffNormal(interaction.hitVelocity, interaction.hitNormal), 3, newFxAtt)

    task.delay(puffFx.Lifetime.Max, function() puffFx:Destroy() end)
    task.delay(shootFx.Lifetime.Max, function() shootFx:Destroy() end)
    task.delay(math.max(puffFx.Lifetime.Max, shootFx.Lifetime.Max), function() newFxAtt:Destroy() end)
end

function projectileUtil.bounceFX(interaction)
    projectileUtil.emitOnPosNormal("BounceParticle", interaction.hitPos, interaction.hitNormal, 3)
end

function projectileUtil.unrenderProjectile(projectileId)
    cleanupStorage(projectileId)
end

function projectileUtil.renderProjectile(id, projectileC, noBeam)
    -- local projectileC = world:get(id, Components.Projectile)
    local storage = getBulletStorage(id)
    if storage.destroyed then return end

    if not storage.init then
        storage.B0 = Instance.new("Attachment")
        storage.B1 = Instance.new("Attachment")
        storage.B0.Name = id .. "B0"
        storage.B1.Name = id .. "B1"
        storage.B0.Parent = workspace.Terrain
        storage.B1.Parent = workspace.Terrain
        storage.Beam = projectileC.beamObj:Clone()
        storage.Beam.Parent = storage.B0
        storage.Beam.Attachment0 = storage.B0
        storage.Beam.Attachment1 = storage.B1

        if projectileC.trailObj then
            storage.T0 = Instance.new("Attachment")
            storage.T1 = Instance.new("Attachment")
            storage.T0.Name = id .. "T0"
            storage.T1.Name = id .. "T1"
            storage.T0.Parent = workspace.Terrain
            storage.T1.Parent = workspace.Terrain
            storage.Trail = projectileC.trailObj:Clone()
            storage.Trail.Parent = storage.T0
            storage.Trail.Attachment0 = storage.T0
            storage.Trail.Attachment1 = storage.T1
        end

        storage.init = true
    end
    -- Bullets should have its nose be right at position, and its tail
    -- extended outward from the position depending on velocity.
    storage.B0.WorldPosition = projectileC.cframe.Position
    storage.B1.WorldPosition = projectileC.cframe.Position - projectileC.velocity * 0.02

    -- Trails should be orthogonal to the velocity.
    if storage.T0 then
        local ortho = projectileC.cframe.RightVector
        storage.T0.WorldPosition = (ortho.Unit * projectileC.trailWidth) + projectileC.cframe.Position
        storage.T1.WorldPosition = (ortho.Unit * -projectileC.trailWidth) + projectileC.cframe.Position
    end
    
    if noBeam then
        storage.Beam.Enabled = false
    else
        storage.Beam.Enabled = true
    end
end


return projectileUtil