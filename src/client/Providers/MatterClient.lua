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
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local timeUtil = require(ReplicatedStorage.Util.timeUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

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
    MatterClient.MainLoop = Matter.Loop.new(MatterClient.World)
    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

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

    -- request replicatable entities
    Remotes.Client:Get("RequestReplicatedEntites"):CallServerAsync():andThen(function(response)
        print("HHH2:", response.count, response.listOfServerIds)
        local count = response.count
        local listOfServerIds = response.listOfServerIds

        if count ~= #listOfServerIds then
            error("Requested " .. #listOfServerIds .. " entities, but got " .. count .. " back")
        end
        local notReplicatedYet = {}
        for i, serverId in ipairs(listOfServerIds) do
            local foundClientId = replicationUtil.senderIdToRecipientId(serverId)
            local entity = world:get(foundClientId)
            if not entity then
                table.insert(notReplicatedYet, serverId)
            end
        end

        if #notReplicatedYet > 0 then
            Remotes.Client:Get("RequestReplicateEntities"):SendToServer(notReplicatedYet)
            print("Asking server for more")
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

        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            if inputObject.UserInputState == Enum.UserInputState.Begin then
                -- release ANYTHING
                -- TODO
                -- do we have anything equipped?
                local characterId = localUtil.getMyCharacterEntityId(world)
                local equipperC = world:get(characterId, Components.Equipper)

                -- already holding something?
                if equipperC.equippableId then return end
                
                -- is there anything grabbable under cursor
                local mouse = Players.LocalPlayer:GetMouse()
                local mousePosition = mouse.Hit.Position
                local char = Players.LocalPlayer.Character
                local head = char:FindFirstChild("Head")
                if not head then error("wtf") end

                local cameraPosition = workspace.CurrentCamera.CFrame.Position

                local grabRayParams = RaycastParams.new()
                grabRayParams.FilterDescendantsInstances = {char}
                grabRayParams.FilterType = Enum.RaycastFilterType.Blacklist
                local raycastResult = workspace:Raycast(head.Position, (mousePosition-head.Position).Unit * 20, params)
                if raycastResult and raycastResult.Instance:IsA("BasePart") then
                    -- see if raycastResult is grabbable
                    local grabbableInstance = raycastResult.Instance
                    local grabbableId = grabUtil.getGrabbableEntity(grabbableInstance, world)
                    if not grabbableId then return end
                    local grabberC = localUtil.getCharComponent("Grabber", world);
                    if not grabberC then error("WTFF") return end
                    local preferLocalPosition = grabbableInstance.CFrame:PointToObjectSpace(raycastResult.Position)

                    world:insert(characterId, grabberC:patch({
                        grabbableId = grabbableId,
                        preferLocalPosition = preferLocalPosition,
                    }))

                    Remotes.Client:Get("RequestGrab"):CallServerAsync(grabbableInstance, preferLocalPosition):andThen(function(response)
                        if response then
                            -- true
                        else
                            -- let go immediately
                            world:insert(characterId, grabberC:patch({
                                grabbableId = Matter.None,
                                preferLocalPosition = Matter.None,
                            }))
                        end
                    end)
                    -- maybe rewrite grabber system?
                    -- a grabber should probably be some attachment, and a grabbable should auto
                    -- generate an attachment when grabbed onto, like nearest point on geometry type stuff
                    -- then, the hands of the character could be grabbers instead of just the character??
                    -- or hold on since grabbing is supposed to be more like some telekensis stuff
                    -- like theres diff orientations and stuff idk idk idk
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            -- release ANYTHING
            -- TODO
            local characterId = localUtil.getMyCharacterEntityId(world)
            local grabberC = world:get(characterId, Components.Grabber)
            world:insert(characterId, grabberC:patch({
                grabbableId = Matter.None,
            }))
            Remotes.Client:Get("RequestGrab"):CallServerAsync(nil):andThen(function(response) end)
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
        if not timeUtil.getDebounce("equipDebounce", 0.4) then return end

        -- make sure we're actually an equipper
        local myCharacterId = world:get(localPlayerId, Components.Player).characterId
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
                if response == true then
                    -- print("Equip succeeded")
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
                -- print("response: ", response)
                if response == true then
                    -- print("Equip succeeded")
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
end

return MatterClient
