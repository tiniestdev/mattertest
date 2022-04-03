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

local MatterIdDisplay = require(Players.LocalPlayer.PlayerScripts.Client.UI.Debug.MatterIdDisplay)

return function(world)
    for i, showMatterDebugC in world:query(Components.ShowMatterDebug) do
        
    end
    for entityId, showMatterDebugCR in world:queryChanged(Components.ShowMatterDebug) do
        if not showMatterDebugCR.old then
            -- new
            local serverId
            local replicatedC = world:get(entityId, Components.Replicated)
            if replicatedC then
                serverId = replicatedC.serverId
            end

            local newBillboard = MatterIdDisplay({
                adornee = showMatterDebugCR.new.adornee,
                clientId = entityId,
                serverId = serverId,
            })
            
            newBillboard.Parent = showMatterDebugCR.new.adornee
        end
        if not showMatterDebugCR.new then
            -- deleted
            if (showMatterDebugCR.old.adornee) then
                local foundDebugUI = showMatterDebugCR.old.adornee:FindFirstChild("MatterDebugUI", true)
                if foundDebugUI then
                    foundDebugUI:Destroy()
                end
            end
        end
    end
end