local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Axis = require(ReplicatedStorage.Packages.axis)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))

local CmdrClient = {}

CmdrClient.AxisName = "CmdrClientAxis"

function CmdrClient:AxisPrepare()
    print("CmdrClient: Axis prepare")
    Cmdr:SetActivationKeys({ Enum.KeyCode.Semicolon })
end

function CmdrClient:AxisStarted()
    print("CmdrClient: Axis started")
end

return CmdrClient
