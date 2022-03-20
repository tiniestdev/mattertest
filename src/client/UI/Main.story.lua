local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Fusion)

local Main = require(script.Parent.Main)
local ClearFrame = require(script.Parent.ClearFrame)

return function(target)
    local mounted = ClearFrame {
        Parent = target;
        [Fusion.Children] = {
            Main {},
        }
    }
    return function()
        mounted:Destroy()
    end
end

