local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local grabUtil = require(ReplicatedStorage.Util.grabUtil)

local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterStart = require(script.Parent.MatterStart)
local GrabStart = {}

GrabStart.AxisName = "GrabStartAxis"
local RDM = Random.new()

function GrabStart:AxisPrepare()
end

function GrabStart:AxisStarted()
    local world = MatterStart.World

    Remotes.Server:OnFunction("RequestGrab", function(player, instance, grabOffset, grabPoint)
        local grabberId = matterUtil.getCharacterIdOfPlayer(player, world)
        local grabberC = world:get(grabberId, Components.Grabber)

        if instance then
            local grabbableId = grabUtil.getGrabbableEntity(instance, world)

            if not grabberId then warn("no grabberId") return false end
            if not grabberC then warn("no grabberC") return false end
            if not grabbableId then warn("no grabbableId") return false end

            -- validity check
            if true then
                local rtcC = world:get(grabberId, Components.ReplicateToClient)
                -- grabberInstance = {}; -- Define a specific grab PART to use to calculate offset
                -- grabbableInstance = {}; -- Same
                -- grabOffsetCFrame = {}; -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
                -- grabPointObjectCFrame = {}; -- for players who click a specific point on the grabbable part to manipulate
                world:insert(grabberId, grabberC:patch({
                    grabbableId = grabbableId,
                    grabOffsetCFrame = grabOffset,
                    grabPointObjectCFrame = grabPoint,
                }), rtcC:patch({
                    blacklist = Llama.List.toSet({player}),
                }))
                return true
            else
                -- it'll revert clientside, no need to do anything serverside
                return false
            end
        else
            -- let go
            world:insert(grabberId, grabberC:patch({
                grabbableId = Matter.None,
                grabOffsetCFrame = Matter.None,
            }))
            return true
        end
    end)
end

return GrabStart
