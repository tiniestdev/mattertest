local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Rx = require(ReplicatedStorage.Packages.rx)

local playerUtil = {}

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
    if RunService:IsServer() then
        local id = world:spawn(
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
        MatterUtil.setEntityId(player, id)
        CollectionService:AddTag(player, "Player")
        return id
    else
        local id = world:spawn(
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
        return id
    end
end

return playerUtil