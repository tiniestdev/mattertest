local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local Llama = require(ReplicatedStorage.Packages.llama)
local Set = Llama.Set
local List = Llama.List

local ChangeTeamEvent = MatterUtil.NetSignalToEvent("ChangeTeam", Remotes)

return function(world)
    for playerId, teamedCR, playerC in world:queryChanged(Components.Teamed, Components.Player) do
        -- handle team its just been added to
        local teamEntityId = teamedCR.new.teamId
        local teamC = world:get(teamEntityId, Components.Team)
        world:insert(teamEntityId, teamC:patch({
            playerIds = Set.add(teamC.playerIds, playerId)
        }))
        print("==============ADDED PLAYERIDS TO TEAMENTITY")

        -- handle the team that it left
        if teamedCR.old then
            local oldTeamEntityId = teamedCR.old.teamId
            local oldTeamC = world:get(oldTeamEntityId, Components.Team)
            world:insert(oldTeamEntityId, oldTeamC:patch({
                playerIds = Set.subtract(oldTeamC.playerIds, playerId)
            }))
        else
            print("No old team")
        end
    end

    for id, teamCR in world:queryChanged(Components.Team) do
        print("TEAM ", teamCR.new.teamId, "DETECTED ITSELF CHANGE!!! CURRENT PLAYERIDS: ", teamCR.new.playerIds)
    end
end

