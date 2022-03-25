local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Matter = require(ReplicatedStorage.Packages.matter)
local Fusion = require(ReplicatedStorage.Fusion)
local Components = require(ReplicatedStorage.components)
local uiUtil = require(ReplicatedStorage.Util.uiUtil)
local New = Fusion.New

local focusOn = "Toolbar"

local component = require(script.Parent:FindFirstChild(focusOn, true))
local ClearFrame = require(script.Parent.ClearFrame)

return function(target)
    local world = Matter.World.new()
    local grab = world:spawn(Components.Storable({
        size = 1,
    }), Components.Equippable({
        name = "Grabber",
    }))
    local apple = world:spawn(Components.Storable({
        size = 2,
    }), Components.Corporeal({
        instance = ReplicatedStorage.Corporeals.Apple,
    }))
    local storage = world:spawn(Components.Storage({
        storableIds = {
            [apple] = true,
            [grab] = true,
        },
    }))

    local mounted = ClearFrame {
        Parent = target;
        [Fusion.Children] = {
            component {
                storableProps = uiUtil.getStorablePropsFromStorage(storage, world),
            },
        }
    }
    return function()
        mounted:Destroy()

        world:clear()
    end
end
