local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Rx = require(ReplicatedStorage.Packages.rx)

local playerUtil = {}

function playerUtil.getSetOfPlayers()
    local set = {}
    for i,v in ipairs(Players:GetPlayers()) do
        set[v] = true
    end
    return set
end

function playerUtil.getPlayersObservable()
    return Rx.of(
        Rx.from(Players:GetPlayers()),
        Rx.fromSignal(Players.PlayerAdded)
    ):Pipe({
        Rx.mergeAll()
    })
end

function playerUtil.getCharactersObservable()
    -- for any future player and for any future character added to them,
    -- make an observable of this
    return Rx.of(
        Rx.from(Players:GetPlayers()):Pipe({
            Rx.map(function(player)
                return player.Character
            end)
        }),
        playerUtil.getPlayersObservable():Pipe({
            Rx.flatMap(function(player)
                return Rx.fromSignal(player.CharacterAdded)
            end)
        })
    ):Pipe({
        Rx.mergeAll()
    })
end

function playerUtil.getLeavingPlayersObservable()
    return Rx.fromSignal(Players.PlayerRemoving)
end

function playerUtil.getLeavingCharactersObservable()
    return playerUtil.getPlayersObservable():Pipe({
        Rx.flatMap(function(player)
            return Rx.fromSignal(player.CharacterRemoving)
        end)
    })
end

function playerUtil.makePlayerEntity(player, world)
    local Components = require(ReplicatedStorage.components)
    local MatterUtil = require(ReplicatedStorage.Util.matterUtil)

    local playerEntityId = MatterUtil.getEntityId(player)
    if not playerEntityId then
        playerEntityId = world:spawn()
        MatterUtil.setEntityId(player, playerEntityId)
    end
    world:insert(
        playerEntityId,
        Components.Instance({
            instance = player,
        }),
        Components.Player({
            player = player,
            characterId = nil,
        }),
        Components.Teamed({
            teamId = nil,
        })
    )

    if RunService:IsServer() then
        MatterUtil.setEntityId(player, playerEntityId)
        CollectionService:AddTag(player, "Player")
        world:insert(
            playerEntityId,
            Components.ReplicateToClient({
                archetypes = {"PlayerArchetype"}
            })
        )
    end

    return playerEntityId
end

return playerUtil