local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

return function(world)
    local addedChars = {}

    for id, oursCR in world:queryChanged(Components.Ours) do
        if not oursCR.new then continue end
        if not world:get(id, Components.Character) then continue end
        if not oursCR.old then
            -- brand new character for us
            table.insert(addedChars, id)
        end
    end

    for i, id in ipairs(addedChars) do
        world:insert(id, Components.ClientOwned({
            archetypes = tableUtil.ToSet({"Aimer", "Equipper"}),
        }))
    end
end