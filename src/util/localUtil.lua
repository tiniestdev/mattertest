local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local localUtil = {}

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
    local castResult = localUtil.castMouseWithParams(params, origin)
    local castPosition
    if castResult then
        castPosition = castResult.Position
    else
        local Mouse = localUtil.getMouse()

        local mousePosition = Mouse.Hit.Position
        local direction = (mousePosition - origin).Unit
        local distance = math.clamp((mousePosition - origin).Magnitude, 0, range)
        castPosition = origin + (direction * distance)
    end

    return castPosition
end

function localUtil.castMouseWithParams(params, origin)
    local Mouse = localUtil.getMouse()
    local Camera = localUtil.getCamera()

    local originPosition = origin or Camera.CFrame.Position
    local mousePosition = Mouse.Hit.Position
    local raycastResult = workspace:Raycast(originPosition, (mousePosition-originPosition).Unit * 100, params)

    return raycastResult
end

return localUtil