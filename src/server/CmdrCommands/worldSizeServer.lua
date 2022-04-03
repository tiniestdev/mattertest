local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local worldCache

return function(context, isServer)
    if not isServer then return end

    if not worldCache then
        local MatterProv = require(ServerScriptService:FindFirstChild("MatterStart", true))
        worldCache = MatterProv.World
    end

    return worldCache:size()
end