local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Intercom = require(ReplicatedStorage.Intercom)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

return function(world)
    for id, equipperCR in world:queryChanged(Components.Equipper) do
        if equipperCR.new then
            if not world:get(id, Components.Ours) then continue end
            Intercom.GetFusionValue("EquippedId", equipperCR.new.equippableId):set(equipperCR.new.equippableId)
            -- print("Set fusion value EquippedId to ", equipperCR.new.equippableId)
        end
    end
end