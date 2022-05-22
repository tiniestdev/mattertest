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
    for grabberId, grabberCR in world:queryChanged(Components.Grabber) do
        if grabberCR.new then
            -- grabUtil.manageConnection(grabberId, grabberCR.new, world)
        end
    end
end