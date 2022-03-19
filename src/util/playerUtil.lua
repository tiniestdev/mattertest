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

return playerUtil