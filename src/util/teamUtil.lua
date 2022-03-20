local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Teams = require(ReplicatedStorage.Teams)
local Llama = require(ReplicatedStorage.Packages.llama)

local teamUtil = {}

function teamUtil.listPlayerIds(playerIdsSet)
    local playerIds = {}
    for playerId, _ in pairs(playerIdsSet) do
        table.insert(playerIds, playerId)
    end
    return playerIds
end

function teamUtil.getUnfilledTeamId(world)
    local min
    local chosenId = Teams.NameToId["Raiders"]

    for id, teamC in world:query(Components.Team) do
        if teamC.autoAssignable then
            local teamCount = #teamUtil.listPlayerIds(teamC.playerIds)
            if (not min) or (teamCount < min) then
                min = min and math.min(teamCount, min) or teamCount
                chosenId = id
            end
        end
    end

    return chosenId
end

return teamUtil;