local Constants = {}

Constants.CollisionNames = {
    HRP = "HumanoidRootPart";
    CHAR = "Character";
    RAGDOLL = "Ragdoll";
    SKELETON = "Skeleton";
    DEFAULT = "Default";
}
--[[
	PhysicsService:CollisionGroupSetCollidable(GameConstants.SKELETON_COLLISION_NAME, GameConstants.HRP_COLLISION_NAME, false)
	PhysicsService:CollisionGroupSetCollidable(GameConstants.SKELETON_COLLISION_NAME, GameConstants.SKELETON_COLLISION_NAME, true)

    PhysicsService:CollisionGroupSetCollidable(GameConstants.RAGDOLL_COLLISION_NAME, GameConstants.RAGDOLL_COLLISION_NAME, false)
	PhysicsService:CollisionGroupSetCollidable(GameConstants.RAGDOLL_COLLISION_NAME, GameConstants.SKELETON_COLLISION_NAME, false)
    PhysicsService:CollisionGroupSetCollidable(GameConstants.RAGDOLL_COLLISION_NAME, GameConstants.HRP_COLLISION_NAME, false)
    PhysicsService:CollisionGroupSetCollidable(GameConstants.RAGDOLL_COLLISION_NAME, "Default", false)
]]
Constants.CollisionRelations = {
    SKELETON = {
        HRP = false,
        SKELETON = true,
    },
    RAGDOLL = {
        RAGDOLL = false,
        SKELETON = false,
        HRP = false,
        DEFAULT = false,
    },
}

Constants.Ragdoll = {
    DOWNED_HEALTH = 20;
}

return Constants