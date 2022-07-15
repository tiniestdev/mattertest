local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Matter = require(ReplicatedStorage.Packages.matter)
local Plasma = require(ReplicatedStorage.Packages.plasma)
local Components = require(ReplicatedStorage.components)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local timeUtil = require(ReplicatedStorage.Util.timeUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

local Remotes = require(ReplicatedStorage.Remotes)
local Net = require(ReplicatedStorage.Packages.Net)
local Rx = require(ReplicatedStorage.Packages.rx)

local Intercom = require(ReplicatedStorage.Intercom)

local Archetypes = require(ReplicatedStorage.Archetypes)

local MatterClient = {}

MatterClient.AxisName = "MatterClientAxis"
MatterClient.World = Matter.World.new()
MatterClient.ServerToClientIds = {}
MatterClient.OurPlayerEntityId = nil
MatterClient.Debugger = Matter.Debugger.new(Plasma)
local debugger = MatterClient.Debugger
local widgets = debugger:getWidgets()
local world = MatterClient.World
local debugState = {}

function MatterClient:AxisPrepare()
    MatterClient.MainLoop = Matter.Loop.new(world, debugState, widgets)

    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

    debugger:autoInitialize(MatterClient.MainLoop)
    MatterClient.MainLoop:scheduleSystems(systems)
    MatterClient.MainLoop:begin({ default = RunService.Stepped})

    task.wait(0.1)
end

function MatterClient:AxisStarted()
    -- make a fake dud player entity until we get real data
    local localPlayerId = PlayerUtil.makePlayerEntity(Players.LocalPlayer, world)
    MatterClient.OurPlayerEntityId = localPlayerId
    replicationUtil.setRecipientIdScopeIdentifier(localPlayerId, Players.LocalPlayer.UserId, replicationUtil.CLIENTIDENTIFIERS.PLAYER)
    world:insert(localPlayerId, Components.Ours({}))

    -- ensure that we know to despawn entities first
    Remotes.Client:WaitFor("DespawnedEntities"):andThen(function(remoteInstance)
        remoteInstance:Connect(function(list)
            Rx.from(list):Pipe({
                Rx.map(function(entityId)
                    local recipientId = replicationUtil.senderIdToRecipientId(entityId)
                    if not recipientId then
                        Intercom.DespawnMap[entityId] = true
                        return nil
                    end
                    return recipientId
                end),
            }):Subscribe(function(recipientId)
                if recipientId then
                    world:despawn(recipientId)
                end
            end)
        end)
    end)

    -- request replicatable entities
    Remotes.Client:Get("RequestReplicatedEntites"):CallServerAsync():andThen(function(response)
        local count = response.count
        local listOfServerIds = response.listOfServerIds

        if count ~= #listOfServerIds then
            error("Requested " .. #listOfServerIds .. " entities, but got " .. count .. " back")
        end
        local notReplicatedYet = {}
        for i, serverId in ipairs(listOfServerIds) do
            local foundClientId = replicationUtil.senderIdToRecipientId(serverId)
            local entityFound = world:contains(foundClientId)
            if not entityFound then
                table.insert(notReplicatedYet, serverId)
            end
        end

        if #notReplicatedYet > 0 then
            Remotes.Client:Get("RequestReplicateEntities"):SendToServer(notReplicatedYet)
            -- print("Asking server for more", notReplicatedYet)
        end
    end)

    Remotes.Client:WaitFor("ReplicateArchetype"):andThen(function(remoteInstance)
        remoteInstance:Connect(function(archetypeName, payload)

            -- inside this deserialize method, we should make sure we don't create a new one if its a playerarchetype
            -- that points to our player
            -- we gotta map it to our local player id
            -- MatterClient.OurPlayerEntityId = localPlayerId
            local entityId = replicationUtil.deserializeArchetype(archetypeName, payload, world)
            if archetypeName == "PlayerArchetype" then
                
            else
                if payload.scope == Players.LocalPlayer.UserId then
                    world:insert(entityId, Components.Ours({}))
                end
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
        -- cooldown
        print("!")
        if not timeUtil.getDebounce("equipDebounce", 0.4) then return end
        print("Equipping equippable", equippableId)

        -- make sure we're actually an equipper
        local myCharacterId = localUtil.getMyCharacterEntityId(world)
        if not myCharacterId then warn("wtf no characterid entity??") end
        local equipperC = world:get(myCharacterId, Components.Equipper)
        local oldEquippableId = equipperC.equippableId
        if not equipperC then warn("wtf no equipper on entity ", myCharacterId, "?") end
        local replicatedC = world:get(equippableId, Components.Replicated)
        if not replicatedC then warn("wtf no replicated on entity ", equippableId, "?") end
        if not replicatedC.serverId then warn("wtf no serverId on replicated component on entity ", equippableId, "?") end

        -- okay actual equip logic starts here
        if equipperC.equippableId == equippableId then
            -- unequip it
            world:insert(myCharacterId, equipperC:patch({
                equippableId = Matter.None,
            }))
            Remotes.Client:Get("RequestEquipEquippable"):CallServerAsync(nil):andThen(function(response)
                print("RequestEquipEquippable response", response)
                if response == true then
                    print("Equip succeeded")
                else
                    warn("!! Unequip failed !!")
                    warn("Tried to unequip " .. tostring(equippableId) .. " but server said " .. tostring(response))
                    world:insert(myCharacterId, equipperC:patch({
                        equippableId = oldEquippableId,
                    }))
                end
            end)
        else
            world:insert(myCharacterId, equipperC:patch({
                equippableId = equippableId,
            }))
            Remotes.Client:Get("RequestEquipEquippable"):CallServerAsync(replicatedC.serverId):andThen(function(response)
                print("response: ", response)
                if response == true then
                    print("Equip succeeded")
                else
                    warn("!! Equip failed !!")
                    warn("Tried to equip " .. tostring(equippableId) .. " but server said " .. tostring(response))
                    world:insert(myCharacterId, equipperC:patch({
                        equippableId = oldEquippableId or Matter.None,
                    }))
                end
            end)
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F4 then
            print("TOGGLING DEBUGGER")
            debugger:toggle()
        end
    end)
end

return MatterClient
