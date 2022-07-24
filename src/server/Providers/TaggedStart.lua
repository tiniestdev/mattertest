local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Components = require(ReplicatedStorage.components)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local playerUtil = require(ReplicatedStorage.Util.playerUtil)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local ragdollUtil = require(ReplicatedStorage.Util.ragdollUtil)
local tableUtil = require(ReplicatedStorage.Util.tableUtil)

local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterStart = require(script.Parent.MatterStart)
local TaggedStart = {}

TaggedStart.AxisName = "TaggedStartAxis"
local RDM = Random.new()

local tagToTask = {
    Turret = function(instance, world)
        local id = world:spawn(
            Components.Turret({
                turretModel = instance,
            }),
            Components.Instance({
                instance = instance,
            })
        )
        matterUtil.setEntityId(instance, id)
    end,
    NPC = function(instance, world)
        assert(instance:IsA("Model"))
        assert(instance:FindFirstChild("Humanoid"))
        local id = world:spawn(
            Components.ReplicateToClient({
                archetypes = tableUtil.ToSet({"CharacterArchetype"})
            }),
            Components.Instance({
                instance = instance,
            }),
            Components.Character({
                -- playerId = nil,
                jumpHeight = 4,
            }),
            Components.Skeleton({}),
            Components.Ragdollable({
                downed = false,
                stunned = false,
                sleeping = false,
            }),
            Components.Health({
                health = 100,
                maxHealth = 100,
            }),
            Components.Storage({
                storableIds = {},
                capacity = 0,
                maxCapacity = 10,
            }),
            Components.Equipper({
                -- equippableId = Matter.None,
            }),
            Components.Grabber({
                -- grabbableId = Matter.None,
                grabberInstance = instance.Head; -- Define a specific grab PART to use to calculate offset
                -- grabbableInstance = Matter.None; -- Same
                grabOffsetCFrame = CFrame.new(); -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
                grabPointObjectCFrame = CFrame.new(); -- for players who click a specific point on the grabbable part to manipulate
                grabStrength = 8.5 * workspace.Gravity; -- Changes maxforce and maxtorque
                grabVelocity = 30;
                grabResponsiveness = 30;
                grabEffectRadiusStart = 5; -- at this distance, it will begin to fade away due to distance
                grabEffectRadiusEnd = 17; -- at this distance, the grab will be completely faded away and nonexistent
            }),
            Components.Walkspeed({
                walkspeed = 16,
            })
        )
        matterUtil.setEntityId(instance, id)
    end,
    Grabbable = function(instance, world)
        if instance:IsA("BasePart") then
            local id = world:spawn(
                Components.Instance({
                    instance = instance,
                }),
                Components.Grabbable({
                    grabbableInstance = instance,
                }),
                Components.ReplicateToClient({
                    archetypes = tableUtil.ToSet({"GrabbableArchetype"})
                }),
                Components.NetworkOwned({
                    instances = instance,
                })
            )
            matterUtil.setEntityId(instance, id)
        elseif instance:IsA("Model") or instance:IsA("Folder") then
            for i,v in ipairs(instance:GetChildren()) do
                if v:IsA("BasePart") then
                    local id = world:spawn(
                        Components.Instance({
                            instance = v,
                        }),
                        Components.Grabbable({
                            grabbableInstance = v,
                        }),
                        Components.ReplicateToClient({
                            archetypes = tableUtil.ToSet({"GrabbableArchetype"})
                        }),
                        Components.NetworkOwned({
                            instances = v,
                        })
                    )
                    matterUtil.setEntityId(v, id)
                end
            end
        end
    end,
}

function TaggedStart:AxisPrepare()
end

function TaggedStart:AxisStarted()
    local world = MatterStart.World

    for tagName, func in pairs(tagToTask) do
        for i, instance in ipairs(CollectionService:GetTagged(tagName)) do
            func(instance, world)
        end
        CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
            func(instance, world)
        end)
    end
end

return TaggedStart