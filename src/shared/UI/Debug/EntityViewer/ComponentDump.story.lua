local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Fusion)

local ComponentDump = require(script.Parent.ComponentDump)

return function(target)
    print("SDJISHDIUSHIUD")
    local mounted = ComponentDump({
        componentName = "hahaha",
        componentData = {
            sup = "yooo",
            sadyao = "yooo",
            chadano = {
                asd = 21,
                asdsa = 2,
                s222 = "sd",
                sdddddd= 99,
                komi = "wejiowa",
                ben = "wejiowa",
                is = "wejiowa",
            },
            -- defen = workspace.Baseplate,
            defen = workspace,
        },
        frameSizeX = 150,
        expanded = true,
    })
    mounted.Parent = target

    return function()
        mounted:Destroy()
    end
end