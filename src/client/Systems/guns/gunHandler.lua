local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)

local getGunState = require(ReplicatedStorage.HookStates.getGunState)
local localUtil = require(ReplicatedStorage.Util.localUtil)
local projectileUtil = require(ReplicatedStorage.Util.projectileUtil)

return function(world)

    for id, gunToolCR in world:queryChanged(Components.GunTool) do
        if not gunToolCR.new then continue end
        local equippableC = world:get(id, Components.Equippable)
        if not equippableC then continue end
        local charId = localUtil.waitForCharacterEntityId(world)
        if equippableC.equipperId == charId then
            -- equipped
            world:insert(id, Components.ClientLocked({
                clientLocked = true,
            }))
        else
            -- unequipped
            world:insert(id, Components.ClientLocked({
                clientLocked = false,
            }))
        end
    end

    local triggeredGuns = {}
    local untriggeredGuns = {}
    for id, gunToolC, equippableC, corporealC in world:query(Components.GunTool, Components.Equippable, Components.Corporeal) do
        local charId = localUtil.waitForCharacterEntityId(world)
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

        -- print(id, gunToolC.triggered)
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