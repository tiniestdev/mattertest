local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local teamUtil = require(ReplicatedStorage.Util.teamUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)

local Intercom = require(ReplicatedStorage.Intercom)

return function(world)
    for id, ragdollableCR in world:queryChanged(Components.Ragdollable) do
        if ragdollableCR.new then
            if ragdollableCR.new.doNotReconcile then
                -- do this code snippet where you want to edit the entity on client
                
                -- world:insert(id, ragdollableCR.new:patch({
                --     doNotReconcile = false,
                -- }))
            else
                Intercom.Get("ProposeRagdollState"):Fire(ragdollableCR.new)
            end
        end
    end
end