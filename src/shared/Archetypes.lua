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
}

return Archetypes