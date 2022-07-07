local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

return function(world)
    -- a queue inside a component of forces that must be applied to an instance?
    -- or just a simple event or some thing idk idk idk
    -- Do an intercom event for serverwide bullet collisions
    -- and also do a remote event to every client
end