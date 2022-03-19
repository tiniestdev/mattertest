local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

local TeamChoose = require(script.Parent.TeamChoose)
local ClearFrame = require(script.Parent.ClearFrame)

return function(target)
    local mounted = ClearFrame {
        Parent = target;
        [Fusion.Children] = {
            TeamChoose {},
        }
    }
    return function()
        mounted:Destroy()
    end
end
