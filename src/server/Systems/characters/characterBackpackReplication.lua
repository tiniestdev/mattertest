local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)
local Rx = require(ReplicatedStorage.Packages.rx)
local Llama = require(ReplicatedStorage.Packages.llama)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

return function(world)
    -- Replication of character backpack/storage
    -- This only replicates a player's own backpack towards the player and no one else

    --[[
    for characterId, storageCR, characterC in world:queryChanged(Components.Storage, Components.Character) do
        -- does a player own this?
        local playerC = world:get(characterC.playerId, Components.Player)
        if playerC then
            local player = playerC.player
            local characterPayload = replicationUtil.serializeArchetype("Character", characterId, replicationUtil.SERVERSCOPE, characterId, world)
            Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(player, "Character", characterPayload)

            local toolsInBackpack = world:get(characterId, Components.Storage).storableIds
            
            Rx.from(Llama.Set.toList(toolsInBackpack)):Pipe({
                Rx.map(function(toolId)
                    return replicationUtil.serializeArchetype(
                        "ToolbarTool",
                        toolId,
                        replicationUtil.SERVERSCOPE,
                        toolId,
                        world
                    )
                end),
            }):Subscribe(function(payload)
                Remotes.Server:Create("ReplicateArchetype"):SendToPlayer(player, "ToolbarTool", payload)
            end)
        end
    end]]
    -- Replication of player team

    -- Replication of stats like health or walkspeed

end