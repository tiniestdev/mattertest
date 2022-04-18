local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.components)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)

local Remotes = require(ReplicatedStorage.Remotes)
local Net = require(ReplicatedStorage.Packages.Net)

local Intercom = require(ReplicatedStorage.Intercom)

local Archetypes = require(ReplicatedStorage.Archetypes)

local MatterClient = {}

MatterClient.AxisName = "MatterClientAxis"
MatterClient.World = Matter.World.new()
MatterClient.ServerToClientIds = {}
MatterClient.OurPlayerEntityId = nil
local world = MatterClient.World

function MatterClient:AxisPrepare()
    -- print("MatterClient: Axis prepare")
    MatterClient.MainLoop = Matter.Loop.new(MatterClient.World)
end

function MatterClient:AxisStarted()

    -- print("MatterClient: Axis started")

    -- print("MatterClient: Starting systems...")
    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

    -- print("MatterClient: Scheduling systems")
    MatterClient.MainLoop:scheduleSystems(systems)
    MatterClient.MainLoop:begin({ default = RunService.Stepped})

    -- print("MatterClient: Binding components from tags")
    MatterUtil.bindCollectionService(MatterClient.World)

    -- make a fake dud player entity until we get real data
    local localPlayerId = PlayerUtil.makePlayerEntity(Players.LocalPlayer, world)
    MatterClient.OurPlayerEntityId = localPlayerId
    replicationUtil.setRecipientIdScopeIdentifier(localPlayerId, Players.LocalPlayer.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER)
    world:insert(localPlayerId, Components.Ours({}))
    
    Remotes.Client:WaitFor("ReplicateArchetype"):andThen(function(remoteInstance)
        remoteInstance:Connect(function(archetypeName, payload)
            -- print("GOT REPLICATION FOR ", archetypeName, payload)
            local entityId = replicationUtil.deserializeArchetype(archetypeName, payload, world)
            if payload.scope == Players.LocalPlayer.UserId then
                world:insert(entityId, Components.Ours({}))
            end
        end)
    end)

    UserInputService.InputBegan:Connect(function(inputObject)
        if inputObject.KeyCode == Enum.KeyCode.X then
            local characterId = localUtil.getMyCharacterEntityId(world)
            if not characterId then return end
            local ragdollC = world:get(characterId, Components.Ragdollable)
            world:insert(characterId, ragdollC:patch({
                sleeping = not ragdollC.sleeping,
                doNotReconcile = false,
            }))
        end
    end)
    Intercom.Get("ProposeRagdollState"):Connect(function(ragdollState)
        -- print("Proposing ragdoll state", ragdollState)
        Remotes.Client:Get("ProposeRagdollState"):CallServerAsync(ragdollState):andThen(function(response)
            if response == true then
                -- print("Ragdoll state change succeeded")
            else
            end
        end)
    end)

    Intercom.Get("EquipEquippable"):Connect(function(equippableId)
        local myCharacterId = world:get(localPlayerId, Components.Player).characterId
        if myCharacterId then
            local equipperC = world:get(myCharacterId, Components.Equipper)
            local oldEquippableId = equipperC.equippableId
            if equipperC then
                world:insert(myCharacterId, equipperC:patch({
                    equippableId = equippableId,
                }))

                local replicatedC = world:get(equippableId, Components.Replicated)
                if replicatedC and replicatedC.serverId then
                    -- Remotes.Client:Get("RequestEquipEquippable"):SendToServer(replicatedC.serverId)
                    Remotes.Client:Get("RequestEquipEquippable"):CallServerAsync(replicatedC.serverId):andThen(function(response)
                        if response == true then
                            -- print("Equip succeeded")
                        else
                            warn("!! Equip failed !!")
                            warn("Tried to equip " .. tostring(equippableId) .. " but server said " .. tostring(response))
                            world:insert(myCharacterId, equipperC:patch({
                                equippableId = oldEquippableId,
                            }))
                        end
                    end)
                else
                    warn("Equippable not replicated properly: Replicated component is ", replicatedC)
                end
            else
                warn("MatterClient: Equipper component not found for character", myCharacterId)
            end
        end
        -- print("Applied equippabel change to character", myCharacterId, "with equippable", equippableId)
    end)
end

return MatterClient
