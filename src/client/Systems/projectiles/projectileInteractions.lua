local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)
local soundUtil = require(ReplicatedStorage.Util.soundUtil)
local randUtil = require(ReplicatedStorage.Util.randUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

local projintevent = matterUtil.NetSignalToEvent("ProjectileInteractions", Remotes)

local ricochetSounds = {
    "ricochet1",
    "ricochet2",
    "ricochet3",
}

local soundCategories = {
    Dirt = {
        "bulletHitDirt",
        "bulletHitDirt2",
        "bulletHitDirt3",
    },
    Ground = {
        "bulletHitGround",
        "bulletHitGround2",
        "bulletHitGround3",
    },
    Metal = {
        "bulletHitMetal",
        "bulletHitMetal2",
        "bulletHitMetal3",
    },
    Flesh = {
        "bulletHitFlesh",
        "bulletHitFlesh2",
    },
}
local materialMap = {
    [Enum.Material.Sand] = soundCategories["Dirt"],
    [Enum.Material.Grass] = soundCategories["Dirt"],
    [Enum.Material.Snow] = soundCategories["Dirt"],

    [Enum.Material.Plastic] = soundCategories["Ground"],
    [Enum.Material.Concrete] = soundCategories["Ground"],
    [Enum.Material.Marble] = soundCategories["Ground"],

    [Enum.Material.Metal] = soundCategories["Metal"],
    [Enum.Material.CorrodedMetal] = soundCategories["Metal"],
    [Enum.Material.DiamondPlate] = soundCategories["Metal"],
}

local lastKnownSpeeds = {}

return function(world)
    for id, projectileC in world:query(Components.Projectile) do
        lastKnownSpeeds[id] = projectileC.velocity.Magnitude
    end
    for i, interactions, bulletId in Matter.useEvent(projintevent, "Event") do

        for _, interaction in ipairs(interactions) do
            local hitPos = interaction.hitPos
            local hitNormal = interaction.hitNormal
            local hitInstance = interaction.hitInstance
            local hitVelocity = interaction.hitVelocity
            local projectileMass = interaction.projectileMass
            local hitDied = interaction.hitDied

            -- we can't read bullet properties since the bullet may already be deleted from the client
            -- if the server told it to delete it. just get all the info from the remote event
            local pitch = math.log(hitVelocity.Magnitude) / 5
            local pitchNoise = 0.2

            local volume = pitch * interaction.projectileMass

            if hitDied then
                -- Died, play hit sound
                if hitInstance.Parent:FindFirstChild("Humanoid") then
                    soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundCategories.Flesh), hitPos, {
                        PlaybackSpeed = math.max(0.5, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                        Volume = volume,
                    })
                else
                    if materialMap[hitInstance.Material] then
                        soundUtil.PlaySoundAtPos(randUtil.chooseFrom(materialMap[hitInstance.Material]), hitPos, {
                            PlaybackSpeed = math.max(0.9, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                            Volume = volume,
                        })
                    else
                        soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundCategories.Ground), hitPos, {
                            PlaybackSpeed = math.max(0.9, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                            Volume = volume,
                        })
                    end
                end
            else
                -- BOUNCED
                projectileUtil.bounceFX(hitPos, hitNormal)
                soundUtil.PlaySoundAtPos(randUtil.chooseFrom(ricochetSounds), hitPos, {
                    PlaybackSpeed = math.max(0.5, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                    Volume = volume * 2,
                })
            end

            if hitInstance then
                projectileUtil.applyImpulseFromProjectile(hitInstance, hitVelocity, projectileMass)
            end
        end
    end
end