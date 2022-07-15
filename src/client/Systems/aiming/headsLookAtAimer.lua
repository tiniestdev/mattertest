local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local function something(dis)
    local st = Matter.useHookState(dis)
    return st
end

return function(world)
    for id, aimerC, characterC, instanceC in world:query(Components.Aimer, Components.Character, Components.Instance) do
        --[[
        local head = instanceC.instance:FindFirstChild("Head")
        local torso = instanceC.instance:FindFirstChild("Torso")
        if not head or not torso then continue end
        local neckJoint = torso:FindFirstChild("Neck")
        if not neckJoint then continue end

        local st = something()
        if not st.num then st.num = 0 end
        st.num = st.num + Matter.useDeltaTime()

        -- yaw, pitch, roll
        local relativeCF = CFrame.Angles(-aimerC.pitch, 0, 0) * CFrame.Angles(0, aimerC.roll, aimerC.yaw)
        -- local relativeCF = CFrame.Angles(0, aimerC.roll, 0) * CFrame.Angles(-aimerC.pitch, 0, aimerC.yaw)
        -- local relativeCF = CFrame.Angles(0, st.num, 0)
        -- neckJoint.Transform = relativeCF
        -- print(neckJoint.Transform)
        ]]
    end
end