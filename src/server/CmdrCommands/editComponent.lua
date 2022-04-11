local ReplicatedStorage = game:GetService("ReplicatedStorage")
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local Components = require(ReplicatedStorage.components)
local worldCache

return {
    Name = "editComponent";
    Aliases = {"edc"};
    Description = "Edits a component's state in a given entity.";
    Group = "Owner";
    Args = {
        {
            Type = "integer";
            Name = "entityId";
            Description = "The integer number that represents the entity.";
        },
        {
            Type = "component";
            Name = "componentName";
            Description = "The name of the component to edit.";
        },
        {
            Type = "string";
            Name = "fieldName";
            Description = "The field of the component to edit.";
        },
        {
            Type = "string # number ! boolean @ instance";
            Name = "fieldData";
            Description = "The new data of the field.";
        },
        {
            Type = "boolean";
            Name = "isServer";
            Description = "Whether or not the command is being run on the server.";
            Default = false;
        },
    };
    ClientRun = function(context, entityId, componentName, fieldName, fieldData, isServer)
        if isServer then return end

        if not worldCache then
            local MatterClient = require(context.Executor:FindFirstChild("MatterClient", true))
            worldCache = MatterClient.World
        end

        return matterUtil.editComponent(worldCache, entityId, componentName, fieldName, fieldData)
    end;
}