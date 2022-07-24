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
local combatUtil = require(ReplicatedStorage.Util.combatUtil)

local projintevent = matterUtil.NetSignalToEvent("ProjectileInteractions", Remotes)

local ricochetSounds = {
    "ricochet1",
    "ricochet2",
    "ricochet3",
}

local lastKnownSpeeds = {}

return function(world)
    for id, projectileC in world:query(Components.Projectile) do
        lastKnownSpeeds[id] = projectileC.velocity.Magnitude
    end
    for i, interactionsMap in Matter.useEvent(projintevent, "Event") do
        for _, interactionInfo in ipairs(interactionsMap) do
            local bulletId = interactionInfo[1]
            local interactions = interactionInfo[2]
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

                if combatUtil.getHumanoidFromInstance(hitInstance) then
                    projectileUtil.bulletHitFX(interaction, Color3.new(0.407843, 0, 0))
                    soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundUtil.soundCategories.Flesh), hitPos, {
                        PlaybackSpeed = math.max(0.5, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                        Volume = volume,
                    })
                elseif hitDied then
                    -- Died, play hit sound
                    projectileUtil.bulletHitFX(interaction)
                    if soundUtil.materialMap[hitInstance.Material] then
                        soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundUtil.materialMap[hitInstance.Material]), hitPos, {
                            PlaybackSpeed = math.max(0.9, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                            Volume = volume,
                        })
                    else
                        soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundUtil.soundCategories.Ground), hitPos, {
                            PlaybackSpeed = math.max(0.9, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                            Volume = volume,
                        })
                    end
                else
                    -- BOUNCED
                    projectileUtil.bounceFX(interaction)
                    soundUtil.PlaySoundAtPos(randUtil.chooseFrom(ricochetSounds), hitPos, {
                        PlaybackSpeed = math.max(0.7, pitch + randUtil.getNum(-pitchNoise, pitchNoise)),
                        Volume = volume * 2,
                        -- Volume = 20,
                    })
                    -- print("BOUNCE SOUND???")
                end

                if hitInstance then
                    projectileUtil.applyImpulseFromProjectile(hitInstance, hitVelocity, projectileMass)
                end
            end
        end
    end
end