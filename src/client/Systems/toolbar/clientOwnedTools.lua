local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local localUtil = require(ReplicatedStorage.Util.localUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

return function(world)
    local ourCharId = localUtil.getMyCharacterEntityId(world)
    if not ourCharId then return end

    -- for equippableId, equippableCR in world:queryChanged(Components.Equippable) do
    --     if not equippableCR.new then continue end
    --     replicationUtil.addClientOwnedArchetypes(equippableId, tableUtil.ToSet({"Equippable"}), world)
    -- end

    -- THIS DOWN THERE BELOW IS THE REASON WHY SERVER SWQITCHIGN AND ALTERNATING HAPPENS WTF!!!!!!!!!!!
    -- okay so every time something unequipped it's immediately server owned.....
    -- okay so iut should ACTUALLY be server owned when it's out of STORAGE, because technically everything inside a client's backpck shouild be server owned
    -- but what happens if the server gets ownership right when a player drops an item into the world? then will the server still have its past perception of it being
    -- in the player's backpack, replicate that to the client, and then it zips right back into the player inventory again?
    -- i think the client should add a flag saying "clientLetGo", which when replicated to the server, will tell the server it can replicate it after it reads that flag
    -- and then the server will let the client know that it's allowed to let go of clientowned i thiiiiiiink

    -- okay once the client removes the clientowned, it doesn't need to immediately request the server version; it's outdated at that poinnt, anyway
    -- then the server will send an updated version which should be identical to the client's data
    -- or if it's invalid data, will be corrected by the server anyway

    for equippableId, equippableCR in world:queryChanged(Components.Equippable) do
        if not equippableCR.new then continue end
        -- print("Equippable", equippableId, "has equipper", equippableCR.new.equipperId)
        if equippableCR.new.equipperId == ourCharId then
            replicationUtil.addClientOwnedArchetypes(equippableId, tableUtil.ToSet({"Equippable"}), world)
            -- print("Added client owned to", equippableId)
        else
            -- just do a delay. screw this
            task.delay(1, function()
                if not world:contains(equippableId) then return end
                local equippableC = world:get(equippableId, Components.Equippable)
                if not equippableC then return end
                if equippableC.equipperId ~= ourCharId then
                    replicationUtil.removeClientOwnedArchetypes(equippableId, tableUtil.ToSet({"Equippable"}), world)
                    -- print("Removed client owned from", equippableId)
                end
            end)
        end
    end
    -- for equipperId, equipperCR in world:queryChanged(Components.Equipper) do
    --     if not equipperCR.new then continue end
    --     print("Equipper", equipperId, "has equippable", equipperCR.new.equippableId)
    -- end
end