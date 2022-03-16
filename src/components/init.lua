local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.Packages.matter)

local COMPONENTS = {
	"Instance",
	"Flammable",
}

local components = {}

for _, name in ipairs(COMPONENTS) do
	components[name] = Matter.component(name)
	print("Made component of name ", name, ": ", components[name])
end

return components

