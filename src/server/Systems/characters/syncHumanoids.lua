local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)

return function(world)
    for id, healthCR in world:queryChanged(Components.Health) do
        if not healthCR.new then continue end
        local instanceC = world:get(id, Components.Instance)
        if not instanceC then continue end
        local foundHumanoid = instanceC.instance:FindFirstChild("Humanoid")
        if not foundHumanoid then continue end
        foundHumanoid.Health = healthCR.new.health
        foundHumanoid.MaxHealth = healthCR.new.maxHealth
    end
end