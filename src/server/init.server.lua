local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Axis = require(ReplicatedStorage.Packages.axis)
for _, providerModule in ipairs(script.Providers:GetDescendants()) do
    if providerModule:IsA("ModuleScript") then
        Axis:AddProvider(require(providerModule))
    end
end
Axis:Start()