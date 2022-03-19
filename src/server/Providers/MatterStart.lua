local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.components)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterStart = {}

MatterStart.AxisName = "MatterStartAxis"
MatterStart.World = Matter.World.new()
local world = MatterStart.World

function MatterStart:AxisPrepare()
    print("MatterStart: Axis prepare")
    MatterStart.MainLoop = Matter.Loop.new(world)
    print("MatterStart: Made Matter World + Loop")
end

function MatterStart:AxisStarted()
    print("MatterStart: Axis started")

    print("MatterStart: Starting systems...")
    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

    print("MatterStart: Scheduling systems")
    MatterStart.MainLoop:scheduleSystems(systems)
    MatterStart.MainLoop:begin({ default = RunService.Heartbeat })

    print("MatterStart: Binding components from tags")
    MatterUtil.bindCollectionService(world)

    PlayerUtil.getCharactersObservable():Subscribe(function(character)
        print("MatterStart: Character added: ", character)
        CollectionService:AddTag(character, "Character")
    end)
end

return MatterStart