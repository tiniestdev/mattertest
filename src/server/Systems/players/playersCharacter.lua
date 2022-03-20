local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local RequestRespawnEvent = MatterUtil.NetSignalToEvent("RequestRespawn", Remotes)

return function(world)
    -- Character addition and worldspawning is handled by spawnLoadedCharacters
    -- LoadCharacter() must be called, and it will make the matter components by itself
    -- You can't really change a player's characterId since that doesn't make sense
    -- actually there is a way but roblox's player-character stuff is just too hard to
    -- customize using just data so screw that

    -- Handle character deletion when playerCR's characterId is set to nothing
    for id, playerCR in world:queryChanged(Components.Player) do
        if playerCR.new.characterId ~= playerCR.old.characterId then
            -- new character (or it was deleted)
            if not playerCR.new.characterId then
                -- deleted character
                print("Deleting character due to removal of characterId from entity " .. id)
                task.spawn(function()
                    playerCR.new.player:RemoveCharacter()
                end)
            end
        end
    end
end

