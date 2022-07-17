local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets
local RoundInfos = {}

RoundInfos.Catalog = {
    Default = {
        Projectile = {
            maxBounces = 1,
            beamObj = Assets.Rounds.Default,
            trailObj = Assets.Rounds.DefaultTrail,
            mass = 0.05,
        },
        Round = {
            baseDamage = 20, -- default to 20, damage applied to humanoids
        }
    },
    Heavy = {
        Projectile = {
            maxBounces = 1,
            beamObj = Assets.Rounds.Heavy,
            trailObj = Assets.Rounds.HeavyTrail,
            trailWidth = 0.15,
            mass = 0.5,
        },
        Round = {
            baseDamage = 70, -- default to 20, damage applied to humanoids
        }
    },
    Bouncy = {
        Projectile = {
            minBounces = 2,
            maxBounces = 8,
            bounceChance = 0.7,
            beamObj = Assets.Rounds.Bouncy,
            trailObj = Assets.Rounds.BouncyTrail,
            trailWidth = 0.1,
            elasticity = 0.9,
            mass = 0.1,
        },
        Round = {
            baseDamage = 10,
        }
    },
    HeavyBouncy = {
        Projectile = {
            minBounces = 2,
            maxBounces = 8,
            bounceChance = 0.7,
            beamObj = Assets.Rounds.HeavyBouncy,
            trailObj = Assets.Rounds.HeavyBouncyTrail,
            trailWidth = 0.8,
            elasticity = 0.9,
            mass = 1,
        },
        Round = {
            baseDamage = 80,
        }
    },
    Chaotic = {
        Projectile = {
            minBounces = 8,
            maxBounces = 20,
            bounceChance = 0.8,
            penetration = 2,
            elasticity = 1.2,
            beamObj = Assets.Rounds.Chaotic,
            trailObj = Assets.Rounds.ChaoticTrail,
            mass = 1,
        },
        Round = {
            baseDamage = 50,
        },
        Explosive = {
            radius = 20,
            deadRadius = 10,
            maxDamage = 100,
            maxKnockback = 500,
        },
    }
}

return RoundInfos