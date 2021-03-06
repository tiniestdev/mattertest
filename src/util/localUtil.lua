local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local localUtil = {}

local MAX_MOUSERAY_RANGE = 500

function localUtil.waitForPlayerEntityId(world)
    local plrId = localUtil.getMyPlayerEntityId(world)
    if not plrId then
        while not plrId do
            plrId = localUtil.getMyPlayerEntityId(world)
            task.wait()
        end
    end
    return plrId
end

function localUtil.getMyPlayerEntityId(world)
    for id, playerC, oursC in world:query(Components.Player, Components.Ours) do
        return id
    end
    -- Nil should be an acceptable answer
    -- error("WTF: Could not find player id:\n" .. debug.traceback())
    return nil
end

function localUtil.getCamera()
    local Camera = workspace.CurrentCamera
    return Camera
end

function localUtil.getMouse()
    local Player = Players.LocalPlayer
    local Mouse = Player:GetMouse()
    return Mouse
end

function localUtil.getCharacter()
    local Player = Players.LocalPlayer
    local Character = Player.Character
    return Character
end

function localUtil.getHRP()
    local Character = localUtil.getCharacter()
    if not Character then return end
    return Character:FindFirstChild("HumanoidRootPart")
end
function localUtil.getHead()
    local Character = localUtil.getCharacter()
    if not Character then return end
    return Character:FindFirstChild("Head")
end

function localUtil.getCharComponent(componentName, world)
    local charId = localUtil.getMyCharacterEntityId(world)
    return world:get(charId, Components[componentName])
end

function localUtil.getSkeletonInstance(world)
    local charId = localUtil.getMyCharacterEntityId(world)
    local skeletonC = world:get(charId, Components.Skeleton)
    return skeletonC.skeletonInstance
end

function localUtil.getMyCharacterEntityId(world)
    local playerId = localUtil.getMyPlayerEntityId(world)
    if not playerId then return end
    local playerC = world:get(playerId, Components.Player)
    if not playerC then
        -- Nil should be an acceptable answer
        -- error("WTF: Could not find character id:\n" .. debug.traceback())
        return nil
    end
    return playerC.characterId
end

function localUtil.waitForCharacterEntityId(world)
    local playerId = localUtil.waitForPlayerEntityId(world)
    local charId = localUtil.getMyCharacterEntityId(world)
    if not charId then
        while not charId do
            charId = localUtil.getMyCharacterEntityId(world)
            task.wait()
        end
    end
    return charId
end

function localUtil.getDefaultLocalCastParams(world, ignoreList)
    local characterId = localUtil.getMyCharacterEntityId(world)

    local ignore = {
        Players.LocalPlayer.Character,
        workspace.CurrentCamera,
    }

    local skeletonC = world:get(characterId, Components.Skeleton)
    if skeletonC then table.insert(ignore, skeletonC.skeletonInstance) end
    local instanceC = world:get(characterId, Components.Instance)
    if instanceC then table.insert(ignore, instanceC.instance) end

    if ignoreList then
        for _, v in ipairs(ignoreList) do
            table.insert(ignore, v)
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignore
    params.CollisionGroup = "Default"

    return params
end

function localUtil.castMouseRangedHitWithParams(params, range, origin)
    local castResult, castPosition = localUtil.castMouseWithParams(params)
    if castResult and (castPosition - origin).Magnitude < range then
        return castPosition
    else
        local direction = (castPosition - origin).Unit
        local distance = math.clamp((castPosition - origin).Magnitude, 0, range)
        return origin + (direction * distance)
    end
end

-- the second return value is always a position, even if the raycast returned nothing
function localUtil.castMouseWithParams(params)
    local Mouse = localUtil.getMouse()
    local Camera = localUtil.getCamera()

    local camOrigin = Camera.CFrame.Position
    local mouseRaycastDirection = (Mouse.Hit.Position - camOrigin).Unit
    local mouseRaycastResult = workspace:Raycast(camOrigin, mouseRaycastDirection * MAX_MOUSERAY_RANGE, params)
    -- local mousePosition

    if mouseRaycastResult then
        return mouseRaycastResult, mouseRaycastResult.Position
    else
        return nil, (camOrigin + mouseRaycastDirection * MAX_MOUSERAY_RANGE)
    end

    -- if mouseRaycastResult then
    --     mousePosition = mouseRaycastResult.Position
    -- else
    --     mousePosition = Camera.CFrame.Position + (mouseRaycastDirection * 500)
    -- end

    -- local originPosition = origin or camOrigin
    -- local raycastResult = workspace:Raycast(originPosition, (mousePosition-originPosition).Unit * range, params)

    -- return raycastResult
end

function localUtil.getAimerC(world)
    local aimerId = localUtil.waitForCharacterEntityId(world)
    local aimerC = world:get(aimerId, Components.Aimer)
    return aimerC
end

return localUtil