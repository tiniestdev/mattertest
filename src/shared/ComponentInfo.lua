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
		archetypes = {};
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
		};
		grabberInstance = {}; -- Define a specific grab PART to use to calculate offset
		grabbableInstance = {}; -- Same
		grabOffsetCFrame = {}; -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
		grabPointObjectCFrame = {}; -- for players who click a specific point on the grabbable part to manipulate
	},
	Grabbable = {
		grabberIds = {
            isReferenceSet = true;
            referenceToArchetype = "Grabber";
		};
		grabbableInstance = {};
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
        playerIds = {
            isReferenceSet = true;
            referenceToArchetype = "PlayerArchetype";
        },
	},
	Alliance = {
        teamIds = {
            isReferenceSet = true;
            referenceToArchetype = "Team";
        },
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

	},
	MeleeTool = {

	},

	Equipper = {
		equippableId = {
            isReference = true;
            referenceToArchetype = "Equippable";
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
        },
		size = {},
		order = {},  -- integer used to sort it in a consistent way. If two storables have the same order, undefined behavior.
	},
	Corporeal = {
		instance = {},
	}, -- does it have a physical form? (Some instances aren't corporeal)
}


return ComponentInfo