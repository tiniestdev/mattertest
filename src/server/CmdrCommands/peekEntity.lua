local ReplicatedStorage = game:GetService("ReplicatedStorage")
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local Components = require(ReplicatedStorage.components)
local worldCache

return {
    Name = "peekEntity";
    Aliases = {"pke"};
    Description = "Dumps a bunch of information about a given entity in Matter World";
    Group = "Owner";
    Args = {
        {
            Type = "integer";
            Name = "entityId";
            Description = "The integer number that represents the entity.";
        },
        {
            Type = "boolean";
            Name = "onServer";
            Description = "If true, checks the server Matter world instead of the local Matter world.";
            Default = false;
        }
    };
    ClientRun = function(context, entityId, isServer)
        if isServer then return end

        if not worldCache then
            local MatterClient = require(context.Executor:FindFirstChild("MatterClient", true))
            worldCache = MatterClient.World
        end

        return matterUtil.cmdrPrintEntityDebugInfo(context, entityId, worldCache)
    end;
}