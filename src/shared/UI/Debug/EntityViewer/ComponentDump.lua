local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Children = Fusion.Children

local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

return function(props)

    local componentColor = uiUtil.nameToDebugColor(props.componentName)

    local expanded = Fusion.Value(props.expanded)

    local fieldUiChildren = Fusion.Computed(function()

        local childrenTab = {
            New "UICorner" {
                Name = "UICorner",
                CornerRadius = UDim.new(0, 4),
            },

            New "UIGradient" {
                Name = "UIGradient",
                Color = ColorSequence.new(componentColor),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.0172, 0.756),
                    NumberSequenceKeypoint.new(0.0253, 0.863),
                    NumberSequenceKeypoint.new(0.0448, 0.925),
                    NumberSequenceKeypoint.new(0.0999, 0.95),
                    NumberSequenceKeypoint.new(0.2, 0.956),
                    NumberSequenceKeypoint.new(0.563, 1),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            },

            New "UIListLayout" {
                Name = "UIListLayout",
                SortOrder = Enum.SortOrder.LayoutOrder,
            },

            New "UIPadding" {
                Name = "UIPadding",
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
            },

            New "TextButton" {
                Name = "NameLabel",
                Font = Enum.Font.GothamBold,
                Text = props.componentName,
                TextColor3 = expanded:get() and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(161, 161, 161),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 20),
                [Fusion.OnEvent("MouseButton1Click")] = function()
                    expanded:set(not expanded:get())
                end,
                Active = true,
                ZIndex = 2,
            },
        }
        
        if props.componentData and expanded:get() then
            for k, val in pairs(props.componentData) do
                local keyStr = tostring(k)
                
                local valStr = ""
                if typeof(val) == "Instance" then
                    valStr = string.format("%s, a %s", val:GetFullName(), val.ClassName)
                else
                    if typeof(val) == "table" then
                        for i, v in pairs(val) do
                            valStr = valStr .. string.format("\n    %s:\t\t\t%s", tostring(i), tostring(v))
                        end
                    else
                        valStr = tostring(val)
                    end
                end
                -- local keyStr = "<b>"..tostring(k).."</b>"
                
                -- local valStr = ""
                -- if typeof(v) == "Instance" then
                --     valStr = string.format("%s, <i>a %s</i>", v:GetFullName(), v.ClassName)
                -- else
                --     if typeof(v) == "table" then
                --         for i,v in pairs(v) do
                --             valStr = valStr .. string.format("\n    <i>%s</i>:\t\t\t%s", tostring(i), tostring(v))
                --         end
                --     else
                --         valStr = tostring(v)
                --     end
                -- end

                local fieldText = string.format("%s: %s", keyStr, valStr)
                local bounds = Vector2.new(
                    props.frameSizeX or 100,
                    math.huge
                )
                local textBounds = TextService:GetTextSize(fieldText, 12, Enum.Font.Gotham, bounds)
                table.insert(childrenTab,
                    New "TextLabel" {
                        Name = "FieldLabel",
                        Font = Enum.Font.Gotham,
                        TextColor3 = Color3.fromRGB(222, 222, 222),
                        Text = fieldText,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        RichText = true,
                        Size = UDim2.new(1, 0, 0, textBounds.Y + 5),
                    }
                )

                print(fieldText)
            end
        end

        return childrenTab
    end)


    return New "Frame" {
        Name = props.componentName,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = componentColor,
        Size = UDim2.new(1, 0, 0, 20),

        -- [Children] = fieldUiChildren:get(),
        [Children] = fieldUiChildren,
    }
end