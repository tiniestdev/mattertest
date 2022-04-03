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

--[[
    clientId, serverId, adornee
]]

return function(props)
    return New "BillboardGui" {
        Name = "BillboardGui",
        Active = true,
        AlwaysOnTop = true,
        ClipsDescendants = true,
        Size = UDim2.new(4, 0, 1, 0),
        StudsOffsetWorldSpace = Vector3.new(0, 1, 0),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Adornee = props.adornee,
    
        [Fusion.Children] = {
            New "TextLabel" {
                Name = "ClientLabel",
                Font = Enum.Font.GothamBlack,
                Text = tostring(props.clientId),
                TextColor3 = Color3.fromRGB(0, 145, 255),
                TextScaled = true,
                TextSize = 14,
                TextStrokeTransparency = 0,
                TextWrapped = true,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0.5, 0, 1, 0),
            },
    
            New "TextLabel" {
                Name = "ServerLabel",
                Font = Enum.Font.GothamBlack,
                Text = tostring(props.serverId),
                TextColor3 = Color3.fromRGB(48, 221, 0),
                TextScaled = true,
                TextSize = 14,
                TextStrokeTransparency = 0,
                TextWrapped = true,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0.5, 0, 1, 0),
            },
    
            New "UIListLayout" {
                Name = "UIListLayout",
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
        }
    }
end