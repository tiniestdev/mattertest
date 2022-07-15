local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local localUtil = require(ReplicatedStorage.Util.localUtil)

return function(world)
    -- for id, gunToolC in world:query(Components.GunTool) do
    --     print(id)
    -- end
    for id, gunToolC, equippableC in world:query(Components.GunTool, Components.Equippable) do
        local charId = localUtil.waitForCharacterEntityId(world)
        -- print(id, gunToolC, charId)
        if equippableC.equipperId == charId then
            print(equippableC.equipperId, charId)
            -- UserInputService.InputBegan:Connect(function(inputObject)
            for i, input in Matter.useEvent(UserInputService, "InputBegan") do
                print(input)
            end
        end
    end
end