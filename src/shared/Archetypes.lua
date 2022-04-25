local Archetypes = {}

Archetypes.Catalog = {
    PlayerArchetype = {
        "Player",
        "Teamed",
        "Instance",
    },
    CharacterArchetype = {
        "NetworkOwned",
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