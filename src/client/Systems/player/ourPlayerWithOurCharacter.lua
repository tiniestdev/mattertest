local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

return function(world)
    for id, ourPlayerCR in world:queryChanged(Components.Player, Components.Ours) do

        -- I commented this all out because when it was queried, it never caught that Player had a
        -- different character ID. I think it's because it only queried after it had the same character id
        -- throughout multiple changes, and so when the queryChanged picks up on the player entity, it doesn't
        -- think the characterId is anything to report on.
        -- Which means now I have to constantly add the Ours component to the character every time the player changes.
        -- Oh well

        -- if ourPlayerCR.new and ourPlayerCR.old then
            -- print(ourPlayerCR.new.characterId, "from: ", ourPlayerCR.old.characterId)
            -- if ourPlayerCR.new.characterId == ourPlayerCR.old.characterId then
                -- we're not changing characters
                -- continue
            -- end
        -- end

        -- print("CHARF: 0")
        if ourPlayerCR.new then
            -- print("CHARF: 1")
            local ourCharacterId = ourPlayerCR.new.characterId
            -- print("CHARF: ", ourCharacterId)
            if ourCharacterId then
                -- print("CHARF: 2")
                if world:contains(ourCharacterId) then
                    -- print("CHARF: 3")
                    world:insert(ourCharacterId, Components.Ours({}))
                    -- print("Marked character id " .. ourCharacterId .. " as ours")
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
                    -- print("Unmarked character id " .. ourCharacterId .. " to be not ours")
                else
                    -- nothing to do
                end
            end
        end
    end
end