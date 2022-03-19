local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local Llama = require(ReplicatedStorage.Packages.llama)
local Set = Llama.Set

return function(world)
    --[[
    for id, teamedCR, playerC in world:queryChanged(Components.Teamed, Components.Player) do
        local teamEntityId = teamedCR.new.teamId
        local teamC = world:get(teamEntityId, Components.Team)
        world:insert(teamEntityId, teamC:patch({
            Set.add(teamC.players, id)
        }))
        print("Team adding: ", teamC.teamName, teamC.players)

        -- handle the team that it left
        local oldTeamEntityId = teamedCR.old.teamId
        local oldTeamC = world:get(oldTeamEntityId, Components.Team)
        world:insert(oldTeamEntityId, oldTeamC:patch({
            Set.subtract(oldTeamC.players, id)
        }))
        print("Team removing: ", oldTeamC.teamName, oldTeamC.players)
    end]]
end


