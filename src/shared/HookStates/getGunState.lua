local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

return function(dis)
    local storage = Matter.useHookState(dis, function(storage)
        if storage.gyro then
            storage.gyro:Destroy()
            storage.gyro = nil
        end
    end)
    return storage
end
