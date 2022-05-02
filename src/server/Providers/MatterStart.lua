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
local ragdollUtil = require(ReplicatedStorage.Util.ragdollUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

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
        print("HHH:", count, replicated)
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
            return false
        end
    end)

    Remotes.Server:OnFunction("RequestGrab", function(player, instance, grabLocalPos)
        local grabberId = matterUtil.getCharacterIdOfPlayer(player, world)
        local grabberC = world:get(grabberId, Components.Grabber)

        if instance then
            -- print("Server grabbing.")
            local grabbableId = grabUtil.getGrabbableEntity(instance, world)

            if not grabberId then warn("no grabberId") return false end
            if not grabberC then warn("no grabberC") return false end
            if not grabbableId then warn("no grabbableId") return false end

            -- validity check
            if true then
                world:insert(grabberId, grabberC:patch({
                    grabbableId = grabbableId,
                    preferLocalPosition = grabLocalPos,
                }))
                -- print("Changed serverside to equip id ", world:get(equipperId, Components.Equipper).equippableId)
                return true
            else
                -- print("Reject change")
                -- world:insert(equipperId, equipperC:patch({
                --     equippableId = nil,
                -- }))
                -- it'll revert clientside, no need to do anything serverside
                return false
            end
        else
            -- let go
            -- print("Server let go.")
            world:insert(grabberId, grabberC:patch({
                grabbableId = Matter.None,
                preferLocalPosition = Matter.None,
            }))
            return true
        end
    end)
end

return MatterStart