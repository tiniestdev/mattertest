local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local Llama = require(ReplicatedStorage.Packages.llama)
local New = Fusion.New

return function(props)
    local defaults = {
        Name = "ClearFrame";
        Size = UDim2.new(1,0,1,0);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 0);
    }
    local finalProps = Llama.Dictionary.merge(defaults, props)
    return New("Frame")(finalProps)
        -- Name = props.Name;
        -- Size = props.Size;
        -- BackgroundTransparency = props.BackgroundTransparency;
        -- BorderSizePixel = 0;
        -- AnchorPoint = props.AnchorPoint;
        -- Position = props.Position;
        -- Parent = props.Parent;
        -- [Fusion.Children] = props[Fusion.Children]
end