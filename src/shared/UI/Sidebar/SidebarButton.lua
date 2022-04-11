local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Remotes)
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Children = Fusion.Children

return function(props)
    return New("TextButton")({
        Name = "TextButton",
        Font = Enum.Font.Gotham,
        Text = string.upper(props.Text),
        TextColor3 = Fusion.Computed(function()
            return props.Disabled and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(255, 255, 255)
        end),
        TextSize = 14,
        TextWrapped = true,
        BackgroundColor3 = Fusion.Computed(function()
            return props.Disabled and Color3.fromRGB(41, 38, 38) or Color3.fromRGB(48, 48, 48)
        end),
        Size = UDim2.fromOffset(200, 50),

        [Children] = {
            New("UICorner")({
                Name = "UICorner",
                CornerRadius = UDim.new(0, 4),
            }),
        },

        [Fusion.OnEvent "MouseButton1Click"] = function()
            props.OnClick()
        end,
    })
end