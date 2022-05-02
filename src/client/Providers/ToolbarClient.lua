local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.promise)
local Remotes = require(ReplicatedStorage.Remotes)

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
end

return Toolbar

