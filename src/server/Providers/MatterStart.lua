local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
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

    Remotes.Server:OnEvent("ClientToServer", function(player, msg)
        print("SERVER recieved a message from player", player, msg)
    end)
    task.spawn(function()
        task.wait(3)
        print("STARTING SOME TESTS=======")
        task.wait(1)
        Remotes.Server:Create("ServerToClient"):SendToAllPlayers("servermessasge")
        print("Fired event")
    end)
end

return MatterStart