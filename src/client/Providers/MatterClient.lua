local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.components)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)

local MatterClient = {}

MatterClient.AxisName = "MatterClientAxis"
MatterClient.World = Matter.World.new()

function MatterClient:AxisPrepare()
    print("MatterClient: Axis prepare")
    MatterClient.MainLoop = Matter.Loop.new(MatterClient.World)
    print("MatterClient: Made Matter World + Loop")
end

function MatterClient:AxisStarted()
    print("MatterClient: Axis started")

    print("MatterClient: Starting systems...")
    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

    print("MatterClient: Scheduling systems")
    MatterClient.MainLoop:scheduleSystems(systems)
    MatterClient.MainLoop:begin({ default = RunService.Stepped})

    print("MatterClient: Binding components from tags")
    MatterUtil.bindCollectionService(MatterClient.World)
end

return MatterClient
