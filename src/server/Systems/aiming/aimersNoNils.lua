local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

return function(world)
    for id, aimerCR in world:queryChanged(Components.Aimer) do
        if aimerCR.new then
            local aimerC = aimerCR.new
            if aimerC.pitch == nil then
                world:insert(id, aimerC:patch({
                    pitch = 0,
                }))
            end
            if aimerC.yaw == nil then
                world:insert(id, aimerC:patch({
                    yaw = 0,
                }))
            end
            if aimerC.roll == nil then
                world:insert(id, aimerC:patch({
                    roll = 0,
                }))
            end
        end
    end
end