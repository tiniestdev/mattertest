local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Fusion)

local EntityDump = require(script.Parent.EntityDump)

return function(target)
    local mounted = EntityDump({
        entityId = 69,
        headerTags = {"CharacterArchetype", "Grabber"},
        componentDumps = {
            Explosive = {
                chadano = {
                    ben = "benus",
                    is = "isadlask",
                },
                defenreate = 20,
            },
            Flammable = {
                sup = "yooo",
                sadyao = "yooo",
                chadano = {
                    komi = "wejiowa",
                    ben = "wejiowa",
                    is = "wejiowa",
                },
                defenreate = workspace.Baseplate,
            }
        },
        expanded = true,
    })
    mounted.Parent = target

    return function()
        mounted:Destroy()
    end
end