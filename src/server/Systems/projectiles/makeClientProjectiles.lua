local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Constants = require(ReplicatedStorage.Constants)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)
local ProposeProjectileHit = matterUtil.NetSignalToEvent("ProposeProjectileHit", Remotes)
local ProposeProjectile = matterUtil.NetSignalToEvent("ProposeProjectile", Remotes)

local awaitingProjectiles = {}

return function(world)
    for i, player, projectileC, clientTickId, creatorId in Matter.useEvent(ProposeProjectile, "Event") do
        -- use the player to infer where it originated from
        awaitingProjectiles[clientTickId] = {projectileC, creatorId}
        -- print("Proposing projectile", clientTickId, creatorId)
    end

    for i, player, projectileC, tickId, creatorId, instance, position, normal in Matter.useEvent(ProposeProjectileHit, "Event") do
        -- print("got hit from", player, tickId)
        -- print(creatorId)
        -- print(projectileC)
        -- print(instance, position, normal)
        -- print()
        if tickId and projectileC and instance and position and normal then
            
            -- todo: make this more secure with rewinding functions? idk
            local projectileC = awaitingProjectiles[tickId][1]
            local creatorId = awaitingProjectiles[tickId][2]
            awaitingProjectiles[tickId] = nil

            if creatorId then
                -- TODO: we expect this to be a gun, but this may change in da futur
                if not world:contains(creatorId) then
                    warn("Creator id not in world", creatorId)
                    continue
                end
                local gunToolC = world:get(creatorId, Components.GunTool)
                if not gunToolC then continue end
                local roundType = gunToolC.roundType
                -- will default to "Default"

                -- TODO: compare the recorded projectileC with the recieved projectileC
                -- Bullets should be made by rounds and modified by whatever components they have.
                -- Effects can be like "BounceModifier" or "DamageModifier".
                -- TODO: idk if just going by barrelSpeed is accurate
                -- since it'd have time to be effected by gravity
                local startPos = position + (normal * Constants.EPSILON)
                local startCFrame = CFrame.new(startPos, position)
                local newBulletId = projectileUtil.fireRound(
                    startCFrame,
                    startCFrame.LookVector.Unit * gunToolC.barrelSpeed,
                    roundType,
                    {
                        -- player.Character
                    },
                    creatorId, -- kinda redundant but whatever
                    world
                )
                -- print("making projectile id", newBulletId)
            end
            -- local stepResults = projectileUtil.stepProjectile(newBulletId, projectileC, Matter.useDeltaTime(), world)
        end
    end
end