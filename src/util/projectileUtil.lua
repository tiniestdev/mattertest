local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Constants = require(ReplicatedStorage.Constants)
local Assets = ReplicatedStorage.Assets

local RoundInfos = require(ReplicatedStorage.RoundInfos)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local randUtil = require(ReplicatedStorage.Util.randUtil)
local vecUtil = require(ReplicatedStorage.Util.vecUtil)

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

    while (not hit) and (distanceToTravel > 0) and (iters < MAX_ITERS) do
        currVelocity = currVelocity + (gravity * timeDelta)
        local newOffset = currVelocity * timeDelta

        local params = RaycastParams.new()
        params.CollisionGroup = projectileC.collisionGroup
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = projectileC.ignoreList
        castResult = workspace:Raycast(currCFrame.Position, newOffset, params)
        local finalPos = currCFrame.Position + newOffset
        if castResult then
            finalPos = castResult.Position
            hit = true
        end

        local actualDistanceTraveled = (finalPos - currCFrame.Position).Magnitude
        distanceToTravel = distanceToTravel - actualDistanceTraveled

        currCFrame = CFrame.new(finalPos, finalPos + currVelocity)

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
    local MAX_ITERS = projectileC.maxBounces + 10
    local iters = 0

    local currCFrame = projectileC.cframe
    local currVelocity = projectileC.velocity
    local gravity = projectileC.gravity
    local bounces = projectileC.bounces
    local life = projectileC.life
    local currPenetration = projectileC.penetratedDistance

    local bounceEvents = {}
    local destroyed = false
    local updateReplication = false

    while (not destroyed) and (distanceToTravel > 0) and (iters < MAX_ITERS) do
        currVelocity = currVelocity + (gravity * timeDelta)
        local newOffset = currVelocity * timeDelta

        local params = RaycastParams.new()
        params.CollisionGroup = projectileC.collisionGroup
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = projectileC.ignoreList
        local castResult = workspace:Raycast(currCFrame.Position, newOffset, params)
        local finalPos = currCFrame.Position + newOffset
        if castResult then
            finalPos = castResult.Position
            updateReplication = true
            -- EVENT MOMENT????????

            if (bounces < projectileC.maxBounces and randUtil.getChance(projectileC.bounceChance))
            or (bounces < projectileC.minBounces) then
                local surfaceNormal = castResult.Normal

                -- reflect like a mirror, but roughen up surfaceNormal
                local normalCFrame = CFrame.new(finalPos, finalPos + surfaceNormal)
                local maxAngleOffset = math.rad(15)
                local theta = randUtil.getNum() * math.pi * 2
                local phi = maxAngleOffset * randUtil.getNum(-1,1)
                surfaceNormal = (normalCFrame * CFrame.Angles(0, phi, theta)).LookVector

                -- theta is any angle chosen to reflect in the direction towards
                -- phi is the angle it should deviate from the normal
                -- rotate the normal by theta
                currVelocity =
                    (currVelocity - (2 * (currVelocity:Dot(surfaceNormal) * surfaceNormal)))
                    * projectileC.elasticity
                
                -- nudge the finalPos outward in preparation for reflecting
                finalPos = finalPos + (currVelocity * Constants.EPSILON)
                table.insert(bounceEvents, {
                    finalPos,
                    surfaceNormal,
                })
                bounces = bounces + 1
            elseif currPenetration < projectileC.penetration then
                -- attempt to penetrate
                -- TODO
                -- print("destroyed from penetrated")
                destroyed = true
                -- local castResult = workspace:Raycast(currCFrame.Position, newOffset, params)
            else
                -- can't penetrate, can't bounce
                -- print("destroyed from interaction")
                destroyed = true
            end
        end

        local actualDistanceTraveled = (finalPos - currCFrame.Position).Magnitude
        -- local timeDeltaUsedUp = timeDelta * (actualDistanceTraveled / totalStepTravelDistance)
        -- there's probably some edge case here about actualDistanceTraveled being
        -- more than needed to satisfy distanceToTravel but whatever idc
        distanceToTravel = distanceToTravel - actualDistanceTraveled

        currCFrame = CFrame.new(finalPos, finalPos + currVelocity)

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
        bounceEvents = bounceEvents,
    }
end

local bulletStores = {}
local function cleanupStorage(id)
    if bulletStores[id] then
        local storage = bulletStores[id]
        storage.Beam:Destroy()
        if storage.Trail then
            task.delay(storage.Trail.Lifetime, function()
                storage.Trail:Destroy()
                for i,v in pairs(storage) do
                    if typeof(v) == "Instance" then
                        v:Destroy()
                    end
                end
            end)
        end
        bulletStores[id] = nil
    -- else
        -- error("Tried to cleanup storage for non-existent bullet ".. id)
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

function projectileUtil.bounceFX(pos, normal)
    normal = normal or Vector3.new(0,1,0)
    fxAtt.WorldCFrame = CFrame.new(pos, pos + normal)
    local bounceEmitter = fxAtt:FindFirstChild("BounceParticle")
    if not bounceEmitter then
        local fx = Assets.Particles.BounceParticle:Clone()
        fx.Parent = fxAtt
        bounceEmitter = fx
        bounceEmitter.Enabled = false
    end
    bounceEmitter:Emit(3)
end

function projectileUtil.unrenderProjectile(projectileId)
    cleanupStorage(projectileId)
end

function projectileUtil.renderProjectile(id, projectileC)
    -- local projectileC = world:get(id, Components.Projectile)
    local storage = getBulletStorage(id)
    if not storage.init then
        storage.B0 = Instance.new("Attachment")
        storage.B1 = Instance.new("Attachment")
        storage.B0.Name = id .. "B0"
        storage.B1.Name = id .. "B1"
        storage.B0.Parent = workspace.Terrain
        storage.B1.Parent = workspace.Terrain
        storage.Beam = projectileC.beamObj:Clone()
        -- print(storage)
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
end


return projectileUtil