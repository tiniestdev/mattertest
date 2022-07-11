local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)
local RoundInfos = require(ReplicatedStorage.RoundInfos)
local RDM = Random.new()

return function(world)
    for id, turretCR in world:query(Components.Turret) do
        if turretCR.new and turretCR.turretModel then
            local turretModel = turretCR.turretModel
            local roundType = turretModel:GetAttribute("RoundType")
            local spread = turretModel:GetAttribute("Spread")
            local firerate = turretModel:GetAttribute("FireRate")
            local speed = turretModel:GetAttribute("Speed")
            if firerate <= 0 then continue end
            if Matter.useThrottle(1/firerate, id) then
                local barrelEnd = turretModel.Barrel.BarrelEnd
                local startCFrame = barrelEnd.WorldCFrame

                local radSpread = math.rad(spread)
                startCFrame = startCFrame:toWorldSpace(CFrame.Angles(
                    RDM:NextNumber(-radSpread, radSpread),
                    RDM:NextNumber(-radSpread, radSpread),
                    RDM:NextNumber(-radSpread, radSpread)
                ))

                local roundId = projectileUtil.fireRound(
                    startCFrame,
                    startCFrame.LookVector.Unit * speed or 100,
                    -- "Default",
                    RoundInfos.Catalog[roundType] and roundType or "Default",
                    {turretModel},
                    world
                )
            end
        end
    end
end