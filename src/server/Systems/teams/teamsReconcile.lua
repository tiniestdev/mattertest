local TeamService = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local Llama = require(ReplicatedStorage.Packages.llama)
local Teams = require(ReplicatedStorage.Teams)

local ChangeTeamEvent = MatterUtil.NetSignalToEvent("ChangeTeam", Remotes)

return function(world)
    for id, teamC in world:query(Components.Team) do
        if not TeamService:FindFirstChild(Teams.IdToName[id]) then
            local newTeamInstance = Instance.new("Team")
            newTeamInstance.Name = Teams.IdToName[id]
            newTeamInstance.TeamColor = BrickColor.new(Teams.IdToInfo[id].color)
            newTeamInstance.AutoAssignable = false
            newTeamInstance.Parent = TeamService

            -- add all its players
            for i, playerEntityId in pairs(teamC.playerIds) do
                local playerC = world:get(playerEntityId, Components.Player)
                local player = playerC.player
                player.Team = newTeamInstance
            end
        end
    end
end


