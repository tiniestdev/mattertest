local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.Components)
local Matter = require(ReplicatedStorage.Packages.matter)

local function flammablesJump(world)
    if Matter.useThrottle(1) then
        for id, instance, flammable in world:query(Components.Instance, Components.Flammable) do
            instance.instance:ApplyImpulse(Vector3.new(0, instance.instance:GetMass() * workspace.Gravity * 0.1, 0))
        end
    end
end

return flammablesJump