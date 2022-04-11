local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local ComponentInfo = require(ReplicatedStorage.ComponentInfo) 

local CmdrTypes = {}

CmdrTypes.Catalog = {
    component = {
        ENUM = tableUtil.FlipNumeric(ComponentInfo.Catalog),
        -- Transform = function(text)
        --     return text;
        -- end;
        -- Validate = function(text)
        --     return ComponentInfo.Catalog[text] ~= nil, "Invalid type name: " .. text;
        -- end;
        -- Parse = function(value)
        --     return value
        -- end;
    },
}

return CmdrTypes