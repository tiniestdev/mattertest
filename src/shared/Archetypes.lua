local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ComponentInfo = require(ReplicatedStorage.ComponentInfo)
local Archetypes = {}

Archetypes.Catalog = {
    PlayerArchetype = {
        "Player",
        "Teamed",
        "Instance",
    },
    CharacterArchetype = {
        "Ragdollable",
        "Character",
        "Health",
        "Skeleton",
        "Storage",
        "Equipper",
        "Grabber",
        "Teamed",
        "Instance",
        "Aimer",
    },
    RagdollableArchetype = { -- doesn't include ragdollable so we have to manually check for it
                            -- this is used to detect if an entity that is CAPABLE of being ragdolled
                            -- suddenly got its ragdollable component removed for some reason
        "Skeleton",
        "Character",
        "Instance",
    },
    ToolbarTool = {
        "Equippable",
        "Storable",
        "Corporeal",
    },
    GrabbableArchetype = {
        "Grabbable",
        "Instance",
    },
    BulletArchetype = {
        "Projectile", --do NOT replicate every single movement of the projectile
        "Round",
    }
}

for componentName, v in ipairs(ComponentInfo.Catalog) do
    Archetypes.Catalog[componentName] = {
        componentName,
    }
end

return Archetypes