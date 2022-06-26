local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Children = Fusion.Children

local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

local ComponentDump = require(script.Parent.ComponentDump)

return function(props)
    local entityId = props.entityId or "??"
    local headerTags = props.headerTags or {}
    -- a table, every key = component name, every value = its data
    local componentDumps = props.componentDumps or {}
    local expanded = Fusion.Value(props.expanded or false)

    local collapseHeight = 30

    local compchildren = {
        New "UIListLayout" {
            Name = "UIListLayout1",
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        },
    }

    for name, data in pairs(componentDumps) do
        -- print("component: " .. name)
        table.insert(compchildren, ComponentDump({
            componentName = name,
            componentData = data,
            expanded = false,
        }))
    end

    local headerchildren = {
        New "TextButton" {
            Name = "IdLabel",
            Font = Enum.Font.Gotham,
            Text = tostring(entityId),
            TextColor3 = Fusion.Computed(function()
                return expanded:get() and Color3.fromRGB(0, 179, 255) or Color3.fromRGB(255, 255, 255)
            end),
            TextSize = 14,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 20, 1, 0),
            [Fusion.OnEvent("MouseButton1Click")] = function()
                expanded:set(not expanded:get())
                -- print("expanded: " .. tostring(expanded:get()))
            end,
        },

        New "UIListLayout" {
            Name = "UIListLayout",
            Padding = UDim.new(0, 5),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
        },
    }
    
    for i,v in ipairs(headerTags) do
        table.insert(headerchildren,
            New "TextLabel" {
                Name = "CompLabel",
                Font = Enum.Font.GothamMedium,
                Text = tostring(v),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                BackgroundColor3 = uiUtil.nameToDebugColor(tostring(v)),
                Size = UDim2.new(0, TextService:GetTextSize(
                    tostring(v),
                    12,
                    Enum.Font.GothamMedium,
                    Vector2.new(math.huge, math.huge)
                ).X + 4, 1, 0),

                [Children] = {
                    New "UICorner" {
                        Name = "UICorner1",
                        CornerRadius = UDim.new(0, 4),
                    },
                }
            }
        )
    end


    return New "Frame" {
        Name = "Entity",
        BackgroundColor3 = Color3.fromRGB(39, 39, 39),
        ClipsDescendants = true,
        AutomaticSize = Fusion.Computed(function()
            return expanded:get() and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
        end),
        Size = Fusion.Computed(function()
            return UDim2.new(1, 0, 0, expanded:get() and 0 or collapseHeight)
        end),
        LayoutOrder = entityId,
    
        [Children] = {
            New "Frame" {
                Name = "Header",
                BackgroundColor3 = Color3.fromRGB(39, 39, 39),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 20),
    
                [Children] = headerchildren,
            },
    
            New "UICorner" {
                Name = "UICorner3",
                CornerRadius = UDim.new(0, 4),
            },
    
            New "UIPadding" {
                Name = "UIPadding",
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
            },
    
            New "Frame" {
                Name = "Components",
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Visible = Fusion.Computed(function() return expanded:get() end),
    
                [Children] = compchildren
            },
    
            New "UIListLayout" {
                Name = "UIListLayout2",
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
        }
    }
end