local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.signal)
local Intercom = {}

Intercom.Signals = {}
Intercom.Blackboard = {}

function Intercom.Get(signalName)
    if not Intercom.Signals[signalName] then
        Intercom.Signals[signalName] = Signal.new()
    end
    return Intercom.Signals[signalName]
end

return Intercom