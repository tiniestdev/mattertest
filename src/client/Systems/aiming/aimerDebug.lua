local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local drawUtil = require(ReplicatedStorage.Util.drawUtil)

return function(world)
    -- for id, aimerC in world:query(Components.Aimer) do
    --     local aimerCF = aimerC.aimerCFrame or aimerC.aimerInstance.CFrame
    --     local aimerLookCF = aimerCF * CFrame.Angles(0, aimerC.yaw, 0) * CFrame.Angles(aimerC.pitch, 0, aimerC.roll)
    --     local lookVec = aimerLookCF.LookVector
    --     drawUtil.vector(aimerC.aimerInstance.Position, lookVec, nil, nil, 0.05, 0.2)
    -- end
end