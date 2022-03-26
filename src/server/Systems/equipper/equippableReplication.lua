local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local RequestEquipEquippable = MatterUtil.NetSignalToEvent("RequestEquipEquippable", Remotes)

return function(world)
    for i, player, equippableId in Matter.useEvent(RequestEquipEquippable, "Event") do
        print("Server got request from ", player, "to equip ", equippableId)
        local playerEntityId = MatterUtil.getEntityId(player)
        assert(playerEntityId, "Player entity ID for player ".. player.Name .. " not found")
        local playerC = world:get(playerEntityId, Components.Player)
        local characterId = playerC.characterId
        -- local characterC = world:get(playerC.characterId, Components.Character)
        local equipperC = world:get(characterId, Components.Equipper)
        if equipperC.equippableId == equippableId then
            print("Already equipped")
            continue
        else
            world:insert(characterId, equipperC:patch({
                equippableId = equippableId,
            }))
            print("Equipped ", equippableId, " to ", playerC.characterId)
        end
    end
end