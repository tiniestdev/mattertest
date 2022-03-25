local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Remotes)
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Value = Fusion.Value

local Llama = require(ReplicatedStorage.Packages.llama)

local ToolbarButton = require(script.ToolbarButton)

return function(props)
	local storableChildren = Fusion.Computed(function()
		return Fusion.ForValues(props.storableProps, function(props)
			return ToolbarButton(props)
		end)
	end)

	return New "Frame" {
		Name = "Toolbar",
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(0, 255, 93),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.95, -10),
		Size = UDim2.new(1, 0, 0.1, 0),

		[Fusion.Children] = Llama.List.append({
			New "UISizeConstraint" {
				Name = "UISizeConstraint",
				MaxSize = Vector2.new(math.huge, 100),
				MinSize = Vector2.new(0, 50),
			},
			New "UIListLayout" {
				Name = "UIListLayout",
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}, storableChildren)
	}
end


