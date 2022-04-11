local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Constants)

local PhysicsStart = {}

PhysicsStart.AxisName = "PhysicsStartAxis"

function PhysicsStart:AxisPrepare()
    for key, name in pairs(Constants.CollisionNames) do
        if key ~= "DEFAULT" then
            PhysicsService:CreateCollisionGroup(name)
        end
    end
    for key, relations in pairs(Constants.CollisionRelations) do
        for otherKey, value in pairs(relations) do
            PhysicsService:CollisionGroupSetCollidable(Constants.CollisionNames[key], Constants.CollisionNames[otherKey], value)
        end
    end
end

function PhysicsStart:AxisStarted()
end

return PhysicsStart
