local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local localUtil = require(ReplicatedStorage.Util.localUtil)

local storage = {}

return function(world)

    -- might be hanndled by gunhandler?
    
    -- local charId = localUtil.getMyCharacterEntityId(world)
    -- if not charId then return end

    -- local found, aimerC, equipperC = matterUtil.checkAndGetComponents(charId, world, "Aimer", "Equipper")
    -- if not found then return end
    -- if not equipperC.equippableId then return end
    
    -- local equippableC = world:get(equipperC.equippableId, Components.Equippable)
    -- local found, equippableC, gunToolC = matterUtil.checkAndGetComponents(charId, world, "Equippable", "GunTool")
    -- if not found then return end

end