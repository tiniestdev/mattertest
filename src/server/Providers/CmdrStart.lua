local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Cmdr = require(ServerScriptService.ServerPackages.cmdr)

local CmdrStart = {}

CmdrStart.AxisName = "CmdrStartAxis"

function CmdrStart:AxisPrepare()
    Cmdr:RegisterDefaultCommands()
    Cmdr:RegisterHooksIn(script.Parent.Parent.CmdrHooks)
    Cmdr.Registry:RegisterCommandsIn(script.Parent.Parent.CmdrCommands)
end

function CmdrStart:AxisStarted()
end

return CmdrStart
