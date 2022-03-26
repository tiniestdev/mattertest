local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

return function(world)
    for playerId, playerCR in world:queryChanged(Components.Player) do
        local playerC = playerCR.new
        if playerC.player then
            local payload = replicationUtil.serializeArchetype(
                "Player",
                playerId,
                playerC.player.UserId,
                replicationUtil.CLIENTIDENTIFIERS.PLAYER,
                world
            )
            Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(playerC.player, "Player", payload)
            print("Replicated player changes to ", playerC.player)
        else
            warn("Player component has no actual player: ", playerC, playerId)
        end
    end
end