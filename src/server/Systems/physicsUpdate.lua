local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)

local RDM = Random.new()

local overrides = {
    BasePart = {
        onComponentChange = function(id, physicsCR, instanceC)
            instanceC.instance.Color = Color3.new(RDM:NextNumber(), RDM:NextNumber(), RDM:NextNumber())
            instanceC.instance.AssemblyLinearVelocity = physicsCR.new.velocity
            instanceC.instance.AssemblyAngularVelocity = physicsCR.new.angularVelocity
            instanceC.instance.CustomPhysicalProperties = PhysicalProperties.new(
                physicsCR.new.density,
                physicsCR.new.friction,
                physicsCR.new.restitution
            )
        end,
        onInstanceChange = function(id, instanceCR, physicsC)
            return instanceCR.new.instance.AssemblyLinearVelocity ~= physicsC.velocity or
                instanceCR.new.instance.AssemblyAngularVelocity ~= physicsC.angularVelocity or
                instanceCR.new.instance.CustomPhysicalProperties.Density ~= physicsC.density or
                instanceCR.new.instance.CustomPhysicalProperties.Friction ~= physicsC.friction or
                instanceCR.new.instance.CustomPhysicalProperties.Elasticity ~= physicsC.restitution
        end,
        observer = function(id, instanceC, physicsC, world)
            if instanceC.instance.Anchored then return end
            if instanceC.instance.AssemblyLinearVelocity ~= physicsC.velocity or
                instanceC.instance.AssemblyAngularVelocity ~= physicsC.angularVelocity or
                instanceC.instance.CustomPhysicalProperties.Density ~= physicsC.density or
                instanceC.instance.CustomPhysicalProperties.Friction ~= physicsC.friction or
                instanceC.instance.CustomPhysicalProperties.Elasticity ~= physicsC.restitution then
                world:insert(
                    id,
                    Components.Physics({
                        velocity = instanceC.instance.AssemblyLinearVelocity,
                        angularVelocity = instanceC.instance.AssemblyAngularVelocity,
                        mass = instanceC.instance.AssemblyMass,
                        density = instanceC.instance.CustomPhysicalProperties.Density,
                        friction = instanceC.instance.CustomPhysicalProperties.Friction,
                        restitution = instanceC.instance.CustomPhysicalProperties.Elasticity,
                        doNotReconcile = true,
                    })
                )
            end
        end,
    },
}

return function(world)
    -- Physics added/changed on existing Instance entity
    for id, physicsCR in world:queryChanged(Components.Physics) do
        local instanceC = world:get(id, Components.Instance)
        if not instanceC then continue end
        if physicsCR.new and not physicsCR.new.doNotReconcile then
            MatterUtil.getProcedures(instanceC.instance, overrides).onComponentChange(id, physicsCR, instanceC)
        end
    end

    -- Instance added/changed on existing entity with Physics
    for id, instanceCR in world:queryChanged(Components.Instance) do
        local physicsC = world:get(id, Components.Physics)
        if not physicsC then continue end
        if instanceCR.new and not instanceCR.new.doNotReconcile then
            MatterUtil.getProcedures(instanceCR.new.instance, overrides).onInstanceChange(id, instanceCR, physicsC)
        end
    end

    -- Update physics components based on roblox physics
    for id, instanceC, physicsC in world:query(Components.Instance, Components.Physics) do
        MatterUtil.getProcedures(instanceC.instance, overrides).observer(id, instanceC, physicsC, world)
    end
end