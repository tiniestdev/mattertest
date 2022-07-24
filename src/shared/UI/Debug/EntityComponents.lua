local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Llama = require(ReplicatedStorage.Packages.llama)

local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

local ComponentFrame = require(script.Parent.ComponentFrame)

return function(props)

    local entityId = props.entityId

	local clientComponentsUI = Fusion.Computed(function()
		table.sort(props.clientComponents, function(a, b)
			return a.componentName < b.componentName
		end)
		return Fusion.ForValues(props.clientComponents, function(componentData)
			return ComponentFrame(componentData)
		end)
	end)

	local serverComponentsUI = Fusion.Computed(function()
		table.sort(props.serverComponents, function(a, b)
			return a.componentName < b.componentName
		end)
		return Fusion.ForValues(props.serverComponents, function(componentData)
			return ComponentFrame(componentData)
		end)
	end)

    return New "Frame" {
        Name = "EntityComponents",
        Active = true,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.new(1, -20, 0.9, 0),
        Size = UDim2.new(0, 400, 0, 300),

        [Fusion.Children] = {
            New "ScrollingFrame" {
                Name = "ScrollingFrame",
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(),
                ScrollBarThickness = 4,
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = Color3.fromRGB(26, 26, 26),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Selectable = false,
                Size = UDim2.new(1, 0, 1, -20),

                [Fusion.Children] = {
                    New "Frame" {
                        Name = "Client",
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = Color3.fromRGB(0, 136, 255),
                        BackgroundTransparency = 0.65,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0.5, 0, 1, 0),

                        [Fusion.Children] = Llama.List.append({
                            New "UIListLayout" {
                                Name = "UIListLayout",
                                Padding = UDim.new(0, 5),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                            },

                            New "UIPadding" {
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0, 4),
                                PaddingLeft = UDim.new(0, 4),
                                PaddingRight = UDim.new(0, 5),
                                PaddingTop = UDim.new(0, 4),
                            },
                        }, clientComponentsUI)
                    },

                    New "Frame" {
                        Name = "Server",
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = Color3.fromRGB(68, 255, 0),
                        BackgroundTransparency = 0.65,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0.5, 0, 0, 0),
                        Size = UDim2.new(0.5, 0, 1, 0),

                        [Fusion.Children] = Llama.List.append({
                            New "UIListLayout" {
                                Name = "UIListLayout1",
                                Padding = UDim.new(0, 5),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                            },

                            New "UIPadding" {
                                Name = "UIPadding1",
                                PaddingBottom = UDim.new(0, 4),
                                PaddingLeft = UDim.new(0, 4),
                                PaddingRight = UDim.new(0, 5),
                                PaddingTop = UDim.new(0, 4),
                            },
                        }, serverComponentsUI)
                    },
                }
            },

            New "TextLabel" {
                Name = "Title",
                Font = Enum.Font.GothamBlack,
                Text = "ENTITY COMPONENTS",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 20),
            },
        }
    }
end