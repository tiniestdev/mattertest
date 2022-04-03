local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    for id, ourPlayerCR in world:queryChanged(Components.Player, Components.Ours) do
        if ourPlayerCR.new and ourPlayerCR.old then
            if ourPlayerCR.new.characterId == ourPlayerCR.old.characterId then
                -- we're not changing characters
                continue
            end
        end

        if ourPlayerCR.new then
            local ourCharacterId = ourPlayerCR.new.characterId
            if ourCharacterId then
                if world:contains(ourCharacterId) then
                    local characterInstance = ourPlayerCR.new.player.Character
                    world:insert(ourCharacterId, Components.Ours({}), Components.ShowMatterDebug({
                        adornee = characterInstance.HumanoidRootPart,
                    }))
                    print("Marked character id " .. ourCharacterId .. " as ours")
                else
                    warn("ourCharacterId ", ourCharacterId, "is not in world")
                    error(debug.traceback())
                end
            end
        end

        if ourPlayerCR.old then
            local ourCharacterId = ourPlayerCR.old.characterId
            if ourCharacterId then
                if world:contains(ourCharacterId) then
                    world:remove(ourCharacterId, Components.Ours({}))
                    print("Unmarked character id " .. ourCharacterId .. " to be not ours")
                else
                    -- nothing to do
                end
            end
        end
    end
end