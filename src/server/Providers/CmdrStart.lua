local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local ComponentInfo = require(ReplicatedStorage.ComponentInfo) 
local CmdrTypes = require(ReplicatedStorage.CmdrTypes)

local Cmdr = require(ServerScriptService.ServerPackages.cmdr)

local CmdrStart = {}

CmdrStart.AxisName = "CmdrStartAxis"

function CmdrStart:AxisPrepare()
    for typeName, typeInfo in pairs(CmdrTypes.Catalog) do
        if typeInfo.ENUM ~= nil then
            -- print(typeInfo.ENUM)
            Cmdr.Registry:RegisterType(typeName, Cmdr.Registry.Cmdr.Util.MakeEnumType(typeName, typeInfo.ENUM))
        else
            Cmdr.Registry:RegisterType(typeName, typeInfo)
        end
    end
    Cmdr:RegisterDefaultCommands()
    Cmdr:RegisterHooksIn(script.Parent.Parent.CmdrHooks)
    Cmdr.Registry:RegisterCommandsIn(script.Parent.Parent.CmdrCommands)
end

function CmdrStart:AxisStarted()
end

return CmdrStart
