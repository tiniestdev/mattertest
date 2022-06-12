local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Children = Fusion.Children

local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

local EntityDump = require(script.Parent.EntityDump)

return function(props)
    -- key=ID, val=entitydump
    local entityDumps = props.entityDumps or {}

    local entityChildren = {
        New "UIListLayout" {
            Name = "UIListLayout1",
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        },
    }
    for id, entityDump in pairs(entityDumps) do
        entityDump.expanded = false
        table.insert(entityChildren, EntityDump(entityDump))
    end

    return New "Frame" {
        Name = "EntityViewer",
        BackgroundColor3 = Color3.fromRGB(56, 56, 56),
        BorderColor3 = Color3.fromRGB(0, 179, 255),
        BorderSizePixel = 2,
        Position = UDim2.new(0.3, 0, 0.05, 0),
        Size = UDim2.new(0, 500, 0, 600),

        [Children] = {
            New "ScrollingFrame" {
                Name = "ScrollingFrame",
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(),
                Active = true,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),

                [Children] = entityChildren,
            },

            New "UIPadding" {
                Name = "UIPadding",
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
            },
        }
    }
end