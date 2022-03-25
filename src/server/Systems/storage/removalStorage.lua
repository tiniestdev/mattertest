local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

return function(world)
    for id, storageCR in world:queryChanged(Components.Storage) do
        if not storageCR.new then
            -- we should delete everything inside it
            -- (if we wanted the storables to be preserved, they'd be transferred to another
            -- storage or removed from this one already)
            for storableId, _ in pairs(storageCR.old.storableIds) do
                world:despawn(storableId)
            end
        end
    end
end