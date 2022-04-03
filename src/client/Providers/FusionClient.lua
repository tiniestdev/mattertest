local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Intercom = require(ReplicatedStorage.Intercom)
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

local UIFolder = script.Parent.Parent.UI
local Main = require(UIFolder.Main)

local Components = require(ReplicatedStorage.components)
local MatterClient = require(script.Parent.MatterClient)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

local FusionClient = {}

FusionClient.AxisName = "FusionClientAxis"

function FusionClient:AxisPrepare()
    -- print("FusionClient: Axis prepare")
end

function FusionClient:AxisStarted()
    -- print("FusionClient: Axis started")

    local storableProps = Fusion.Value({})
    Intercom.Get("UpdateToolbar"):Connect(function(charStorageId)
        storableProps:set(uiUtil.getStorablePropsFromStorage(charStorageId, MatterClient.World))
    end)

    New "ScreenGui" {
        Name = "FusionClient",
        Parent = Players.LocalPlayer.PlayerGui,
        [Fusion.Children] = {
            Main {
                storableProps = storableProps,
            },
        },
    }
end

return FusionClient