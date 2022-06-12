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
    for id, teamedCR in world:queryChanged(Components.Teamed) do
        local playerC = world:get(id, Components.Player)
        if not playerC then continue end
        if teamedCR.new and teamedCR.new.teamId then
            local teamId = teamedCR.new.teamId
            local teamName = Teams.IdToName[teamId]
            playerC.player.Team = TeamService:FindFirstChild(teamName)
        else
            playerC.player.Team = nil
        end
    end
end


