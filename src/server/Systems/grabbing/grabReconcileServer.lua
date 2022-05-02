local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)

local Llama = require(ReplicatedStorage.Packages.llama)
local Set = Llama.Set

return function(world)
    matterUtil.reconcileManyToOneRelationship(world, "Grabber", "Grabbable")
end
