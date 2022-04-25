local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Axis = require(ReplicatedStorage.Packages.axis)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local CmdrTypes = require(ReplicatedStorage.CmdrTypes)

local CmdrClient = {}

CmdrClient.AxisName = "CmdrClientAxis"

function CmdrClient:AxisPrepare()
    -- print("CmdrClient: Axis prepare")
    for typeName, typeInfo in pairs(CmdrTypes.Catalog) do
        if typeInfo.ENUM ~= nil then
            -- print(typeInfo.ENUM)
            Cmdr.Registry:RegisterType(typeName, Cmdr.Registry.Cmdr.Util.MakeEnumType(typeName, typeInfo.ENUM))
        else
            Cmdr.Registry:RegisterType(typeName, typeInfo)
        end
    end
    Cmdr:SetActivationKeys({ Enum.KeyCode.Semicolon })
end

function CmdrClient:AxisStarted()
    -- print("CmdrClient: Axis started")
end

return CmdrClient
