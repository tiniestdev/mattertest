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

local Grab = {}

Grab.AxisName = "GrabAxis"
local MatterClient = require(script.Parent.MatterClient)

function Grab:AxisPrepare()
    -- print("Grab: Axis prepare")
end

function Grab:AxisStarted()
    -- print("Grab: Axis started")
    local world = MatterClient.World
    
    UserInputService.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            if inputObject.UserInputState == Enum.UserInputState.Begin then
                -- release ANYTHING
                -- TODO
                -- do we have anything equipped?
                local characterId = localUtil.getMyCharacterEntityId(world)
                local equipperC = world:get(characterId, Components.Equipper)
                local skeletonC = world:get(characterId, Components.Skeleton)

                -- already holding something?
                if equipperC.equippableId then return end
                
                -- is there anything grabbable under cursor
                local mouse = Players.LocalPlayer:GetMouse()
                local mousePosition = mouse.Hit.Position
                local char = Players.LocalPlayer.Character
                local head = char:FindFirstChild("Head")
                if not head then error("wtf") end

                local grabRayParams = RaycastParams.new()
                grabRayParams.FilterDescendantsInstances = {char, skeletonC.skeletonInstance}
                grabRayParams.FilterType = Enum.RaycastFilterType.Blacklist

                local raycastResult = workspace:Raycast(head.Position, (mousePosition-head.Position).Unit * 20, grabRayParams)
                if raycastResult and raycastResult.Instance:IsA("BasePart") then
                    -- see if raycastResult is grabbable
                    local grabbableInstance = raycastResult.Instance
                    local grabbableId = grabUtil.getGrabbableEntity(grabbableInstance, world)
                    if not grabbableId then return end
                    local grabberC = localUtil.getCharComponent("Grabber", world);
                    if not grabberC then error("WTFF") return end
                    local preferLocalPosition = grabbableInstance.CFrame:PointToObjectSpace(raycastResult.Position)

                    print("Grab: GRABBED")
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
            print(characterId)
            local grabberC = world:get(characterId, Components.Grabber)
            world:insert(characterId, grabberC:patch({
                grabbableId = Matter.None,
            }))

            -- release.
            print("Grab: GRAB RELEASE!!!!!")
            Remotes.Client:Get("RequestGrab"):CallServerAsync(nil):andThen(function(response) end)
        end
    end)
end

return Grab


