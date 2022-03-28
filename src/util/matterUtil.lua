local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Components = require(ReplicatedStorage.components)
local ComponentInfo = require(ReplicatedStorage.ComponentInfo)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Archetypes = require(ReplicatedStorage.Archetypes)

local matterUtil = {}

matterUtil.instanceToComponentData = {
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

function matterUtil.getProcedures(instance, overrides)
    for className, procedures in pairs(overrides) do
        if instance:IsA(className) then
            return procedures
        end
    end
    error("No procedures for " .. instance.ClassName)
end

function matterUtil.getInstanceComponentData(instance, componentName)
    -- find the correct key using IsA()
    for key, value in pairs(matterUtil.instanceToComponentData) do
        if instance:IsA(key) then
            return value[componentName](instance)
        end
    end
    return nil
end

function matterUtil.getEntityId(instance)
    return RunService:IsServer() and instance:GetAttribute("entityServerId") or instance:GetAttribute("entityClientId")
end

function matterUtil.setEntityId(instance, id)
    if RunService:IsServer() then
        instance:SetAttribute("entityServerId", id)
    else
        instance:SetAttribute("entityClientId", id)
    end
end

function matterUtil.bindInstanceToComponent(instance, component, world)
end

--[[
    The collectionservice will listen to every tag that is also a component name.
    It will deal with the creation of entity creation, component adding, and component removing
    based on tags.
    If components are removed in data, it is not reflected in tags. They may linger in instances.
    Do not rely on tags to be the source of truth, always refer to world:get.
]]
function matterUtil.bindCollectionService(world)
end

function matterUtil.NetSignalToEvent(signalName, remotes)
    local newSignal = Instance.new("BindableEvent")
    if RunService:IsServer() then
        remotes.Server:OnEvent(signalName, function(...)
            newSignal:Fire(...)
        end)
    else
        remotes.Client:WaitFor(signalName):andThen(function(fromServer)
            fromServer.instance.OnClientEvent:Connect(function(...)
                newSignal:Fire(...)
            end)
        end)
    end
    return newSignal
end

function matterUtil.ObservableToEvent(observable)
    local newSignal = Instance.new("BindableEvent")
    observable:Subscribe(function(...)
        newSignal:Fire(...)
    end)
    return newSignal
end

function matterUtil.cmdrPrintEntityDebugInfo(context, entityId, world)
    if world:contains(entityId) then
        context:Reply("EntityId " .. entityId .. ":")
        for componentName, _ in pairs(Components) do
            if world:get(entityId, Components[componentName]) then
                context:Reply("Is a " .. componentName .. ":")
                for componentField, fieldValue in pairs(world:get(entityId, Components[componentName])) do
                    if typeof(fieldValue) == "Instance" then
                        context:Reply("\t" .. fieldValue.ClassName .. " " .. componentField .. ": " .. fieldValue:GetFullName())
                    else
                        if typeof(fieldValue) == "table" then
                            for i,v in pairs(fieldValue) do
                                context:Reply("\t\t" .. tostring(i) .. " : " .. tostring(v))
                            end
                        else
                            context:Reply("\t" .. typeof(fieldValue) .. " " .. componentField .. ": " .. tostring(fieldValue))
                        end
                    end
                end
            end
        end
        return true
    else
        return "EntityId " .. entityId .. " does not exist in the local world."
    end
end

function matterUtil.isArchetype(entityId, archetypeName, world)
    local componentSet = matterUtil.getComponentSetFromArchetype(archetypeName)
    for componentName, _ in pairs(componentSet) do
        if not world:get(entityId, Components[componentName]) then
            return false
        end
    end
    return true
end

function matterUtil.getComponentSetFromArchetype(archetypeName)
    local archetypesToCheck = Archetypes.Catalog[archetypeName]
    if archetypesToCheck then
        print("Archetypes to check:", archetypesToCheck)
        local componentNameSet = {}
        for _, subArchetypeName in ipairs(archetypesToCheck) do
            componentNameSet = Llama.Set.union(componentNameSet, matterUtil.getComponentSetFromArchetype(subArchetypeName))
        end
        return componentNameSet
    else
        print("Archetypes to check:", archetypeName)
        return Llama.Set.fromList({ archetypeName })
    end
end

function matterUtil.getReferenceSetPropertiesOfComponent(componentName, componentData)
    local propertyNames = {}
    local componentPropertyInfos = ComponentInfo.Catalog[componentName]
    for propertyName, propertyMetadata in pairs(componentPropertyInfos) do
        if propertyMetadata.isReferenceSet then
            table.insert(propertyNames, propertyName)
        end
    end
    return propertyNames
end
function matterUtil.getReferencePropertiesOfComponent(componentName, componentData)
    local propertyNames = {}
    local componentPropertyInfos = ComponentInfo.Catalog[componentName]
    for propertyName, propertyMetadata in pairs(componentPropertyInfos) do
        if propertyMetadata.isReference then
            table.insert(propertyNames, propertyName)
        end
    end
    return propertyNames
end

-- Takes a payload, and gets a list of all the serverIds of entities to make shells of from component properties.
function matterUtil.getServerEntityArchetypesOfReferences(payload)
    local serverEntities = {}
    local components = payload.components
    for componentName, componentData in pairs(components) do
        local properties = ComponentInfo.Catalog[componentName]
        for propertyName, propertyMetadata in pairs(properties) do
            if propertyMetadata.isReference then
                local refArchetype = propertyMetadata.referenceToArchetype
                assert(refArchetype, "No referenceToArchetype for " .. componentName .. "." .. propertyName)

                -- does the field actually reference an entity or is it nil
                if componentData[propertyName] then
                    table.insert(serverEntities, {
                        entityId = componentData[propertyName],
                        archetype = refArchetype,
                    })
                end

            elseif propertyMetadata.isReferenceSet then
                local refArchetype = propertyMetadata.referenceToArchetype
                assert(refArchetype, "No referenceToArchetype for " .. componentName .. "." .. propertyName)

                -- loop through the *set*
                for entityId, _ in pairs(componentData[propertyName]) do
                    table.insert(serverEntities, {
                        entityId = entityId,
                        archetype = refArchetype,
                    })
                end

            end
        end
    end

    return serverEntities
end

function matterUtil.linkBidirectionalEntityIdRefs(alphaName, betaName, world)
    -- A change in an equippable tool changes the beta(s).

    -- the referenceField is camelcase; only lowercase the first letter.
    -- For example: the component name "FruitJuices" should be "fruitJuices".
    local alphaReferenceField = string.lower(string.sub(alphaName, 1, 1)) .. string.sub(alphaName, 2)
    local betaReferenceField = string.lower(string.sub(betaName, 1, 1)) .. string.sub(betaName, 2)

    for alphaId, alphaCR in world:queryChanged(Components[alphaName]) do

        -- check for actual change and reconciliation
        if alphaCR.old and alphaCR.new then
            local newBetaId = alphaCR.new[betaReferenceField]
            local oldBetaId = alphaCR.old[betaReferenceField]
            if alphaCR.new.doNotReconcile then
                world:insert(alphaId, alphaCR.new:patch({
                    doNotReconcile = false
                }))
                continue
            end
            if newBetaId == oldBetaId then continue end
        end

        -- Update whatever beta component it's pointing to now
        if alphaCR.new then
            local newBetaId = alphaCR.new[betaReferenceField]
            if newBetaId then
                if world:contains(newBetaId) then
                    local betaC = world:get(newBetaId, Components[betaName])
                    if betaC then
                        world:insert(newBetaId, betaC:patch({
                            [alphaReferenceField] = alphaId,
                            doNotReconcile = true,
                        }))
                        print("LINKED " .. alphaName .. ":" .. alphaId .. " TO " .. betaName .. ":" .. newBetaId)
                    else
                        warn("Component " .. alphaName .. "'s " .. betaReferenceField .. ":" .. newBetaId .. " does not have an " .. betaName .. " component.")
                    end
                else
                    warn("Component " .. alphaName .. "'s " .. betaReferenceField .. " pointed to a non-existent entity:", newBetaId)
                    warn("Restoring old state:", alphaCR.old)
                    world:insert(alphaId, alphaCR.old:patch({
                        doNotReconcile = true,
                    }))
                    continue
                end
            end
        end

        -- Update the old beta component to remove its own reference
        if alphaCR.old then
            local oldBetaId = alphaCR.old[betaReferenceField]
            if oldBetaId then
                if world:contains(oldBetaId) then
                    local oldBetaC = world:get(oldBetaId, Components[betaName])
                    if oldBetaC then
                        if oldBetaC[alphaReferenceField] == alphaId then
                            world:insert(oldBetaId, oldBetaC:patch({
                                [alphaReferenceField] = Matter.None,
                                doNotReconcile = true,
                            }))
                            print("UNLINKED " .. alphaName .. ":" .. alphaId .. " FROM " .. betaName .. ":" .. oldBetaId)
                        else
                            warn("Previous " .. betaName .. " component did not reference " .. alphaReferenceField .. " " .. alphaId .. ", it referenced " .. oldBetaC[alphaReferenceField])
                            -- not really much to reject our own change since it wasn't there in the first place
                        end
                    else
                        warn("Component " .. betaName .. " does not exist in entity:", oldBetaId)
                        continue
                    end
                else
                    -- beta was deleted
                end
            end
        end
    end

    -- When an beta changes what it's equipping, update the alpha 
    for betaId, betaCR in world:queryChanged(Components[betaName]) do

        if betaCR.new and betaCR.old then
            local newAlphaId = betaCR.new[alphaReferenceField]
            local oldAlphaId = betaCR.old[alphaReferenceField]
            if betaCR.new.doNotReconcile then
                world:insert(betaId, betaCR.new:patch({
                    doNotReconcile = false
                }))
                continue
            end
            if newAlphaId == oldAlphaId then continue end
        end

        -- Update the alpha component it just pointed to
        if betaCR.new then
            local newAlphaId = betaCR.new[alphaReferenceField]
            if newAlphaId then
                if world:contains(newAlphaId) then
                    local alphaC = world:get(newAlphaId, Components[alphaName])
                    if alphaC then
                        world:insert(newAlphaId, alphaC:patch({
                            [betaReferenceField] = betaId,
                            doNotReconcile = true,
                        }))
                        print("LINKED " .. alphaName .. ":" .. newAlphaId .. " TO " .. betaName .. ":" .. betaId)
                    else
                        warn("Component " .. betaName .. "'s " .. alphaReferenceField .. ":" .. newAlphaId .. " does not have an " .. alphaName .. " component.")
                    end
                else
                    warn("Component " .. betaName .. "'s " .. alphaReferenceField .. " pointed to a non-existent entity:", newAlphaId)
                    warn("Restoring old state:", betaCR.old)
                    world:insert(betaId, betaCR.old:patch({
                        doNotReconcile = true,
                    }))
                    continue
                end
            end
        end

        -- Update the alpha component that it broke away from
        if betaCR.old then
            local oldAlphaId = betaCR.old[alphaReferenceField]
            if oldAlphaId then
                if world:contains(oldAlphaId) then
                    local oldAlphaC = world:get(oldAlphaId, Components[alphaName])
                    if oldAlphaC then
                        if oldAlphaC[betaReferenceField] == betaId then
                            world:insert(oldAlphaId, oldAlphaC:patch({
                                [betaReferenceField] = Matter.None,
                                doNotReconcile = true,
                            }))
                            print("UNLINKED " .. alphaName .. ":" .. betaId .. " FROM " .. betaName .. ":" .. oldAlphaId)
                        else
                            warn("Previous " .. alphaName .. " component did not reference " .. betaReferenceField .. " " .. betaId .. ", it referenced " .. oldAlphaC[betaReferenceField])
                            -- not really much to reject our own change since it wasn't there in the first place
                        end
                    else
                        warn("Component " .. alphaName .. " does not exist in entity:", oldAlphaId)
                        continue
                    end
                else
                    -- alpha was deleted
                end
            end
        end
    end
end

return matterUtil