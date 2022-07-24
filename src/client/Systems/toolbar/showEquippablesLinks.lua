local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plasma = require(ReplicatedStorage.Packages.plasma)
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

return function(world, _, ui)
    if not ui.checkbox("Show"):checked() then return end

    -- for i,v in pairs(ui) do
    --     print(i,v)
    -- end
    local items = {}
    for id, equippableC in world:query(Components.Equippable) do
        local info = {
            tostring(id),
            equippableC.equipperId and tostring(equippableC.equipperId) or "nil",
        }
        table.insert(items, info)
    end
    ui.table(items)
end