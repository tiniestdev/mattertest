local Llama = require(script.Parent.Parent.Llama)

--[=[
	@class Component

	A component is a named piece of data that exists on an entity.
	Components are created and removed in the [World](/api/World).

	In the docs, the terms "Component" and "ComponentInstance" are used:
	- **"Component"** refers to the base class of a specific type of component you've created.
		This is what [`Matter.component`](/api/Matter#component) returns.
	- **"Component Instance"** refers to an actual piece of data that can exist on an entity.
		The metatable of a component instance table is its respective Component table.

	Component instances are *plain-old data*: they do not contain behaviors or methods.

	Since component instances are immutable, one helper function exists on all component instances, `patch`,
	which allows reusing data from an existing component instance to make up for the ergonomic loss of mutations.
]=]

--[=[
	@within Component
	@type ComponentInstance {}

	The `ComponentInstance` type refers to an actual piece of data that can exist on an entity.
	The metatable of the component instance table is set to its particular Component table.

	A component instance can be created by calling the Component table:

	```lua
	-- Component:
	local MyComponent = Matter.component("My component")

	-- component instance:
	local myComponentInstance = MyComponent({
		some = "data"
	})

	print(getmetatable(myComponentInstance) == MyComponent) --> true
	```
]=]

local function newComponent(name)
	name = name or debug.info(2, "s") .. "@" .. debug.info(2, "l")

	local component = {}
	component.__index = component

	function component.new(data)
		return table.freeze(setmetatable(data or {}, component))
	end

	--[=[
	@within Component

	```lua
	for id, target in world:query(Target) do
		if shouldChangeTarget(target) then
			world:insert(id, target:patch({ -- modify the existing component
				currentTarget = getNewTarget()
			}))
		end
	end
	```

	A utility function used to immutably modify an existing component instance. Key/value pairs from the passed table
	will override those of the existing component instance.

	As all components are immutable and frozen, it is not possible to modify the existing component directly.

	You can use the `Matter.None` constant to remove a value from the component instance:

	```lua
	target:patch({
		currentTarget = Matter.None -- sets currentTarget to nil
	})
	```

	@param partialNewData {} -- The table to be merged with the existing component data.
	@return ComponentInstance -- A copy of the component instance with values from `partialNewData` overriding existing values.
	]=]
	function component:patch(partialNewData)
		debug.profilebegin("patch")
		local patch = getmetatable(self).new(Llama.Dictionary.merge(self, partialNewData))
		debug.profileend()
		return patch
	end

	setmetatable(component, {
		__call = function(_, ...)
			return component.new(...)
		end,
		__tostring = function()
			return name
		end,
	})

	return component
end

return {
	newComponent = newComponent,
}
