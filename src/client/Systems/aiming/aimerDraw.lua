local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local localUtil = require(ReplicatedStorage.Util.localUtil)
local drawUtil = require(ReplicatedStorage.Util.drawUtil)

local function drawstuff(pos, vec)
    local storage = Matter.useHookState(nil, function(state)
        if state.vec then state.vec:Destroy() end
    end)
    if storage.vec then storage.vec:Destroy() end
    storage.vec = drawUtil.vector(pos, vec.Unit * 6, Color3.new(0.5,1,0), nil, 0.1, 0.2)
end

return function(world, _, ui)
    if ui.checkbox("See Aims"):checked() then
        for id, aimerC in world:query(Components.Aimer) do
            local aimerCF = aimerC.aimerCFrame or aimerC.aimerInstance.CFrame
            local aimerLookCF = aimerCF * CFrame.Angles(0, aimerC.yaw, 0) * CFrame.Angles(aimerC.pitch, 0, aimerC.roll)
            local lookVec = aimerLookCF.LookVector
            -- drawstuff(aimerC.aimerInstance.Position, lookVec)
            local pos = aimerC.aimerInstance.Position
            local targ = pos + lookVec * 6
            ui.arrow(pos, targ, Color3.new(0,1,0))
        end
    end
end