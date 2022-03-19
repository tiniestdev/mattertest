local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Axis = require(ReplicatedStorage.Packages.axis)
for _, providerModule in ipairs(script.Providers:GetChildren()) do
    Axis:AddProvider(require(providerModule))
end
Axis:Start()
