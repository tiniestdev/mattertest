local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.signal)
local Fusion = require(ReplicatedStorage.Fusion)
local Intercom = {}

Intercom.Signals = {}
Intercom.FusionValues = {}
Intercom.Blackboard = {}

function Intercom.Get(signalName)
    if not Intercom.Signals[signalName] then
        Intercom.Signals[signalName] = Signal.new()
    end
    return Intercom.Signals[signalName]
end

function Intercom.GetFusionValue(valueName, defaultValue)
    -- print("GETFUSIONVALUE CALLBACK: ", debug.traceback())
    if not Intercom.FusionValues[valueName] then
        Intercom.FusionValues[valueName] = Fusion.Value(defaultValue)
    end
    return Intercom.FusionValues[valueName]
end

return Intercom