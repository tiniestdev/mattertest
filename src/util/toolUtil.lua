local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)
local ToolInfos = require(ReplicatedStorage.ToolInfos)

local toolUtil = {}

function toolUtil.makePresetTool(toolName, props, world)
    local toolInfo = ToolInfos.Catalog[toolName]
    local entityId = world:spawn()

    for componentName, componentProps in pairs(toolInfo) do
        if Components[componentName] then
            local mergedProps = Llama.Dictionary.merge(componentProps, props)
            world:insert(entityId,
                Components[componentName](mergedProps),
                Components.ReplicateToClient({
                    archetypes = {"ToolbarTool"}
                })
            )
            -- patch props
        else
            warn("toolUtil: Unknown component: " .. componentName)
            warn(debug.traceback())
        end
    end

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

return toolUtil