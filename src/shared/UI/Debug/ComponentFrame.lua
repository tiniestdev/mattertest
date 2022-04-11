local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Remotes)
local Fusion = require(ReplicatedStorage.Fusion)
local Llama = require(ReplicatedStorage.Packages.llama)
local New = Fusion.New

local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

return function(componentData)

	local fieldChildren = Fusion.Computed(function()
		table.sort(componentData.fields, function(a, b)
			return a.key < b.key
		end)
		return Fusion.ForValues(componentData.fields, function(fieldData)
            return New "TextLabel" {
                Name = "Field",
                Font = Enum.Font.SourceSans,
                Text = tostring(fieldData.key) .. " : " .. tostring(fieldData.value),
                TextColor3 = Color3.fromRGB(209, 209, 209),
                TextSize = 14,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 15),
            }
		end)
	end)

    return New "Frame" {
        Name = "ComponentFrame",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(47, 47, 47),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),

		[Fusion.Children] = Llama.List.append({
            New "TextLabel" {
                Name = "ComponentTitle",
                Font = Enum.Font.GothamBlack,
                Text = string.upper(componentData.componentName),
                TextColor3 = Color3.fromRGB(255, 183, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 14),
            },

            New "UIPadding" {
                Name = "UIPadding",
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
            },

            New "UIListLayout" {
                Name = "UIListLayout",
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
        }, fieldChildren)
    }
end
