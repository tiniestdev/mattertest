local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)
local Constants = require(ReplicatedStorage.Constants)

local localUtil = require(ReplicatedStorage.Util.localUtil)
local geometryUtil = require(ReplicatedStorage.Util.geometryUtil)
local randUtil = require(ReplicatedStorage.Util.randUtil)
local soundUtil = require(ReplicatedStorage.Util.soundUtil)
local drawUtil = require(ReplicatedStorage.Util.drawUtil)

local function state(id)
    local storage = Matter.useHookState(id)
    return storage
end

local projectileStorage = {}

local whizSounds = {
    "bulletwhiz1",
    "bulletwhiz2_invert",
    "bulletwhiz3_high",
    "bulletwhiz4",
}

return function(world, _, ui)
    for id, projectileCR in world:queryChanged(Components.Projectile) do
        if not projectileCR.old then
            projectileStorage[id] = {}
        end
        if not projectileCR.new then
            projectileStorage[id] = nil
        end
    end
    for id, projectileC in world:query(Components.Projectile) do
        local currPosition = projectileC.cframe.Position
        -- local projState = state(id)
        local projState = projectileStorage[id]

        if not projState.prevPosition then
            projState.prevPosition = currPosition
            projState.whizzed = false
        end

        local camPosition = localUtil.getCamera().CFrame.Position
        -- idk maybe someday ill write better more custom code for this feature no one really cares about at all

        -- print(currPosition)
        -- ui.arrow(currPosition, currPosition + Vector3.new(0,2,0), Color3.new(1,1,0))
        local closestPointOnPath = geometryUtil.closestPointOnLine(camPosition, projState.prevPosition, currPosition)
        -- drawUtil.point(closestPointOnPath + Vector3(0,1,0), Color3.new(1,1,0))
        local closestDist = (closestPointOnPath - camPosition).Magnitude
        -- print(closestDist)

        if closestDist < 12 then
            -- if not projState.whizzed or Matter.useThrottle(id, 0.3) then
            if not projState.whizzed then
                -- The faster the velocity, the higher pitched.
                local velocity = projectileC.velocity
                -- Use logarithms
                local pitch = math.log(velocity.Magnitude) / 6
                local volume = pitch / 2
                -- print(pitch, volume)
                soundUtil.PlaySoundAtPos(randUtil.chooseFrom(whizSounds), closestPointOnPath, {
                    PlaybackSpeed = math.max(0.5, pitch + randUtil.getNum(-0.1,0.1)),
                    Volume = volume,
                })
                projState.whizzed = true
            end
        else
            if closestDist > 30 then
                projState.whizzed = false
            end
        end

        projState.prevPosition = currPosition
    end
end