local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.Packages.matter)

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

local CLIENTCOMPONENTS = {
	InToolbar = {},
	Ours = {},
}

local SERVERCOMPONENTS = {

}

local COMPONENTS = {
	Replicated = {
		serverId = { },
		scope = {},
		identifier = {},
	},
	ServerReplicated = {
		serverId = { }
	},

	Instance = {
		instance = { }
	},
	Flammable = {

	},

	-- Basepart stuff
	Physics = {

	},
	Transform = {

	},

	-- Applied to objects associated with a certain team or alliance.
	Teamed = {
		teamId = {},
	},

	-- Actual entities of teams and groups
	Team = {

	},
	Alliance = {

	},

	Player = {
		player = {},
		characterId = {},
	},
	Character = {
		playerId = {},
	},
	Health = {
		health = {},
		maxHealth = {},
	},
	Storage = {
		storableIds = {},
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
		equippableId = {},
	},
	Equippable = {
		presetName = {}, -- string key to lookup in Tools
		droppable = {}, -- can this be dropped by a player?????
		transferrable = {}, -- can it have a new owner other than the world/player
		equipperId = {}, -- is nil if not equipped
		hotkey = {}, --CLIENT
	},
	Storable = { -- Should be able to be transferred between storages
		displayName = {},
		displayIcon = {},
		storageId = {},
		size = {},
		order = {},  -- integer used to sort it in a consistent way. If two storables have the same order, undefined behavior.
	},
	Corporeal = {
		instance = {},
	}, -- does it have a physical form? (Some instances aren't corporeal)
}

local components = {}

if RunService:IsServer() then
	for name, info in pairs(SERVERCOMPONENTS) do
		components[name] = Matter.component(name)
	end
else
	for name, info in pairs(CLIENTCOMPONENTS) do
		components[name] = Matter.component(name)
	end
end

for name, info in pairs(COMPONENTS) do
	components[name] = Matter.component(name)
	--print("Made component of name ", name, ": ", components[name])
end


return components

