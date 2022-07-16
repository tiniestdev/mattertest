local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Corporeals = ReplicatedStorage.Corporeals
local ToolScripts = ReplicatedStorage.ToolScripts
local Llama = require(ReplicatedStorage.Packages.llama)
local Constants = require(ReplicatedStorage.Constants)
local ToolInfos = {}

-- toolScript is implicitly assumed to be the same name of the key
-- corporeal is implicitly assumed to be the same name in COrporeals
ToolInfos.Catalog = {
    ["Iron"] = {
        -- by default, this will run toolUtil.defaultToolEquip
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
    },
    ["Test Gun"] = {
        Equippable = {
            droppable = true,
            transferrable = true,
        },
        Storable = {
            storageSize = 2,
        },
        Corporeal = {},
        GunTool = {
            storageCapacity = -1,
            magCapacity = 10,
            fireRate = 5,
            fireModes = {
                Constants.FireModes.Semi,
                Constants.FireModes.Auto,
                Constants.FireModes.Burst,
            },
            roundType = "Bouncy",
            barrelSpeed = 1000,
        },
    },
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
        local foundInstance = Corporeals:FindFirstChild(toolKey)
        if not foundInstance then
            warn("ToolInfos: No corporeal found for " .. toolKey)
        end
        ToolInfos.Catalog[toolKey].Corporeal = Llama.Dictionary.merge(
            {
                instance = foundInstance,
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