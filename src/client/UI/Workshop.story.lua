local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

local focusOn = "Toolbar"

local component = require(script.Parent:FindFirstChild(focusOn, true))
local ClearFrame = require(script.Parent.ClearFrame)

return function(target)
    local mounted = ClearFrame {
        Parent = target;
        [Fusion.Children] = {
            component {},
        }
    }
    return function()
        mounted:Destroy()
    end
end
