local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)

local RDM = Random.new()

local function updatePart(part, transform)
    part.CFrame = transform.cframe
end

local overrides = {
    BasePart = {
        onComponentChange = function(id, transformCR, instanceC)
            updatePart(instanceC.instance, transformCR.new)
        end,
        onInstanceChange = function(id, instanceCR, transformC)
            updatePart(instanceCR.new.instance, transformC)
        end,
        observer = function(id, instanceC, transformC, world)
            if instanceC.instance.Anchored then return end
            if instanceC.instance.CFrame ~= transformC.cframe then
                world:insert(
                    id,
                    Components.Transform({
                        cframe = instanceC.instance.CFrame,
                        doNotReconcile = true,
                    })
                )
            end
        end,
    },
    Attachment = {
        onComponentChange = function()
            warn("TODO")
        end,
        onInstanceChange = function()
            warn("TODO")
        end,
        observer = function()
            warn("TODO")
        end,
        shouldUpdate = function(instanceC, transformC)
            return instanceC.instance.WorldCFrame ~= transformC.cframe
        end,
    },
}


return function(world)
    -- Transform added/changed on existing Instance entity
    for id, transformCR in world:queryChanged(Components.Transform) do
        local instanceC = world:get(id, Components.Instance)
        if not instanceC then continue end
        if transformCR.new and not transformCR.new.doNotReconcile then
            MatterUtil.getProcedures(instanceC.instance, overrides).onComponentChange(id, transformCR, instanceC)
        end
    end

    -- Instance added/changed on existing entity with Transform
    for id, instanceCR in world:queryChanged(Components.Instance) do
        if instanceCR.new then
            local transformC = world:get(id, Components.Transform)
            if not transformC then continue end
            if instanceCR.new then
                MatterUtil.getProcedures(instanceCR.new.instance, overrides).onInstanceChange(id, instanceCR, transformC)
            end
        end
    end

    -- Update transform components based on roblox transform
    for id, instanceC, transformC in world:query(Components.Instance, Components.Transform) do
        MatterUtil.getProcedures(instanceC.instance, overrides).observer(id, instanceC, transformC, world)
    end
end