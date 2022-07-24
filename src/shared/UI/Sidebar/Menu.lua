local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

local SidebarButton = require(script.Parent.SidebarButton)

return function(props)
    local goalXO = Computed(function()
        return (props.openState:get() and 5) or -5
    end)
    local goalXAS = Computed(function()
        return (props.openState:get() and 0) or 1
    end)
    
    local speed = 50
    local springXO = Spring(goalXO, speed)
    local springXAS = Spring(goalXAS, speed)

	return New "Frame" {
		Name = "SidebarSensor",
		BackgroundColor3 = Color3.fromRGB(9, 255, 0),
        BackgroundTransparency = 1,
		Size = UDim2.new(.7, 0, 1, 0),
        AnchorPoint = Computed(function()
            return Vector2.new(springXAS:get(), 0)
        end),
        Position = Computed(function()
            return UDim2.new(0, springXO:get(),0,0)
        end),

		[Fusion.Children] = {
			New("UISizeConstraint")({
				Name = "UISizeConstraint",
				MaxSize = Vector2.new(150, math.huge),
				MinSize = Vector2.new(50, 0),
			}),

			New("UIGridLayout")({
				Name = "UIGridLayout",
				CellSize = UDim2.new(1, 0, 0, 50),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

            [Fusion.Children] = Fusion.ForValues(props.SidebarButtons, function(info)
                return SidebarButton(info)
            end),
		},
	}
end
