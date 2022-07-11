local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local Intercom = require(ReplicatedStorage.Intercom)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local projintevent = matterUtil.SignalToEvent(Intercom.Get("ProjectileInteractions"))

return function(world)
    -- a queue inside a component of forces that must be applied to an instance?
    -- or just a simple event or some thing idk idk idk
    -- Do an intercom event for serverwide bullet collisions
    -- and also do a remote event to every client
    for i, interactions, id in Matter.useEvent(projintevent, "Event") do
        for _, interaction in ipairs(interactions) do
            local hitInstance = interaction.hitInstance
            local hitVelocity = interaction.hitVelocity
            local projectileMass = interaction.projectileMass

            if hitInstance then
                projectileUtil.applyImpulseFromProjectile(hitInstance, hitVelocity, projectileMass)
                if hitInstance.Parent:FindFirstChild("Humanoid") then
                    
                end
            end
        end
    end
end