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

local COMPONENTS = {
	Replicated = {
		serverId = { }
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

	},

	-- Actual entities of teams and groups
	Team = {

	},
	Alliance = {

	},

	Player = {

	},
	Character = {

	},
	Health = {

	},
	Storage = {

	},
	Walkspeed = {

	},

	HoldForce = {

	},
	HoldForceClient = {

	},
	Holdable = {

	},

	Tool = {

	},
	Storable = {

	},
	Corporeal = {

	}, -- does it have a physical form? (Some instances aren't corporeal)
}

local components = {}
for name, info in pairs(COMPONENTS) do
	components[name] = Matter.component(name)
	--print("Made component of name ", name, ": ", components[name])
end
return components

