local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assetUtil = require(ReplicatedStorage.Util.assetUtil)
local Components = require(ReplicatedStorage.components)

local combatUtil = {}

local bodyPartsToMultiplier = {
    ["Head"] = 1.5,
    ["Torso"] = 1,
    ["Left Arm"] = 0.5,
    ["Right Arm"] = 0.5,
    ["Left Leg"] = 0.5,
    ["Right Leg"] = 0.5,
    ["Handle"] = 1,
}

function combatUtil.areTeamsAllied(teamId1, teamId2, world)
    local teamC1 = world:get(teamId1, Components.Team)
    local teamC2 = world:get(teamId2, Components.Team)
    if teamC1 and teamC2 then
        return teamC1.allianceId == teamC2.allianceId
    end
    return false
end

function combatUtil.canRoundDamage(roundId, victimId, world)
    if not (world:contains(roundId) and world:contains(victimId)) then return false end
    local roundC = world:get(roundId, Components.Round)
    if not roundC then return false end
    local victimHealthC = world:get(victimId, Components.Health)
    if not victimHealthC then return false end

    -- If the round is teamed, use that
    local teamedRoundC = world:get(roundId, Components.Teamed)
    local teamedVictimC = world:get(victimId, Components.Teamed)
    if teamedRoundC and teamedVictimC then
        if combatUtil.areTeamsAllied(teamedRoundC.teamId, teamedVictimC.teamId, world) then
            return false
        end
    end

    -- Otherwise, if owned by a player, use the player's team
    local playerOwnedC = world:get(roundId, Components.PlayerOwned)
    if playerOwnedC then
        local teamedOwnedC = world:get(playerOwnedC.ownerId, Components.Teamed)
        local teamedVictimC = world:get(victimId, Components.Teamed)
        if teamedOwnedC and teamedVictimC then
            if combatUtil.areTeamsAllied(teamedOwnedC.teamId, teamedVictimC.teamId, world) then
                return false
            end
        end
    end

    return true
end

function combatUtil.getHumanoidFromInstance(instance)
    local foundHum = instance:FindFirstChild("Humanoid") or instance.Parent:FindFirstChild("Humanoid")
    if foundHum then return foundHum end
    if instance.Name == "Handle" then return instance.Parent.Parent:FindFirstChild("Humanoid") end
end
function combatUtil.getCharFromInstance(instance)
    local hum = combatUtil.getHumanoidFromInstance(instance)
    return hum and hum.Parent or nil
end

function combatUtil.getDamageFromRoundToInstance(roundId, hitInstance, world)
    local roundC = world:get(roundId, Components.Round)
    if not roundC then return 0 end
    local multiplier = bodyPartsToMultiplier[hitInstance.Name] or 1
    return roundC.baseDamage * multiplier
end

function combatUtil.damageResults(victimId, damage, world)
    local victimHealthC = world:get(victimId, Components.Health)
    if not victimHealthC then return end
    local finalHealth = math.max(0, victimHealthC.health - damage)
    local died = finalHealth <= 0

    return {
        finalHealth = finalHealth,
        died = died,
    }
end

local imagesCache = {}
function combatUtil.sprayBloodFx(start, incident, radius, blacklist)
    local bloodCastParams = RaycastParams.new()
    bloodCastParams.FilterDescendantsInstances = blacklist
    bloodCastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(start, incident, bloodCastParams)
    if result then
        local blood = Instance.new("Part")
        blood.Name = "Blood"
        blood.Anchored = false
        blood.CanCollide = false
        blood.CanQuery = false
        blood.Transparency = 1
        blood.Size = Vector3.new(radius, 0.01, radius)
        blood.Parent = workspace
        blood.Massless = true
        
        local maxDistance = incident.Magnitude
        local intensity = (result.Position - start).Magnitude / maxDistance
        local bloodDecal
        if intensity > 0.8 then
            -- max blood
            bloodDecal = assetUtil.getRandomImageFromCategory("Splatter")
        elseif intensity > 0.4 then
            -- min blood
            bloodDecal = assetUtil.getRandomImageFromCategory("LightSplatter")
        else
            -- droplets
            bloodDecal = assetUtil.getRandomImageFromCategory("SplatterDrops")
        end
        local topBlood = bloodDecal:Clone()
        local botBlood = bloodDecal:Clone()
        topBlood.Face = Enum.NormalId.Top
        botBlood.Face = Enum.NormalId.Bottom
        topBlood.Parent = blood
        botBlood.Parent = blood
        blood.CFrame = CFrame.new(result.Position, incident:Cross(result.Normal))

        task.delay(3, function()
            blood:Destroy()
        end)
    end
end

return combatUtil