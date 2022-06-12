local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Fusion)

-- local Main = require(script.Parent.Main)
-- local ClearFrame = require(script.Parent.ClearFrame)

-- return function(target)
--     local mounted = ClearFrame {
--         Parent = target;
--         [Fusion.Children] = {
--             Main {},
--         }
--     }
--     return function()
--         mounted:Destroy()
--     end
-- end

return function(target)

    local mounted = Fusion.New("Frame") {
        Name = "testframe";
        Size = UDim2.new(1,0,1,0);
        BackgroundTransparency = 0;
        BackgroundColor3 = Color3.new(0.074509, 0.074509, 0.074509);
        BorderSizePixel = 0;
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 0);
        Parent = target;
        [Fusion.Children] = {
            -- Main {},
        }
    }

    return function()
        mounted:Destroy()
    end
end

