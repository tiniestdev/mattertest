local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

return function(props)
    return New "Frame" {
        Name = props.Name;
        Size = UDim2.new(1,0,1,0);
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 0);
        Parent = props.Parent;
        [Fusion.Children] = props[Fusion.Children]
    }
end