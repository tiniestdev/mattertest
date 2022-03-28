local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local Rx = require(ReplicatedStorage.Packages.rx)

local Teams = require(ReplicatedStorage.Teams)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local toolUtil = require(ReplicatedStorage.Util.toolUtil)
local ToolInfos = require(ReplicatedStorage.ToolInfos)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)


local CharacterEvent = MatterUtil.ObservableToEvent(PlayerUtil.getCharactersObservable())

return function(world)
    for _, character in Matter.useEvent(CharacterEvent, "Event") do
        local player = Players:GetPlayerFromCharacter(character)
        local playerEntityId = MatterUtil.getEntityId(player)
        local playerC = world:get(playerEntityId, Components.Player)

        -- local startingTools = toolUtil.makePresetTools({
        --     "Grab",
        --     "Apple",
        -- }, world)

        local charEntityId = world:spawn(
            -- Components.Instance({
            --     instance = character,
            -- }),
            Components.Character({
                playerId = playerEntityId,
            })
            -- Components.Health({
            --     health = 100,
            --     maxHealth = 100,
            -- }),
            -- Components.Storage({
            --     storableIds = Llama.List.toSet(startingTools),
            --     capacity = 0,
            --     maxCapacity = 10,
            -- }),
            -- Components.Equipper({
            --     equippableId = nil,
            -- }),
            -- Components.Walkspeed({
            --     walkspeed = 16,
            -- })
        )

        world:insert(playerEntityId, playerC:patch({
            characterId = charEntityId,
        }))
        print("Player ID " .. playerEntityId .. " has character ID " .. charEntityId)
        MatterUtil.setEntityId(character, charEntityId)
        CollectionService:AddTag(character, "Character")
    end
end


