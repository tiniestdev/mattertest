local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    -- Replication of character backpack/storage
    for id, storageCR, characterC in world:queryChanged(Components.Storage, Components.Character) do
        -- does a player own this?
        local playerC = world:get(characterC.playerId, Components.Player)
        if playerC then
            local player = playerC.player
            Remotes.Server:SendToPlayer(player, 
                characterC
            )
        end
    end

    -- Replication of player team

    -- Replication of stats like health or walkspeed

end