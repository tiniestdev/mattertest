local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.Components)
local Matter = require(ReplicatedStorage.Packages.matter)

local RDM = Random.new()

local function flammablesClone(world)
    local queried = {}
    for id, instance, flammable in world:query(Components.Instance, Components.Flammable) do
        table.insert(queried, instance.instance)
    end

    if Matter.useThrottle(2) then
        for i,v in ipairs(queried) do
            if (RDM:NextNumber() < 0.5) then
                local newClone = v:Clone();
                newClone.Parent = workspace
                local spawnForce = 40;
                local spawnRotForce = 20;
                task.delay(0.1, function()
                    CollectionService:AddTag(newClone, "Flammable")
                    newClone.AssemblyAngularVelocity = Vector3.new(
                        RDM:NextNumber(-spawnRotForce, spawnRotForce),
                        RDM:NextNumber(spawnRotForce, spawnRotForce*1.5),
                        RDM:NextNumber(-spawnRotForce, spawnRotForce)
                    )
                    newClone.AssemblyLinearVelocity = Vector3.new(
                        RDM:NextNumber(-spawnForce, spawnForce),
                        RDM:NextNumber(spawnForce, spawnForce*1.5),
                        RDM:NextNumber(-spawnForce, spawnForce)
                    )
                end)
            end
        end
    end
end

return flammablesClone