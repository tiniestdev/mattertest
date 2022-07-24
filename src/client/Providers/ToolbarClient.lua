local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localUtil = require(ReplicatedStorage.Util.localUtil)

local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.components)
local Promise = require(ReplicatedStorage.Packages.promise)
local Remotes = require(ReplicatedStorage.Remotes)
local Intercom = require(ReplicatedStorage.Intercom)

local Toolbar = {}

Toolbar.AxisName = "ToolbarAxis"
local MatterClient = require(script.Parent.MatterClient)

function Toolbar:AxisPrepare()
    -- print("Toolbar: Axis prepare")
end

function Toolbar:AxisStarted()
    -- print("Toolbar: Axis started")
    local world = MatterClient.World

    --[[
        i was thinking toolbar should be entirely local but 
        the server should also impose its changes onto the client
         forecefully and force em to update its worldview but then 
            i dont want it to be its own entirely separate replication
             system so uhh im putting this off for later
    ]]

    Intercom.Get("EquipEquippable"):Connect(function(equippableId)
        local myCharacterId = localUtil.getMyCharacterEntityId(world)
        if not myCharacterId then warn("wtf no characterid entity??") end
        local equipperC = world:get(myCharacterId, Components.Equipper)
        local equippableC = world:get(equippableId, Components.Equippable)

        if equippableId == equipperC.equippableId then
            world:insert(myCharacterId, equipperC:patch({
                equippableId = Matter.None
            }))
        else
            world:insert(myCharacterId, equipperC:patch({
                equippableId = equippableId
            }))
        end
    end)
end

return Toolbar

