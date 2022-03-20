local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local Components = require(ReplicatedStorage.components)
local MatterUtil = require(ReplicatedStorage.Util.matterUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)

local Net = require(ReplicatedStorage.Packages.Net)
local Remotes = require(ReplicatedStorage.Remotes)

local MatterStart = {}

MatterStart.AxisName = "MatterStartAxis"
MatterStart.World = Matter.World.new()
local world = MatterStart.World

function MatterStart:AxisPrepare()
    print("MatterStart: Axis prepare")
    MatterStart.MainLoop = Matter.Loop.new(world)
    print("MatterStart: Made Matter World + Loop")
end

function MatterStart:AxisStarted()
    print("MatterStart: Axis started")

    print("MatterStart: Starting systems...")
    local systems = {}
    for _, systemModule in ipairs(script.Parent.Parent.Systems:GetDescendants()) do
        if systemModule:IsA("ModuleScript") then
            table.insert(systems, require(systemModule))
        end
    end

    print("MatterStart: Scheduling systems")
    MatterStart.MainLoop:scheduleSystems(systems)
    MatterStart.MainLoop:begin({ default = RunService.Heartbeat })

    print("MatterStart: Binding components from tags")
    MatterUtil.bindCollectionService(world)

    local chest = world:spawn(
        Components.Storage({
            storableIds = {},
            maxCapacity = 10,
        })
    )
    local pear = world:spawn(
        Components.Storable({
            storageId = nil,
            size = 2,
        }),
        Components.Corporeal({
            instance = workspace.pear
        })
    )
    local apple = world:spawn(
        Components.Storable({
            storageId = nil,
            size = 2,
        }),
        Components.Corporeal({
            instance = workspace.apple
        })
    )
    local orange = world:spawn(
        Components.Storable({
            storageId = nil,
            size = 3,
        }),
        Components.Corporeal({
            instance = workspace.orange
        })
    )
    local bigSword = world:spawn(
        Components.Storable({
            storageId = nil,
            size = 3,
        }),
        Components.Corporeal({
            instance = workspace.sword
        })
    )

    print(world:get(bigSword, Components.Corporeal))
    --[[
    task.spawn(function()
        task.wait(1)
        print("Gonna insert pear")
        world:insert(pear, world:get(pear, Components.Storable):patch({
            storageId = chest,
        }))
        task.wait(1)
        print("Gonna insert apple")
        world:insert(apple, world:get(apple, Components.Storable):patch({
            storageId = chest,
        }))
        task.wait(1)
        print("Gonna insert orange")
        world:insert(orange, world:get(orange, Components.Storable):patch({
            storageId = chest,
        }))
        task.wait(2)
        print("Gonna insert bigSword")
        world:insert(bigSword, world:get(bigSword, Components.Storable):patch({
            storageId = chest,
        }))
        task.wait(3)
        print("Removing every single item from the chest")
        world:insert(chest, world:get(chest, Components.Storage):patch({
            storableIds = {},
        }))
        task.wait(3)
        print("Inserting every single item back into the chest")
        world:insert(chest, world:get(chest, Components.Storage):patch({
            storableIds = Llama.List.toSet({
                pear,
                apple,
                orange,
                bigSword,
            }),
        }))
    end)]]
end

return MatterStart