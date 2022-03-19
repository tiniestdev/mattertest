local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

local TeamButton = require(script.Parent.TeamButton)

return function(props)
    return New "Frame" {
        Name = "ChoiceFrame";
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0.5, 0, 0.8, 0);
        Size = UDim2.new(1, 0, 0.1, 0);
        [Fusion.Children] = {
            New "UISizeConstraint" {
                MinSize = Vector2.new(0,50);
            },
            New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Center;
                Padding = UDim.new(0, 10);
                VerticalAlignment = Enum.VerticalAlignment.Center;
            },
            TeamButton {
                team = "Raiders";
            },
            TeamButton {
                team = "Guards";
            },
            TeamButton {
                team = "Officials";
            },
        }
    }
end