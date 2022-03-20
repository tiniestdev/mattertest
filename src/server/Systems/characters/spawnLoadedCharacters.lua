local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local Teams = require(ReplicatedStorage.Teams)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

local CharacterEvent = MatterUtil.ObservableToEvent(PlayerUtil.getCharactersObservable())

return function(world)
    for i, character in Matter.useEvent(CharacterEvent, "Event") do
        local player = Players:GetPlayerFromCharacter(character)
        local playerEntityId = MatterUtil.getEntityId(player)
        local id = world:spawn(
            Components.Instance({
                instance = character,
            }),
            Components.Character({
                playerId = playerEntityId,
            }),
            Components.Health({
                health = 100,
                maxHealth = 100,
            }),
            Components.Storage({
                storableIds = {},
                capacity = 0,
                maxCapacity = 10,
            }),
            Components.Walkspeed({
                walkspeed = 16,
            })
        )
        MatterUtil.setEntityId(character, id)
        CollectionService:AddTag(character, "Character")
    end
end


