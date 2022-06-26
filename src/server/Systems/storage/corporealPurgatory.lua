local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    for id, corporealCR in world:queryChanged(Components.Corporeal) do
        -- if not corporealCR.old then
        --     print("AAAAAAAAAAAAAAA")
        --     print(corporealCR.new.instance:GetFullName())
        --     print(id)
        -- end
        if not corporealCR.new then continue end
        local thing = corporealCR.new.instance
        if corporealCR.new.purgatory then
            thing.Parent = nil
        else
            thing.Parent = workspace
        end
    end
end