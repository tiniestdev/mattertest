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
    for entityId, characterCR in world:queryChanged(Components.Character) do
        local instanceC = world:get(entityId, Components.Instance)
        task.delay(0.5, function()
            world:insert(entityId, Components.ShowMatterDebug({
                adornee = instanceC.instance.HumanoidRootPart,
            }))
            -- print("INSERTED SHOW MATTER DEBUG INTO INSTANCE ", instanceC.instance.Name)
        end)
    end
end
