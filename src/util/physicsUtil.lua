local tableUtil = require(script.Parent.tableUtil)
local PhysicsService = game:GetService("PhysicsService")

local physicsUtil = {}

--[[
	GetParts
	Accepts a table, a part, or an instance that has descendants
	Returns a gauranteed table of parts.
--]]
function physicsUtil.GetParts(target)
	--If a table was passed, recursive call on every item it contains
	--(good for tables containing parts/instances as values)
	if typeof(target) == "table"  then
		local parts = {}
		for i,v in ipairs(target)do
			local partsAdd = physicsUtil.GetParts(v)
			tableUtil.Append(parts, partsAdd)
		end
		return parts
	end
	
	--If the target happens to have children, do task on
	--every descendant (and if it's a part, include it)
	if typeof(target) == "Instance" then
		local parts = {}
		local Descendants = target:GetDescendants()
		for _, descendant in ipairs(Descendants) do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
		if target:IsA("BasePart") then
			table.insert(parts, target)
		end
		return parts
	end
	return {}
end

function physicsUtil.GetUnanchoredParts(target)
	--If a table was passed, recursive call on every item it contains
	--(good for tables containing parts/instances as values)
	if typeof(target) == "table"  then
		local parts = {}
		for i,v in ipairs(target)do
			local partsAdd = physicsUtil.GetUnanchoredParts(v)
			tableUtil.Append(parts, partsAdd)
		end
		return parts
	end
	
	--If the target happens to have children, do task on
	--every descendant (and if it's a part, include it)
	if typeof(target) == "Instance" then
		local parts = {}
		local Descendants = target:GetDescendants()
		for _, descendant in ipairs(Descendants) do
			if descendant:IsA("BasePart") and not descendant.Anchored then
				table.insert(parts, descendant)
			end
		end
		if target:IsA("BasePart") and not target.Anchored then
			table.insert(parts, parts)
		end
		return parts
	end
	
	return {}
end

--[[
	DeepTask
	Accepts a table, a part, or an instance that has descendants
	and does a given (function) task on every basepart it contains (and on itself
	if it is also a basepart)
--]]
function physicsUtil.DeepTask(target, taskFunction)
	assert(target, "target is nil")
	assert(typeof(taskFunction) == "function", "taskFunction not a function")
	for i,v in ipairs(physicsUtil.GetParts(target))do
		taskFunction(v)
	end
end

--[[
	DeepSetCollisionGroup
	Accepts a table, a part, or an instance that has descendants
	and sets the collision group of all its consitutients.
--]]
function physicsUtil.DeepSetCollisionGroup(target, collisionGroupName)
	--delegate most work to deep task
	assert(typeof(collisionGroupName) == "string", "collision group name not a string")
	physicsUtil.DeepTask(target, function(part)
		PhysicsService:SetPartCollisionGroup(part, collisionGroupName)
	end)
end

--[[
	DeepSetCollisionGroup
	Accepts a table, a part, or an instance that has descendants
	and sets the collision group of all its consitutients.
--]]
function physicsUtil.DeepSetCanCollide(target, state)
	--delegate most work to deep task
	assert(typeof(state) == "boolean", "state not a boolean")
	physicsUtil.DeepTask(target, function(part)
		part.CanCollide = state
	end)
end

--[[
	DeepSetNoCollisionConstraint
	Accepts a table, a part, or an instance that has descendants.
	Every single part in this will not collide with eachother,
	using NoCollisionConstraints.
--]]
function physicsUtil.DeepSetNoCollisionConstraint(target, state)
	--delegate most work to deep task
	local parts = physicsUtil.GetParts(target)
	if state then
		for i, part1 in ipairs(parts)do
			for i, part2 in ipairs(parts)do
				if part1:CanCollideWith(part2) then
					local NCC = Instance.new("NoCollisionConstraint")
					NCC.Part0 = part1
					NCC.Part1 = part2
					NCC.Enabled = true
					NCC.Parent = part1
				end
			end
		end
	else
		for i, part1 in ipairs(parts)do
			for i, child in ipairs(part1:GetChildren())do
				if child:IsA("NoCollisionConstraint") then
					child:Destroy()
				end
			end
		end
	end
end

--[[
	DeepSetAnchored
	Accepts a table, a part, or an instance that has descendants
	sets anchored to whatever bool is passed
--]]
function physicsUtil.DeepSetAnchored(target, state)
	--delegate most work to deep task
	assert(typeof(state) == "boolean", "state is not a boolean")
	physicsUtil.DeepTask(target, function(part)
		part.Anchored = state
	end)
end

function physicsUtil.DeepSetNetworkOwner(target, owner)
	--delegate most work to deep task
	physicsUtil.DeepTask(target, function(part)
		print(part, part:IsA("BasePart"))
		if part:CanSetNetworkOwnership() then
			part:SetNetworkOwner(owner)
		else
			warn("could not set network owner of ",part:GetFullName())
			print(debug.traceback())
		end
	end)
end

physicsUtil.weldParts = function(part0, part1)
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
    w.C1 = CFrame.new()
    w.Parent = part0

    return w
end

physicsUtil.weldPartsExact = function(part0, part1)
    local w = Instance.new("Weld")
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = CFrame.new()
    w.C1 = CFrame.new()
    w.Parent = part0

    return w
end

physicsUtil.weldPartsStrong = function(part0, part1)
    --experimental, with compatibility with blink
    local w = Instance.new("WeldConstraint")

    local function forceWeld()
        part0.AssemblyLinearVelocity = Vector3.new()
        part0.AssemblyAngularVelocity = Vector3.new()
        part0.CFrame = part1.CFrame
        part0.AssemblyLinearVelocity = Vector3.new()
        part0.AssemblyAngularVelocity = Vector3.new()
        w.Enabled = true
    end

    w.Enabled = false
    w.Part0 = part0
    w.Part1 = part1
    w.Parent = part0
    forceWeld()

    w:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not w.Enabled then
            print("physicsUtil: DETECT WELD CHANGE")
            forceWeld()
        end
    end)

    return w
end

return physicsUtil