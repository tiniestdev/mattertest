local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Fusion = require(ReplicatedStorage.Fusion)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

local MatterIdDisplay = require(ReplicatedStorage.UI.Debug.MatterIdDisplay)

return function(world)
    for entityId, equippableCR in world:queryChanged(Components.Equippable) do
        if equippableCR.new then
            if equippableCR.new.equipperId then
                if equippableCR.new.equipperId ~= equippableCR.old.equipperId then
                    -- we've changed equippers
                    
                end
            else
                -- disconnect any listeners
            end
        end
    end
end

