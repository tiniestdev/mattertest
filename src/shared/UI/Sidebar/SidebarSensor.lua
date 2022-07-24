local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New

return function(props)
	return New "Frame" {
		Name = "SidebarSensor",
		BackgroundColor3 = Color3.fromRGB(255, 61, 61),
        BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromScale(0, 0),

		[Fusion.Children] = {
			New("UISizeConstraint")({
				Name = "UISizeConstraint",
				MaxSize = Vector2.new(150, math.huge),
				MinSize = Vector2.new(50, 0),
			}),
		},
		
        [Fusion.OnEvent "MouseEnter"] = function()
            props.openState:set(true)
        end,
        [Fusion.OnEvent "MouseLeave"] = function()
            props.openState:set(false)
        end,
	}
end
