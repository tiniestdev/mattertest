local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = {}

MatterUtil.instanceToComponentData = {
    BasePart = {
        Physics = function(part)
            return {
                velocity = part.AssemblyLinearVelocity,
                angularVelocity = part.AssemblyAngularVelocity,
                mass = part.AssemblyMass,
                density = part.CustomPhysicalProperties.Density,
                friction = part.CustomPhysicalProperties.Friction,
                restitution = part.CustomPhysicalProperties.Elasticity,
            }
        end,
        Transform = function(part)
            return {
                cframe = part.CFrame,
                size = part.Size,
            }
        end,
    },
    Attachment = {
        Physics = {

        },
        Transform = function(att)
            return {
                cframe = att.WorldCFrame,
            }
        end,
    }
}

function MatterUtil.getProcedures(instance, overrides)
    for className, procedures in pairs(overrides) do
        if instance:IsA(className) then
            return procedures
        end
    end
    error("No procedures for " .. instance.ClassName)
end

function MatterUtil.getInstanceComponentData(instance, componentName)
    -- find the correct key using IsA()
    for key, value in pairs(MatterUtil.instanceToComponentData) do
        if instance:IsA(key) then
            return value[componentName](instance)
        end
    end
    return nil
end

function MatterUtil.getEntityId(instance)
    return RunService:IsServer() and instance:GetAttribute("entityServerId") or instance:GetAttribute("entityClientId")
end

function MatterUtil.setEntityId(instance, id)
    if RunService:IsServer() then
        instance:SetAttribute("entityServerId", id)
    else
        instance:SetAttribute("entityClientId", id)
    end
end

function MatterUtil.bindInstanceToComponent(instance, component, world)
    local existingId = MatterUtil.getEntityId(instance)
    if existingId then
        -- We might have a component already inserted with populated data from somewhere else.
        if world:get(existingId, component) then
            print("Existing component", component, " for instance ", instance, "returning")
            return
        end
        -- If not, just put nothing in the component and slap it in the object
        world:insert(existingId, component())
    else
        -- Brand new instance not recognized by our world.
        -- Make it an official entity of our world
        local id = world:spawn(
            component(),
            Components.Instance({
                instance = instance,
            })
        )
        MatterUtil.setEntityId(instance, id)

        -- If it makes sense to, insert physics and transform components as well
        if instance:IsA("BasePart") and instance.CustomPhysicalProperties == nil then
            instance.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1, 0.5, 1, 1)
        end
        local physicsData = MatterUtil.getInstanceComponentData(instance, "Physics")
        local transformData = MatterUtil.getInstanceComponentData(instance, "Transform")
        if physicsData then world:insert(id, Components.Physics(physicsData)) end
        if transformData then world:insert(id, Components.Transform(transformData)) end

        -- Try not to handle instance removal from workspace since it should be lesser than
        -- our raw data world. If it gets removed from workspace for some odd reason
        -- we'll probably just recreate it to fit with our data.
    end
end

--[[
    The collectionservice will listen to every tag that is also a component name.
    It will deal with the creation of entity creation, component adding, and component removing
    based on tags.
    If components are removed in data, it is not reflected in tags. They may linger in instances.
    Do not rely on tags to be the source of truth, always refer to world:get.
]]
function MatterUtil.bindCollectionService(world)
    -- Goes through every tagname and makes a component out of these tags
    for tagName, component in pairs(Components) do
        for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
            MatterUtil.bindInstanceToComponent(instance, component, world)
        end
    
        CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
            MatterUtil.bindInstanceToComponent(instance, component, world)
        end)
    
        CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
            -- just remove the corresponding component from the instance, don't delete the entire entity
            local entityId = MatterUtil.getEntityId(instance)
            if entityId then
                world:remove(entityId, component)
            end
        end)
    end
end

function MatterUtil.NetSignalToEvent(signalName, remotes)
    local newSignal = Instance.new("BindableEvent")
    if RunService:IsServer() then
        remotes.Server:OnEvent(signalName, function(...)
            newSignal:Fire(...)
        end)
    else
        remotes.Client:OnEvent(signalName, function(...)
            newSignal:Fire(...)
        end)
    end
    return newSignal
end

function MatterUtil.ObservableToEvent(observable)
end

return MatterUtil