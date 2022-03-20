local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local ChangeTeamEvent = MatterUtil.NetSignalToEvent("ChangeTeam", Remotes)

return function(world)
    for id, teamCR, charC in world:queryChanged(Components.Teamed, Components.Character) do
        print("Character changed team: ", charC, " to ", teamCR)
    end

    for id, charCR in world:queryChanged(Components.Character) do
        -- some char entity changed its properties
    end
end
