local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

return function(world)
    for i, player in Matter.useEvent(Players, "PlayerRemoving") do
        local id = MatterUtil.getEntityId(player)
        if id then
            world:despawn(id)
        end
    end
end

