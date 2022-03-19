local TeamService = game:GetService("Teams")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local Teams = require(ReplicatedStorage.Teams)

return function(world)
    for id, teamedCR, playerC in world:queryChanged(Components.Teamed, Components.Player) do
        local teamId = teamedCR.new.teamId
        local teamName = Teams.IdToName[teamId]
        playerC.player.Team = TeamService:FindFirstChild(teamName)
    end
end


