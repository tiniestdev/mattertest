local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local Intercom = require(ReplicatedStorage.Intercom)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local combatUtil = require(ReplicatedStorage.Util.combatUtil)
local soundUtil = require(ReplicatedStorage.Util.soundUtil)
local randUtil = require(ReplicatedStorage.Util.randUtil)
local projintevent = matterUtil.SignalToEvent(Intercom.Get("ProjectileInteractions"))

return function(world)
    -- a queue inside a component of forces that must be applied to an instance?
    -- or just a simple event or some thing idk idk idk
    -- Do an intercom event for serverwide bullet collisions
    -- and also do a remote event to every client
    for i, interactions, projectileId in Matter.useEvent(projintevent, "Event") do
        for _, interaction in ipairs(interactions) do
            
            local hitPos = interaction.hitPos
            local hitNormal = interaction.hitNormal
            local hitInstance = interaction.hitInstance
            local hitVelocity = interaction.hitVelocity
            local projectileMass = interaction.projectileMass
            local hitDied = interaction.hitDied

            if hitInstance then
                projectileUtil.applyImpulseFromProjectile(hitInstance, hitVelocity, projectileMass)
            end

            -- this whole damage thing has got to be improved on later
            -- considering doing it the runker 51 way but we'll see. i feel like
            -- there's a conflict between event-based handling and the *matter* way
            local victimId = matterUtil.getEntityId(hitInstance) or matterUtil.getEntityId(hitInstance.Parent)
            if victimId then
                if combatUtil.canRoundDamage(projectileId, victimId, world) then
                    local finalDamage = combatUtil.getDamageFromRoundToInstance(projectileId, hitInstance, world)
                    local results = combatUtil.damageResults(victimId, finalDamage, world)
                    local healthVictimC = world:get(victimId, Components.Health)
                    local lastHealth = healthVictimC.health
                    world:insert(victimId, healthVictimC:patch({
                        health = results.finalHealth,
                    }))
                    
                    local blacklist = {}
                    local instanceC = world:get(victimId, Components.Instance)
                    if instanceC then
                        table.insert(blacklist, instanceC.instance)
                    end
                    -- local blood = combatUtil.sprayBloodFx(hitPos, hitVelocity, randUtil.getNum(3,6), blacklist)

                    if lastHealth > 0 then
                        local pitch = (7 / math.log(hitVelocity.Magnitude))^2
                        local volume = hitVelocity.Magnitude / 1000
                        local heavyVolume = math.max(0, volume - 2)
                        if volume > 0 then
                            soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundUtil.soundCategories.Hit), hitPos, {
                                PlaybackSpeed = math.max(0.5, pitch),
                                Volume = volume,
                            })
                        end
                        if heavyVolume > 0 then
                            soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundUtil.soundCategories.HeavyHit), hitPos, {
                                PlaybackSpeed = math.max(0.5, pitch),
                                Volume = heavyVolume,
                            })
                        end

                        if results.died then
                            -- ???????
                            -- TODO
                            projectileUtil.deathFX(hitPos)
                            soundUtil.PlaySoundAtPos(randUtil.chooseFrom(soundUtil.soundCategories.Death), hitPos, {
                                PlaybackSpeed = randUtil.getNum(0.8,1),
                                Volume = math.max(1.5, 0.5 + heavyVolume + volume),
                            })
                        end
                    end
                end
            end
        end
    end
end