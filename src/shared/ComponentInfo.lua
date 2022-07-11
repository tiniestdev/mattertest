local ComponentInfo = {}

export type InstanceType = {
	instance: Instance,
}
export type PhysicsType = {
	velocity: Vector3,
	angularVelocity: Vector3,
	mass: number,
	density: number,
	friction: number,
	restitution: number,
	doNotReconcile: boolean,
}

export type TransformType = {
	cframe: CFrame,
	size: Vector3,
}

-- lookup of fields that are expected to be found inside any component
ComponentInfo.genericFields = {
	["doNotReconcile"] = true,
}

ComponentInfo.Catalog = {
    -- CLIENT COMPONENTS
	InToolbar = {
        CLIENTCOMPONENT = true;
    },
	Ours = {
        CLIENTCOMPONENT = true;
    },
		-- use this component to force an entity to not be changed by
		-- server replication even if the server replicates changes to its state
		-- set the property lockLinks to make it so any entity with a reference to it
		-- will also be forced to maintain the same relationship with the entity
		-- that it is locked to
		-- should be removed if you wish to allow replication again

		-- actually maybe instead of a component just have it be a field in a component
		-- so it can be applied to individual components instead of affecting the entire entity and locking ALL its components
	ClientLocked = {
        CLIENTCOMPONENT = true;
		clientLocked = {};
		lockLinks = {};
    },
	CheckArchetypes = {
        CLIENTCOMPONENT = true;
        archetypeSet = {};
    },
	ShowMatterDebug = {
		CLIENTCOMPONENT = true;
		adornee = {};
	},
	Replicated = {
		CLIENTCOMPONENT = true;
		serverId = {};
		scope = {};
		identifier = {};
	},

	-- SERVER COMPONENTS
	ReplicateToClient = {
		SERVERCOMPONENT = true;
		disabled = {};
		replicateFlag = {}; -- use in conjunction with disabled. Will force replication, then immediately reset back to false.
		archetypes = {};
		blacklist = {}; -- a set of players to avoid replicating to
		whitelist = {}; -- a set of players that will be allowed to be replicated to
	},

    -- SHARED COMPONENTS
	Instance = {
		instance = {};
	},
	Flammable = {

	},

	-- Basepart stuff
	Physics = {
        velocity = {};
        angularVelocity = {};
        mass = {};
        density = {};
        friction = {};
        restitution = {};
	},
	Transform = {
        cframe = {};
        size = {};
	},
	Grabber = {
		grabbableId = {
			isReference = true;
			referenceToArchetype = "Grabbable";
			replicateNil = true;
		};
		grabberInstance = {}; -- Define a specific grab PART to use to calculate offset
		grabbableInstance = {}; -- Same (may be redundant cause this can be derived from grabbableId)
		grabOffsetCFrame = {}; -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
		grabPointObjectCFrame = {}; -- for players who click a specific point on the grabbable part to manipulate

		grabStrength = {}; -- Changes maxforce and maxtorque
		grabVelocity = {};
		grabResponsiveness = {};
		
		grabEffectRadiusStart = {}; -- at this distance, it will begin to fade away due to distance
		grabEffectRadiusEnd = {}; -- at this distance, the grab will be completely faded away and nonexistent
	},
	Grabbable = {
		grabberIds = {
            isReferenceSet = true;
            referenceToArchetype = "Grabber";
		};
		grabbableInstance = {};
		ownedBySinglePlayer = {};
	},

	-- Applied to objects associated with a certain team or alliance.
	Teamed = {
		teamId = {
            isReference = true;
            referenceToArchetype = "Team";
        },
	},

	-- Actual entities of teams and groups
	Team = {
		allianceId = {
			isReference = true;
			referenceToArchetype = "Alliance";
		},
        playerIds = {
            isReferenceSet = true;
            referenceToArchetype = "PlayerArchetype";
        },
		teamName = {},
		color = {},
		autoAssignable = {},
	},
	Alliance = {
        teamIds = {
            isReferenceSet = true;
            referenceToArchetype = "Team";
        },
		allianceName = {},
	},

	Player = {
		player = {},
		characterId = {
            isReference = true;
            referenceToArchetype = "CharacterArchetype";
        },
	},
	NetworkOwned = {
		networkOwner = {},
		instances = {},
	},
	Character = {
		playerId = {
            isReference = true;
            referenceToArchetype = "PlayerArchetype";
        },
	},
	Skeleton = {
		skeletonInstance = {},
	},
	Ragdollable = {
		downed = {},
		stunned = {},
		sleeping = {},
	},
	Health = {
		health = {},
		maxHealth = {},
		    -- like if it wanted to take on a different archetype
	},
	Storage = {
		storableIds = {
            isReferenceSet = true;
            referenceToArchetype = "Storable";
        },
		capacity = {},
		maxCapacity = {},
	},
	Walkspeed = {
		walkspeed = {},
	},

	HoldForce = {

	},
	HoldForceClient = {

	},
	Holdable = {

	},
	
	GunTool = {
		-- STATE (initialized in systems)
		reloading = {}, -- user input determines this, can be held down
		triggered = {}, -- user input determines this, can be held down
		firing = {}, -- is it actually firing a bullet rn
		ammoInMag = {},
		ammoInStorage = {},
		fireMode = {},
		
		-- CONFIGURATION
		-- should coexist with ToolbarTool archetype
		storageCapacity = {}, -- set to -1 for infinite, default is 100
		magCapacity = {}, -- set to -1 for infinite, default is 20
		
		fireRate = {}, -- bullets per second
		bulletsPerShot = {}, -- number of bullets per shot, default 1
		fireModes = {}, -- set of fire modes, default Semi
		--[[
			0 = Semi
			1 = Auto
			2 = Burst
		]]

		flatSpread = {}, -- *flat* angle in degrees applied to any bullet, default 0
		fireSpread = {}, -- angle in degrees AFTER firing, default 0
		recoilKnockback = {}, -- knockback in force, default 0
		barrelSpeed = {}, -- base speed of bullets leaving it, default 100
		roundType = {}, -- string of bullet type/ rounds type, default "Default"

		attachments = {}, -- set of attachments it has equipped
		modifiers = {}, -- set of modifiers it has equipped (can affect bullets and gun)
	},
	Projectile = {
		-- REPLICATION STUFF
		active = {}, -- can pause/disable simulation if set to false

		-- STATE
		cframe = {}, -- cframe of the projectile
		velocity = {}, -- speed and direction
		life = {}, -- how long it has been alive
		bounces = {}, -- current bounces it used up
		traveledDistance = {}, -- how far it has traveled in studs
		penetratedDistance = {}, -- how far it has penetrated through solids so far
		mass = {}, -- default to 0, affects force applied to hit parts

		-- CONFIG
		ignoreList = {},
		beamObj = {}, -- will clone from this reference instance
		trailObj = {}, -- will clone from this reference instance
		trailWidth = {}, -- width of the trail, default 0.2
		gravity = {}, -- gravity applied to the projectile studs per second
		lifetime = {}, -- lifespan in seconds, default is 10 seconds, -1 forever
		maxDistance = {}, -- max distance in studs before dying, default is 500 studs
		--[[
			bounce system: at each hit, a bullet has a chance to bounce.
			if it bounces, reflects off hit surface and continues its path
			if it doesn't bounce, it tries to penetrate.
			if it penetrates all the way into empty space it continues
			if it doesn't penetrate all the way, it dies.
			if there are no bounces left, it dies.
		]]
		minBounces = {}, -- gauranteed bounces per life
		bounceChance = {}, -- bounce chance per intersection, default is 0.1
		maxBounces = {}, -- potential bounces per life, default 1
		elasticity = {}, -- how much momentum it retains after bouncing, default 0.7
		penetration = {}, -- studs, default 0.5
		collisionGroup = {}, -- string, determines what can be collided/interacted with
	},
	Round = {
		-- This component describes the effects of any projectile hit.
		-- Velocity/motion properties should be handled realtime by Projectile components.
		-- speed = {}, -- default to gun's bulletSpeed
		baseDamage = {}, -- default to 20, damage applied to humanoids
		-- explosive = {}, -- default to false (can be modified via components)
	},
	Explosive = {
		radius = {}, -- default to 50 studs, max range of effect
		deadRadius = {}, -- default to 5 studs. within this, max effect
		maxDamage = {}, -- 200
		maxKnockback = {}, -- default to 100, max force applied to hit parts
	},
	MeleeTool = {

	},

	Aimer = { -- for any entity that involves aiming/having its direction of aim (characters, sentries, etc)
		aimerInstance = {}, -- all below are relative to this instance's CFrame
		aimerCFrame = {}, -- all below are relative to this CFrame, overrides aimerInstance if set

		-- Pitch and yaw should be replicated very frequently
		
		pitch = {}, -- (up and down look) (in radians)
		yaw = {}, -- (side to side turns) (in radians)
		roll = {}, -- (tilt) (in radians, less used)
		target = {}, -- world position to look at (Vector3)
	},
	Equipper = {
		equippableId = {
            isReference = true;
            referenceToArchetype = "Equippable";
			replicateNil = true;
        },
	},
	Equippable = {
		presetName = {}, -- string key to lookup in Tools
		droppable = {}, -- can this be dropped by a player?????
		transferrable = {}, -- can it have a new owner other than the world/player
		equipperId = {
            isReference = true;
            referenceToArchetype = "Equipper";
        }, -- is nil if not equipped
		hotkey = {}, --CLIENT
	},
	Storable = { -- Should be able to be transferred between storages
		displayName = {},
		displayIcon = {},
		storageId = {
            isReference = true;
            referenceToArchetype = "Storage";
			replicateNil = true;
        },
		size = {},
		order = {},  -- integer used to sort it in a consistent way. If two storables have the same order, undefined behavior.
	},
	Corporeal = {
		instance = {},
	}, -- does it have a physical form? (Some instances aren't corporeal)

	Turret = {
		turretModel = {},
	},
}

ComponentInfo.getReplicateNilFields = function(componentName)
	local componentInfo = ComponentInfo.Catalog[componentName];
	if not componentInfo then
		warn("ComponentInfo.getReplicateNilFields: No component info for " .. componentName)
		return {}
	end
	local replicateNilFields = {};
	for field, info in pairs(componentInfo) do
		-- print(field, info)
		if typeof(info) == "table" and info.replicateNil then
			table.insert(replicateNilFields, field);
		end
	end
	return replicateNilFields
end


return ComponentInfo