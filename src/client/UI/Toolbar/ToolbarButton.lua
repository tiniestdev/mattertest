local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Remotes)
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Value = Fusion.Value

return function(props)
    return New "TextButton" {
        Name = "Button",
        Font = Enum.Font.GothamSemibold,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        TextSize = 14,
        TextWrapped = true,
        Text = props.storableName,
        BackgroundColor3 = Color3.fromRGB(56, 56, 56),
        Size = UDim2.new(1, 0, 1, 0),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        [Fusion.OnEvent "MouseButton1Click"] = function()
            print("Gonna equip ",props.storableId)
        end,
        [Fusion.Children] = {
            New "UICorner" {
                Name = "UICorner",
            },
            New "UITextSizeConstraint" {
                Name = "UITextSizeConstraint",
                MaxTextSize = 20,
            },
        }
    }
end