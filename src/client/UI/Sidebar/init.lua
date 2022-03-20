local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Remotes)
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Value = Fusion.Value

local Menu = require(script.Menu)
local SidebarSensor = require(script.SidebarSensor)

return function(props)
    local hoveringOverSidebar = Value(false)
	return New "Frame" {
		Name = "Sidebar",
		BackgroundColor3 = Color3.fromRGB(0, 4, 255),
        BackgroundTransparency = 1,
		Size = UDim2.new(.2, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromScale(0, 0),

		[Fusion.Children] = {
			New("UISizeConstraint")({
				Name = "UISizeConstraint",
				MaxSize = Vector2.new(150, math.huge),
				MinSize = Vector2.new(50, 0),
			}),
            Menu {
                openState = hoveringOverSidebar,
                SidebarButtons = props.SidebarButtons,
            },
            SidebarSensor {
                openState = hoveringOverSidebar,
            },
		},
	}
end

