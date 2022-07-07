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

local bounceFXEvent = matterUtil.NetSignalToEvent("BounceFX", Remotes)

local ricochetSounds = {
    "ricochet1",
    "ricochet2",
    "ricochet3",
}

return function(world)
    for i, hitPos, hitNormal, bulletId in Matter.useEvent(bounceFXEvent, "Event") do
        local recipientBulletId = replicationUtil.getRecipientIdFromScopeIdentifier(replicationUtil.SERVERSCOPE, bulletId)
        if not world:contains(recipientBulletId) then continue end
        local bulletC = world:get(recipientBulletId, Components.Projectile)
        if not bulletC then continue end
        local pitch = math.log(bulletC.velocity.Magnitude) / 5
        projectileUtil.bounceFX(hitPos, hitNormal)
        soundUtil.PlaySoundAtPos(randUtil.chooseFrom(ricochetSounds), hitPos, {
            PlaybackSpeed = math.max(0.5, pitch + randUtil.getNum(-0.1, 0.1))
        })
    end
end