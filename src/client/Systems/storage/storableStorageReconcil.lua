local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local storageUtil = require(ReplicatedStorage.Util.storageUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)

local Llama = require(ReplicatedStorage.Packages.llama)
local Set = Llama.Set

return function(world)
    matterUtil.reconcileManyToOneRelationship(world, "Storable", "Storage")
end