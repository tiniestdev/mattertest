local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)
local ToolInfos = require(ReplicatedStorage.ToolInfos)

local toolUtil = {}

function toolUtil.makeTool(toolName, props, world)
    local toolInfo = ToolInfos.Catalog[toolName]

    if toolInfo.corporeal then
        local entityId = world:spawn(
            Components.Tool(
                Llama.Dictionary.merge(
                    toolInfo,
                    props
                )
            ),
            Components.Storable({
                storableId = toolName,
                size = toolInfo.storageSize or 1,
            }),
            Components.Corporeal({
                instance = toolInfo.corporeal,
            })
        )
        return entityId
    else
        local entityId = world:spawn(
            Components.Tool(
                Llama.Dictionary.merge(
                    toolInfo,
                    props
                )
            ),
            Components.Storable({
                storableId = toolName,
                size = toolInfo.storageSize or 1,
            })
        )
        return entityId
    end
end

-- Makes multiple tools and returns an array of newly created entity ids.
-- (you can't define individual properties though)
function toolUtil.makeTools(toolNames, world)
    local ids = {}
    for _, toolName in ipairs(toolNames) do
        table.insert(ids, toolUtil.makeTool(toolName, {}, world))
    end
    return ids
end

return toolUtil