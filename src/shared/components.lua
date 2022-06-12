local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.Packages.matter)
local ComponentInfo = require(ReplicatedStorage.ComponentInfo)

local components = {}

if RunService:IsServer() then
	for name, info in pairs(ComponentInfo.Catalog) do
		if not info.CLIENTCOMPONENT then
			components[name] = Matter.component(name)
		end
	end
else
	for name, info in pairs(ComponentInfo.Catalog) do
		if not info.SERVERCOMPONENT then
			components[name] = Matter.component(name)
			-- print("Registered ", name, " : ", components[name])
		end
	end
end

return components

