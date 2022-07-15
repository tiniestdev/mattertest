local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

return function(world)
    for id, healthCR in world:queryChanged(Components.Health) do
        if not healthCR.new then continue end
        local ragdollableC = world:get(id, Components.Ragdollable)
        if not ragdollableC then continue end
        if healthCR.new.health < 20 then
            world:insert(id, ragdollableC:patch({
                downed = true,
            }))
        else
            world:insert(id, ragdollableC:patch({
                downed = false,
            }))
        end
    end
end