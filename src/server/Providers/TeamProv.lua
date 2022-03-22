local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Remotes = require(ReplicatedStorage.Remotes)
local Components = require(ReplicatedStorage.components)
local Teams = require(ReplicatedStorage.Teams)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)

local Llama = require(ReplicatedStorage.Packages.llama)
local Set = Llama.Set

local MatterStart = require(script.Parent.MatterStart)

local TeamProv = {}

TeamProv.AxisName = "TeamProvAxis"

function TeamProv:AxisPrepare()
end

function TeamProv:AxisStarted()
    local world = MatterStart.World

    Remotes.Server:OnEvent("ChangeTeam", function(player, newTeamName)
        local entityId = MatterUtil.getEntityId(player)
        if entityId then
            -- make sure we're not changing to the same exact team
            local newTeamId = Teams.NameToId[newTeamName]
            local teamC = world:get(entityId, Components.Teamed)
            print(teamC, teamC.teamId, newTeamId)
            if teamC and teamC.teamId == newTeamId then
                return
            else
                world:insert(entityId, Components.Teamed({
                    teamId = newTeamId
                }))
            end
        end
    end)

    -- CREATE ALLIANCES
    for allianceName, allianceInfo in pairs(Teams.Alliances) do
        local allianceId = world:spawn(Components.Alliance({
            ["allianceName"] = allianceName;
            ["teamIds"] = {};
        }))
        Teams.NameToId[allianceName] = allianceId
        Teams.IdToName[allianceId] = allianceName
    end

    -- CREATE TEAMS (AND LINK THEM TO THEIR ALLIANCES)
    for teamName, teamInfo in pairs(Teams.Teams) do
        -- allianceId could potentially be nil, treat as neutral
        local teamId = world:spawn(Components.Team({
            teamName = teamName;
            allianceId = Teams.NameToId[teamInfo.allianceName] or Teams.NameToId["Neutral"];
            playerIds = {};
            color = teamInfo.color;
            autoAssignable = teamInfo.autoAssignable;
        }))
        Teams.NameToId[teamName] = teamId
        Teams.IdToName[teamId] = teamName
        Teams.IdToInfo[teamId] = teamInfo
    end

    -- LINK ALLIANCES TO THEIR TEAMS
    for allianceId, allianceC in world:query(Components.Alliance) do
        -- get teams that have it as an alliance
        for teamId, teamC in world:query(Components.Team) do
            if teamC.allianceId == allianceId then
                world:insert(allianceId, allianceC:patch({
                    teamIds = Set.add(allianceC.teamIds, teamId);
                }))
            end
        end
    end

    --[[
    print("Created alliances and teams")
    -- print out each alliance name along with their ids
    for allianceId, allianceC in world:query(Components.Alliance) do
        print("Alliance: ", allianceC.allianceName, allianceId)
    end
    -- print out each team name along with their ids
    for teamId, teamC in world:query(Components.Team) do
        print("Team: ", teamC.teamName, teamId)
    end]]
end

return TeamProv

