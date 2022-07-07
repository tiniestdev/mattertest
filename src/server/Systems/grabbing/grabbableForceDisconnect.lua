local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

return function(world)
    for grabbableId, grabbableCR in world:queryChanged(Components.Grabbable) do
        if not grabbableCR.new then continue end
        local grabbableInstance = grabbableCR.new.instance
        if not grabbableInstance then continue end

        -- Matter.useEvent(grabbableInstance, "Touched")
    end
end