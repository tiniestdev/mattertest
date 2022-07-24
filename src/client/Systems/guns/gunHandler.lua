local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local getGunState = require(ReplicatedStorage.HookStates.getGunState)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)

return function(world)

    local triggeredGuns = {}
    local untriggeredGuns = {}
    local charId = localUtil.getMyCharacterEntityId(world)
    if not charId then return end
    
    for id, gunToolC, equippableC, corporealC in world:query(Components.GunTool, Components.Equippable, Components.Corporeal) do
        if equippableC.equipperId ~= charId then continue end

        local gunState = getGunState()
        for _, input in Matter.useEvent(UserInputService, "InputBegan") do
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                table.insert(triggeredGuns, {id, gunToolC})
            end
        end

        for _, input in Matter.useEvent(UserInputService, "InputEnded") do
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                table.insert(untriggeredGuns, {id, gunToolC})
            end
        end

        if gunToolC.triggered then
            if not gunState.lastFired then
                gunState.lastFired = 0
            end
            local fireDelay = 1 / math.max(gunToolC.fireRate, 0.0001)
            local currentTick = tick()
            if (currentTick - gunState.lastFired > fireDelay) then
                world:insert(id, gunToolC:patch({
                    firing = true,
                }))
                gunState.lastFired = currentTick

                local barrelBegin = corporealC.instance.Barrel.BarrelBegin.WorldPosition
                local barrelEnd = corporealC.instance.Barrel.BarrelEnd.WorldPosition
                local barrelCFrame = CFrame.new(barrelBegin, barrelEnd)
                local aimerC = localUtil.getAimerC(world)

                projectileUtil.fireRound(
                    barrelCFrame,
                    (aimerC.target - barrelEnd).Unit * gunToolC.barrelSpeed,
                    gunToolC.roundType,
                    {
                        corporealC.instance,
                        localUtil.getCharacter(),
                        localUtil.getSkeletonInstance(world),
                        workspace.CurrentCamera,
                    },
                    id,
                    world
                )
                -- projectileUtil.fireLocalBullet(world)
            else
                world:insert(id, gunToolC:patch({
                    firing = false,
                }))
            end
        end
        
        -- CHAR MOVEMENT
        if not gunState.gyro then
            local gyro = Instance.new("BodyGyro")
            gunState.gyro = gyro
            gyro.MaxTorque = Vector3.new(0, 100000, 0)
            gyro.D = 100
            gyro.P = 10000
        end
        local aimerC = localUtil.getAimerC(world)
        if aimerC then
            local aimerCF = aimerC.aimerCFrame or aimerC.aimerInstance.CFrame
            gunState.gyro.CFrame = CFrame.new(aimerCF.Position, aimerC.target)
        end
        local hrp = localUtil.getHRP()
        if hrp then
            gunState.gyro.Parent = hrp
        end
    end

    for _,v in ipairs(triggeredGuns) do
        world:insert(v[1], v[2]:patch({
            triggered = true,
        }))
    end
    for _,v in ipairs(untriggeredGuns) do
        world:insert(v[1], v[2]:patch({
            triggered = false,
        }))
    end
end