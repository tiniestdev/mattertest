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
		attachmentInstance = {};
		grabbableAttachmentInstance = {};
		grabberOffset = {}; -- for a grabber to adjust the offset of the grab point relative to itself, (0,0,0) by default
		-- This property is updated by the grabber (client dictated), but the server should sanitize and sanity check it,
		-- and also won't update at high frequency because a client-owned grab point should be updated super frequently clientside,
		-- so this property wouldn't even matter; and if it were depended on because it's server owned, then this implies
		-- there are contesting grabbers and so grab movement should be fairly slow.
		-- (the origin will be the parent of the attachment instance)
		preferPosition = {}; -- for players who click a specific point on the grabbable part
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