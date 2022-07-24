local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

return function(world)
    -- Character addition and worldspawning is handled by spawnLoadedCharacters
    -- LoadCharacter() must be called, and it will make the matter components by itself
    -- You can't really change a player's characterId since that doesn't make sense
    -- actually there is a way but roblox's player-character stuff is just too hard to
    -- customize using just data so screw that
    MatterUtil.linkBidirectionalEntityIdRefs("Player", "Character", world)
end

