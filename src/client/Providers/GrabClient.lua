local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.promise)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)
local Components = require(ReplicatedStorage.components)
local Llama = require(ReplicatedStorage.Packages.llama)

local drawUtil = require(ReplicatedStorage.Util.drawUtil)

local Grab = {}

Grab.AxisName = "GrabAxis"
local MatterClient = require(script.Parent.MatterClient)

function Grab:AxisPrepare()
    -- print("Grab: Axis prepare")
end

local function attemptCastGrabRay(world)
    local characterId = localUtil.getMyCharacterEntityId(world)
    local equipperC = world:get(characterId, Components.Equipper)
    local skeletonC = world:get(characterId, Components.Skeleton)
    local grabberC = world:get(characterId, Components.Grabber)

    if not equipperC then return end
    if not skeletonC then return end
    if not grabberC then return end
   
    -- already holding something?
    if equipperC.equippableId then return end
    
    -- is there anything grabbable under cursor
    local grabRayParams = grabUtil.getGrabberOffsetCastParams(world, grabberC)

    local camPos = workspace.CurrentCamera.CFrame.Position
    local mouseRaycastHit = localUtil.castMouseRangedHitWithParams(
        grabRayParams,
        100,
        camPos
    )
    local grabberInstance = grabberC.grabberInstance
    local raycastResult = workspace:Raycast(grabberInstance.Position, (mouseRaycastHit-grabberInstance.Position).Unit * 10, grabRayParams)


    if raycastResult and raycastResult.Instance then
        -- see if raycastResult is grabbable
        local grabbableInstance = raycastResult.Instance
        local grabbableId = grabUtil.getGrabbableEntity(grabbableInstance, world)
        if not grabbableId then return nil end
        return raycastResult, grabbableId
    end

    return nil
end

function Grab:AxisStarted()
    local world = MatterClient.World
    
    UserInputService.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputState == Enum.UserInputState.Begin then
            local characterId = localUtil.getMyCharacterEntityId(world)
            local grabberC = world:get(characterId, Components.Grabber)

            local raycastResult, grabbableId = attemptCastGrabRay(world)
            if not raycastResult then return end

            local grabObjectCFrame = raycastResult.Instance.CFrame:toObjectSpace(CFrame.new(raycastResult.Position))

            local hit = localUtil.castMouseRangedHitWithParams(
                grabUtil.getGrabberOffsetCastParams(world, grabberC),
                grabUtil.MaxGrabDistance,
                grabberC.grabberInstance.Position
            )

            world:insert(characterId, grabberC:patch({
                grabbableId = grabbableId,
                grabbableInstance = raycastResult.Instance,
                grabOffsetCFrame = grabberC.grabberInstance.CFrame:toObjectSpace(CFrame.new(hit)),
                grabPointObjectCFrame = grabObjectCFrame,
            }), Components.ClientLocked({
                clientLocked = true,
                lockLinks = true,
            }))

            Remotes.Client:Get("RequestGrab"):CallServerAsync(raycastResult.Instance, grabObjectCFrame):andThen(function(response)
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
        end
    end)

    UserInputService.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            -- release ANYTHING
            -- TODO
            local characterId = localUtil.getMyCharacterEntityId(world)
            local grabberC = world:get(characterId, Components.Grabber)

            -- world:insert(characterId, grabberC:patch({
            --     grabbableId = Matter.None,
            -- }))
            -- world:insert(oldGrabbableId,
            --     grabbableC:patch({
            --         Llama.Set.subtract(grabbableC.grabberIds, characterId),
            --     })
            -- )
            world:insert(characterId, grabberC:patch({
                grabbableId = Matter.None,
            }))

            task.delay(0.5, function()
                if world:get(characterId, Components.Grabber).grabbableId == nil then
                    world:insert(characterId,
                        Components.ClientLocked({
                            clientLocked = false,
                            lockLinks = false,
                        })
                    )
                end
            end)

            -- release.
            Remotes.Client:Get("RequestGrab"):CallServerAsync(nil):andThen(function(response) end)
        end
    end)
end

return Grab


