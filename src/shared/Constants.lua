local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = {}

Constants.CollisionNames = {
    HRP = "HumanoidRootPart";
    CHAR = "Character";
    RAGDOLL = "Ragdoll";
    SKELETON = "Skeleton";
    DEFAULT = "Default";
}

Constants.FireModes = {
    Semi = 0,
    Auto = 1,
    Burst = 2,
}

Constants.EPSILON = 0.001

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