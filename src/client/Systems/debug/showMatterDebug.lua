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
    for entityId, showMatterDebugCR in world:queryChanged(Components.ShowMatterDebug) do
        if not showMatterDebugCR.old then
            -- new
            task.delay(1, function()
            local serverId
            local replicatedC = world:get(entityId, Components.Replicated)
            if replicatedC then
                serverId = replicatedC.serverId
            end

            local entityPlrId
            local serverPlrId
            local foundCharacterC = world:get(entityId, Components.Character)
            if foundCharacterC and foundCharacterC.playerId then
                entityPlrId = foundCharacterC.playerId
                local replicatedC = world:get(foundCharacterC.playerId, Components.Replicated)
                if replicatedC then
                    serverPlrId = replicatedC.serverId
                end
            end

            local newBillboard = MatterIdDisplay({
                adornee = showMatterDebugCR.new.adornee,
                -- characterInstance = showMatterDebugCR.new.adornee.Parent,
                -- clientCharacterId = 0,
                -- serverCharacterId = 1,
                -- clientPlayerId = 2,
                -- serverPlayerId = 3,
                clientCharacterId = entityId,
                serverCharacterId = serverId,
                clientPlayerId = entityPlrId,
                serverPlayerId = serverPlrId,
            })
            
            newBillboard.Parent = showMatterDebugCR.new.adornee
            end)
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