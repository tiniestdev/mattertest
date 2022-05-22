local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local localUtil = {}

local MAX_MOUSERAY_RANGE = 500

function localUtil.getMyPlayerEntityId(world)
    for id, playerC, oursC in world:query(Components.Player, Components.Ours) do
        return id
    end
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
    local playerC = world:get(localUtil.getMyPlayerEntityId(world), Components.Player)
    if not playerC then
        error("WTF: Could not find player component:\n" .. debug.traceback())
        return nil
    end
    return playerC.characterId
    -- okay wtf
    -- for id, characterC, oursC in world:query(Components.Character, Components.Ours) do
    --     return id
    -- end
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

return localUtil