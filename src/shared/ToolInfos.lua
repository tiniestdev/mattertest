local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Corporeals = ReplicatedStorage.Corporeals
local ToolScripts = ReplicatedStorage.ToolScripts
local Llama = require(ReplicatedStorage.Packages.llama)
local ToolInfos = {}

-- toolScript is implicitly assumed to be the same name of the key
-- corporeal is implicitly assumed to be the same name in COrporeals
ToolInfos.Catalog = {
    ["Iron"] = {
        Equippable = {
            droppable = true,
            transferrable = true,
        },
        Storable = {
            storageSize = 1,
        },
        Corporeal = {},
    },
    ["Apple"] = {
        Equippable = {
            droppable = true,
            transferrable = true,
        },
        Storable = {
            storageSize = 1,
        },
        Corporeal = {},
    }
}

-- populate default values, but override if overridden
for toolKey, toolInfo in pairs(ToolInfos.Catalog) do
    if toolInfo.Equippable then
        toolInfo.Equippable = Llama.Dictionary.merge(
            {
                presetName = toolKey,
                toolScript = ToolScripts:FindFirstChild(toolKey),
                droppable = true,
                transferrable = true,
            },
            toolInfo.Equippable
        )
    end
    if toolInfo.Corporeal then
        toolInfo.Corporeal = Llama.Dictionary.merge(
            {
                instance = Corporeals:FindFirstChild(toolKey),
            },
            toolInfo.Corporeal
        )
    end
    if toolInfo.Storable then
        toolInfo.Storable = Llama.Dictionary.merge(
            {
                displayName = toolKey,
                storageSize = 1,
            },
            toolInfo.Storable
        )
    end
end

return ToolInfos