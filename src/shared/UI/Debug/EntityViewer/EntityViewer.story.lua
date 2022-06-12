local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Fusion)

local EntityViewer = require(script.Parent.EntityViewer)

return function(target)
    local mounted = EntityViewer({
        entityDumps = {
            {
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
            },
            {
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
            },
            {
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
            },
        }
    })
    mounted.Parent = target

    return function()
        mounted:Destroy()
    end
end