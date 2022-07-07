local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

return function(world)
    for id, characterCR in world:queryChanged(Components.Character) do
        if not characterCR.new then continue end
        local instanceC = world:get(id, Components.Instance)
        if not instanceC then continue end 
        local character = instanceC.instance
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then continue end

        local characterC = characterCR.new
        humanoid.JumpHeight = characterC.jumpHeight
    end
end