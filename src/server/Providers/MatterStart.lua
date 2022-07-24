local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.matter)
local Plasma = require(ReplicatedStorage.Packages.plasma)
local Llama = require(ReplicatedStorage.Packages.llama)
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local ragdollUtil = require(ReplicatedStorage.Util.ragdollUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterStart = {}

MatterStart.AxisName = "MatterStartAxis"
MatterStart.World = Matter.World.new()
MatterStart.Debugger = Matter.Debugger.new(Plasma)
local debugger = MatterStart.Debugger
local widgets = debugger:getWidgets()
local world = MatterStart.World
local debugState = {}

local RDM = Random.new()

function MatterStart:AxisPrepare()
    -- print("MatterStart: Axis prepare")
    MatterStart.MainLoop = Matter.Loop.new(world, debugState, widgets)
    -- print("MatterStart: Made Matter World + Loop")
    -- print("MatterStart: Starting systems...")
    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

    debugger.authorize = function(plr)
        if RunService:IsStudio() then return true end
        return plr:GetRankInGroup(4575704) >= 253
    end

    -- print("MatterStart: Scheduling systems")
    debugger:autoInitialize(MatterStart.MainLoop)
    MatterStart.MainLoop:scheduleSystems(systems)
    MatterStart.MainLoop:begin({ default = RunService.Heartbeat })

    task.wait(1)
end

function MatterStart:AxisStarted()
    -- print("MatterStart: Axis started")

    Remotes.Server:OnFunction("RequestReplicatedEntites", function(player)
        local replicated = {}
        local count = 0;
        for id, v in world:query(Components.ReplicateToClient) do
            table.insert(replicated, id)
            count = count + 1
        end
        print("SENDING REQEUSTED ENTITIES:", count, replicated)
        return {count = count, listOfServerIds = replicated}
    end)

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

    Remotes.Server:OnFunction("ProposeRagdollState", function(player, ragdollState)
        local characterId = matterUtil.getCharacterIdOfPlayer(player, world)

        while not characterId do
            print("WAITING FOR CHARACTER ID")
            task.wait()
            characterId = matterUtil.getCharacterIdOfPlayer(player, world)
        end

        local ragdollableC = world:get(characterId, Components.Ragdollable)
        local healthC = world:get(characterId, Components.Health)

        local newDowned = ragdollableC.downed
        if ragdollState.downed ~= nil and ragdollUtil.shouldBeDowned(characterId, world) == ragdollState.downed then
        -- if false then
            newDowned = ragdollState.downed
        else
            print("Rejected ragdoll state proposal downed: ", ragdollState.downed, " shouldBeDowned: ", ragdollUtil.shouldBeDowned(characterId, world))
        end

        local newSleeping = ragdollableC.sleeping
        if ragdollState.sleeping ~= nil then
        -- if false then
            newSleeping = ragdollState.sleeping
        end

        -- ehhh worry about stuns later
        world:insert(characterId, ragdollableC:patch({
            downed = newDowned,
            sleeping = newSleeping,
        }))

        replicationUtil.replicateServerEntityArchetypeTo(player, characterId, "Ragdollable", world)

        return true
    end)

    --[[
    Remotes.Server:OnFunction("RequestEquipEquippable", function(player, equipId)
        local equipperId = matterUtil.getCharacterIdOfPlayer(player, world)
        local equipperC = world:get(equipperId, Components.Equipper)

        -- validity check
        if true then
            world:insert(equipperId, equipperC:patch({
                equippableId = equipId or Matter.None,
            }))
            return true
        else
            replicationUtil.replicateServerEntityArchetypeTo(player, equipId, "Equippable", world, true)
            replicationUtil.replicateServerEntityArchetypeTo(player, equipperId, "Character", world, true)
            return false
        end
    end)]]

    Remotes.Server:OnFunction("RequestEntitiesDump", function(player)
        return matterUtil.getEntityViewerData(world)
    end)
end

return MatterStart