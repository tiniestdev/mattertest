local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)

local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterStart = {}

MatterStart.AxisName = "MatterStartAxis"
MatterStart.World = Matter.World.new()
local world = MatterStart.World

local RDM = Random.new()

function MatterStart:AxisPrepare()
    -- print("MatterStart: Axis prepare")
    MatterStart.MainLoop = Matter.Loop.new(world)
    -- print("MatterStart: Made Matter World + Loop")
    -- print("MatterStart: Starting systems...")
    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

    -- print("MatterStart: Scheduling systems")
    MatterStart.MainLoop:scheduleSystems(systems)
    MatterStart.MainLoop:begin({ default = RunService.Heartbeat })

    -- print("MatterStart: Binding components from tags")
    matterUtil.bindCollectionService(world)
end

function MatterStart:AxisStarted()
    -- print("MatterStart: Axis started")

    Remotes.Server:OnFunction("RequestReplicateArchetype", function(player, request)
        local response = {}
        for _, entityInfo in ipairs(request) do
            -- print("Got request to replicate entity ", entityInfo.serverId, entityInfo)
            local serverId = tonumber(entityInfo.serverId)
            local missingArchetypes = entityInfo.missingArchetypes

            local totalComponentSet = {}
            for _, archetypeName in ipairs(missingArchetypes) do
                replicationUtil.replicateServerEntityArchetypeTo(player, serverId, archetypeName, world)
            end
        end
        return true
    end)
    Remotes.Server:OnFunction("RequestEquipEquippable", function(player, equipId)
        -- print("REQUESTING EQUIP ID ", equipId, " FOR ", player.Name)
        local equipperId = matterUtil.getCharacterIdOfPlayer(player, world)
        local equipperC = world:get(equipperId, Components.Equipper)

        -- validity check
        if true then
            world:insert(equipperId, equipperC:patch({
                equippableId = equipId,
            }))
            -- print("Changed serverside to equip id ", world:get(equipperId, Components.Equipper).equippableId)
            return true
        else
            -- print("Reject change")
            world:insert(equipperId, equipperC:patch({
                equippableId = nil,
            }))
            return false
        end
    end)
    -- Remotes.Server:OnEvent("ClientToServer", function(player, msg)
    --     print("SERVER recieved a message from player", player, msg)
    -- end)
    -- task.spawn(function()
    --     task.wait(3)
    --     print("STARTING SOME TESTS=======")
    --     for i=1,3 do
    --         task.wait(1)
    --         Remotes.Server:Create("ServerToClient"):SendToAllPlayers("servermessasge")
    --         print("Fired event")
    --     end
    -- end)
end

return MatterStart