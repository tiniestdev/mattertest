local ReplicatedStorage = game:GetService("ReplicatedStorage")
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local Components = require(ReplicatedStorage.components)
local worldCache

return {
    Name = "worldSize";
    Aliases = {"wsize"};
    Description = "Returns the world:size() value, or the number of entities in the world.";
    Group = "Owner";
    Args = {
        {
            Type = "boolean";
            Name = "onServer";
            Description = "If true, checks the server Matter world instead of the local Matter world.";
            Default = false;
        },
    };
    ClientRun = function(context, isServer)
        if isServer then return end

        if not worldCache then
            local MatterClient = require(context.Executor:FindFirstChild("MatterClient", true))
            worldCache = MatterClient.World
        end

        return worldCache:size()
    end;
}