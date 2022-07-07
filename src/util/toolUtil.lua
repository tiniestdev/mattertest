local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)
local ToolInfos = require(ReplicatedStorage.ToolInfos)

local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)

local toolUtil = {}

function toolUtil.makePresetTool(toolName, props, world)
    local toolInfo = ToolInfos.Catalog[toolName]
    local entityId = world:spawn()
    local toolbarToolComponentSet = matterUtil.getComponentSetFromArchetype("ToolbarTool")
    local archetypes = {"ToolbarTool"}

    for componentName, componentProps in pairs(toolInfo) do
        if Components[componentName] then
            local mergedProps = Llama.Dictionary.merge(componentProps, props)
            
            -- Things unique to an entity (like instances) should be cloned.
            if componentName == "Corporeal" then
                mergedProps.instance = mergedProps.instance:Clone()
            end

            -- Any archetypes not covered by being a tool, like GunTool or MeleeTool?
            if not toolbarToolComponentSet[componentName] then
                table.insert(archetypes, componentName)
            end

            world:insert(entityId,
                Components[componentName](mergedProps)
            )
            -- patch props
        else
            warn("toolUtil: Unknown component: " .. componentName)
            warn(debug.traceback())
        end
    end

    world:insert(entityId,
        Components.ReplicateToClient({
            ["archetypes"] = archetypes,
        })
    )

    return entityId
end

-- Makes multiple tools and returns an array of newly created entity ids.
-- (you can't define individual properties though)
function toolUtil.makePresetTools(toolNames, world)
    local ids = {}
    for _, toolName in ipairs(toolNames) do
        local newToolId = toolUtil.makePresetTool(toolName, {}, world)
        world:insert(newToolId, world:get(newToolId, Components.Storable):patch({
            order = newToolId,
        }))
        table.insert(ids, newToolId)
    end
    return ids
end

function toolUtil.getCorporealHandle(corporeal)
    if corporeal:IsA("BasePart") then return corporeal end
    return corporeal:FindFirstChild("Handle") or corporeal.PrimaryPart or nil
end

function toolUtil.defaultToolEquip(toolId, charId, world)
    local corporealC = world:get(toolId, Components.Corporeal)
    if not corporealC then return end
    local instanceC = world:get(charId, Components.Instance)
    if not instanceC then return end
    local char = instanceC.instance
    if not char then return end
    
    local foundRightArm = char:FindFirstChild("Right Arm")
    if not foundRightArm then return end

    local corporeal = corporealC.instance
    local handle = toolUtil.getCorporealHandle(corporeal)
    assert(handle, "toolUtil: No handle found for " .. toolId)

    local weld = Instance.new("WeldConstraint")
    weld.Name = "ToolWeld"
    weld.Part0 = handle
    weld.Part1 = foundRightArm
    weld.Parent = handle

    if corporeal:IsA("BasePart") then
        handle.CFrame = foundRightArm.CFrame:toWorldSpace(CFrame.new(0,-foundRightArm.Size.Y/2,0) * CFrame.Angles(math.rad(-90),0,0))
        handle.Position = foundRightArm.CFrame:pointToWorldSpace(Vector3.new(0,-foundRightArm.Size.Y/2,0))
    else
        if not corporeal.PrimaryPart then corporeal.PrimaryPart = handle end
        corporeal:SetPrimaryPartCFrame(foundRightArm.CFrame:toWorldSpace(CFrame.new(0,-foundRightArm.Size.Y/2,0) * CFrame.Angles(math.rad(-90),0,0)))
    end

    physicsUtil.DeepSetCanCollide(corporeal, false)
    corporeal.Parent = char
end

function toolUtil.defaultToolUnequip(toolId, charId, world)
    local corporealC = world:get(toolId, Components.Corporeal)
    if not corporealC then return end
    local handle = toolUtil.getCorporealHandle(corporealC.instance)
    if handle then
        local toolWeld = handle:FindFirstChild("ToolWeld")
        if toolWeld then toolWeld:Destroy() end
    end
    corporealC.instance.Parent = nil
end

return toolUtil