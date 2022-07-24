local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Intercom = require(ReplicatedStorage.Intercom)
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

local UIFolder = ReplicatedStorage.UI
local Main = require(UIFolder.Main)
local EntityViewer = require(UIFolder.Debug.EntityViewer.EntityViewer)

local Components = require(ReplicatedStorage.components)
local MatterClient = require(script.Parent.MatterClient)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local Remotes = require(ReplicatedStorage.Remotes)

local FusionClient = {}

FusionClient.AxisName = "FusionClientAxis"

function FusionClient:AxisPrepare()
    -- print("FusionClient: Axis prepare")
end

function FusionClient:AxisStarted()
    -- print("FusionClient: Axis started")

    -- localUtil.waitForPlayerEntityId(MatterClient.World)
    -- localUtil.waitForCharacterEntityId(MatterClient.World)
    local storableProps = Fusion.Value({})
    Intercom.Get("UpdateToolbar"):Connect(function()
        local myCharacterId = localUtil.getMyCharacterEntityId(MatterClient.World)
        if not myCharacterId then return end
        storableProps:set(uiUtil.getStorablePropsFromStorage(myCharacterId, MatterClient.World))
    end)

    Intercom.Get("ChangeTeam"):Connect(function(team)
        Remotes.Client:Get("ChangeTeam"):SendToServer(team)
    end)
    -- local data = matterUtil.getEntityViewerData(MatterClient.World)
    -- task.wait()
    New "ScreenGui" {
        Name = "FusionClient",
        Parent = Players.LocalPlayer.PlayerGui,
        [Fusion.Children] = {
            Main {
                storableProps = storableProps,
            },
            -- EntityViewer({
            --     entityDumps = data,
            --     theme = Color3.new(0, 0.7, 1),
            --     refreshCallback = function()
            --         return matterUtil.getEntityViewerData(MatterClient.World)
            --     end,
            --     position = UDim2.new(0.1, 0, 0.2, 0),
            -- }),
            -- EntityViewer({
            --     entityDumps = data,
            --     theme = Color3.new(0, 0.7, 0),
            --     refreshCallback = function()
            --         local success, value = Remotes.Client:Get("RequestEntitiesDump"):CallServerAsync(nil):await()
            --         -- print("GOT EQUIP", success, value)
            --         return value
            --         -- Remotes.Client:Get("RequestGrab"):CallServerAsync(raycastResult.Instance, grabOffsetCFrame, grabObjectCFrame):andThen(function(response)
            --     end,
            --     position = UDim2.new(0.5, 0, 0.2, 0),
            -- }),
        },
    }
end

return FusionClient