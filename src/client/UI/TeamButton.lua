local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Remotes)
local Fusion = require(ReplicatedStorage.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)
local New = Fusion.New

return function(props)
    return New "TextButton" {
        Name = "TeamButton";
        Size = UDim2.new(0.3, 0, 1, 0);
        Text = string.upper(props.team);
        Font = Enum.Font.GothamBlack;
        TextScaled = true;
        [Fusion.Children] = {
            New "UITextSizeConstraint" {
                MaxTextSize = 40;
                MinTextSize = 5;
            }
        };
        [Fusion.OnEvent "MouseButton1Click"] = function()
            Remotes.Client:Get("ChangeTeam"):SendToServer(props.team)
            print("sent event with args: " .. props.team)
        end;
    }
end