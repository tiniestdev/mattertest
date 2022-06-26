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
    local entityDumps = Fusion.Value(props.entityDumps or {})

    local entitychildren = Fusion.Computed(function()
        local entityChildren = {
            New "UIListLayout" {
                Name = "UIListLayout1",
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
        }
        for id, entityDump in pairs(entityDumps:get()) do
            entityDump.expanded = false
            table.insert(entityChildren, EntityDump(entityDump))
        end
        return entityChildren
    end)

    local visible = Fusion.Value(true)

    return New "Frame" {
        Name = "EntityViewer",
        BackgroundColor3 = Color3.fromRGB(56, 56, 56),
        BorderColor3 = props.theme or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = Fusion.Computed(function()
            return visible:get() and 2 or 0
        end),
        Position = props.position or UDim2.new(0.3, 0, 0.05, 0),
        Size = Fusion.Computed(function()
            return UDim2.new(0, visible:get() and 400 or 0, 0, visible:get() and 500 or 0)
        end),
        Active = true,
        Draggable = true,
        -- Visible = Fusion.Computed(function()
        --     return visible:get()
        -- end),

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

                [Children] = entitychildren,
            },

            New "UIPadding" {
                Name = "UIPadding",
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
            },

            -- exit button on the top left corner
            New "TextButton" {
                Name = "ExitButton",
                Font = Enum.Font.Gotham,
                Text = "X",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                BackgroundColor3 = Color3.fromRGB(56, 27, 27),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 0, 0, -27),
                [Fusion.OnEvent("MouseButton1Click")] = function()
                    visible:set(not visible:get())
                end,
            },

            -- refresh button
            New "TextButton" {
                Name = "RefreshButton",
                Font = Enum.Font.Gotham,
                Text = "Refresh",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                BackgroundColor3 = Color3.fromRGB(35, 97, 68),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 100, 0, 20),
                Position = UDim2.new(0, 30, 0, -27),
                [Fusion.OnEvent("MouseButton1Click")] = function()
                    entityDumps:set(props.refreshCallback())
                end,
            },
        }
    }
end