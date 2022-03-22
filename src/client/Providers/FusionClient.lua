local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

local UIFolder = script.Parent.Parent.UI
local Main = require(UIFolder.Main)

local FusionClient = {}

FusionClient.AxisName = "FusionClientAxis"

function FusionClient:AxisPrepare()
    print("FusionClient: Axis prepare")
end

function FusionClient:AxisStarted()
    print("FusionClient: Axis started")

    New "ScreenGui" {
        Name = "FusionClient",
        Parent = Players.LocalPlayer.PlayerGui,
        [Fusion.Children] = {
            Main {},
        },
    }
end

return FusionClient