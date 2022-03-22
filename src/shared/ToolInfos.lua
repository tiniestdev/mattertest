local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Corporeals = ReplicatedStorage.Corporeals
local ToolScripts = ReplicatedStorage.ToolScripts
local ToolInfos = {}

ToolInfos.Catalog = {
    ["Grab"] = {
        name = "Grab",
        icon = nil,
        -- script is implicitly assumed to be the same name of the key
        droppable = false,
        storable = true,
        transferrable = false, -- can it be moved between different storages?
        equippable = true, -- modifiable at runtime
        storageSize = 0,
    },
    ["Apple"] = {
        name = "Apple",
        icon = nil,
        -- script is implicitly assumed to be the same name of the key
        -- corporeal is implicitly assumed to be the same name in COrporeals
        droppable = true,
        storable = true,
        transferrable = true,
        equippable = true,
        storageSize = 1,
    }
}

for toolKey, toolInfo in pairs(ToolInfos.Catalog) do
    toolInfo.toolScript = ToolScripts:FindFirstChild(toolKey)
    toolInfo.corporeal = Corporeals:FindFirstChild(toolKey)
end

return ToolInfos