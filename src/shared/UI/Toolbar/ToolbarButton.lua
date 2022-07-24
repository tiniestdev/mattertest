local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Value = Fusion.Value

local randUtil = require(ReplicatedStorage.Util.randUtil)
local Intercom = require(ReplicatedStorage.Intercom)

return function(props)
    return New "TextButton" {
        Name = "Button",
        Font = Enum.Font.GothamSemibold,
        TextColor3 = Fusion.Computed(function()
            local equippedValue = Intercom.GetFusionValue("EquippedId")
            -- print("COMPUTED BUTTON. EQUIPPED: ", equippedValue:get())
            if equippedValue:get() == props.storableId then
                return Color3.fromRGB(0, 125, 192)
            else
                return Color3.fromRGB(255, 255, 255)
            end
        end),
        TextScaled = true,
        TextSize = 14,
        TextWrapped = true,
        Text = props.storableName,
        LayoutOrder = props.order,
        BackgroundColor3 = Fusion.Computed(function()
            local equippedValue = Intercom.GetFusionValue("EquippedId")
            -- print("COMPUTED BUTTON. EQUIPPED: ", equippedValue:get())
            if equippedValue:get() == props.storableId then
                return Color3.fromRGB(224, 244, 255)
            else
                return Color3.fromRGB(56, 56, 56)
                -- return randUtil.color()
            end
        end),
        Size = UDim2.new(1, 0, 1, 0),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        -- [Fusion.OnEvent("InputBegan")] = function(input)
            -- print("input state:", input)
        -- end,
        [Fusion.OnEvent("MouseButton1Click")] = function()
            -- print("CLICKED")
            -- print("Gonna equip ",props.storableId)
            Intercom.Get("EquipEquippable"):Fire(props.storableId)
        end,
        [Fusion.Children] = {
            New "UICorner" {
                Name = "UICorner",
            },
            New "UITextSizeConstraint" {
                Name = "UITextSizeConstraint",
                MaxTextSize = 20,
            },
        }
    }
end