local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.components)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local Net = require(ReplicatedStorage.Packages.Net)

local MatterClient = {}

MatterClient.AxisName = "MatterClientAxis"
MatterClient.World = Matter.World.new()
MatterClient.ServerToClientIds = {}
local world = MatterClient.World

function MatterClient:AxisPrepare()
    print("MatterClient: Axis prepare")
    MatterClient.MainLoop = Matter.Loop.new(MatterClient.World)
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

    -- make a fake dud player entity until we get real data
    local localPlayerId = PlayerUtil.makePlayerEntity(Players.LocalPlayer, world)
    replicationUtil.setRecipientIdScopeIdentifier(localPlayerId, Players.LocalPlayer.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER)
    Remotes.Client:WaitFor("ReplicatePlayerEntity"):andThen(function(remoteInstance)
        remoteInstance:Connect(function(payload)
            local playerId = replicationUtil.deserializeArchetype("Player", payload, world)
        end)
    end)
end

return MatterClient
