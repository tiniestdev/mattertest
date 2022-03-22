local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

return function(world)
    for storableId, storableCR in world:queryChanged(Components.Storable) do
        if not storableCR.new then
            -- it's not a storable anymore, so remove it from any potential storage it's in right now
            -- actually hold on this is handled by storableStorageReconcil nvm
        end
    end
end
