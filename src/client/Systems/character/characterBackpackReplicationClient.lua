local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Intercom = require(ReplicatedStorage.Intercom)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

local Remotes = require(ReplicatedStorage.Remotes)

return function(world)
    for storageId, storageCR, characterC in world:queryChanged(Components.Storage, Components.Character) do
        -- check if it's *our* character
        -- print("storage got, storageId:", storageId, "storageCR:", storageCR, "characterC:", characterC)
        if not storageCR.new then continue end
        if not characterC.playerId then continue end
        local foundPlayerC = world:get(characterC.playerId, Components.Player)
        -- print("storage got r2", foundPlayerC)
        if not foundPlayerC then continue end
        if foundPlayerC.player == Players.LocalPlayer then
            -- send a signal to update toolbar in fusion
            -- print("storage got 3")
            Intercom.Get("UpdateToolbar"):Fire(storageId)
        end
    end
end