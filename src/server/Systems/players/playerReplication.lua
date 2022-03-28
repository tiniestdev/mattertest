local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

return function(world)
    for playerId, playerCR in world:queryChanged(Components.Player) do
        if playerCR.new then
            local playerC = playerCR.new
            if playerC.player then
                replicationUtil.replicateOwnPlayer(playerC.player, playerId, world)
                print("QueryChanged: sending player changes to ", playerC.player)
            else
                warn("Player component has no actual player: ", playerC, playerId)
            end
        end
    end
end