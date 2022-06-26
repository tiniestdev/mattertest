local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local ChangeTeamEvent = MatterUtil.NetSignalToEvent("ChangeTeam", Remotes)

return function(world)
    for id, teamCR in world:queryChanged(Components.Teamed) do
        if teamCR.new then
            local characterC = world:get(id, Components.Character)
            if not characterC then continue end
            -- print("Character changed team: ", characterC, " to ", teamCR)
            -- some fx here? idfk
        end
    end
end
