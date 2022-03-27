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
	CheckArchetype = {
        CLIENTCOMPONENT = true;
        archetypeSet = {};
    },


    -- SHARED COMPONENTS
	Replicated = {
		serverId = {};
		scope = {};
		identifier = {};
	},
	ServerReplicated = {
		serverId = {};
	},

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
	Character = {
		playerId = {
            isReference = true;
            referenceToArchetype = "PlayerArchetype";
        },
	},
	Health = {
		health = {},
		maxHealth = {},
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