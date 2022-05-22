--- Debug drawing library useful for debugging 3D abstractions
-- think i stole this from Quenty's nevermore n modded it

--[[

Draw.point(vector3, color, parent, diameter, key)
Draw.vector(key, startPos, vector, color, parent, meshDiameter, diameter)
Draw.cframe(key, startPos, cframe, color, parent, diameter)

]]

-- @module Draw
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Draw = {}
Draw._defaultColor = Color3.new(1, 0, 0)

--- Sets the Draw's drawing color
-- @tparam {Color3} color The color to set
function Draw.setColor(color)
	Draw._defaultColor = color
end

--- Sets the Draw library to use a random color
function Draw.setRandomColor()
	Draw.setColor(Color3.fromHSV(math.random(), 0.5+0.5*math.random(), 1))
end

--- Draws a ray for debugging
-- @param ray The ray to Draw
-- @tparam[opt] {color3} color The color to Draw in
-- @tparam[opt] {Instance} parent
-- @tparam[opt] {number} diameter
-- @tparam[opt] {number} meshDiameter
function Draw.ray(ray, color, parent, meshDiameter, diameter)
	color = color or Draw._defaultColor
	parent = parent or Draw._getDefaultParent()
	meshDiameter = meshDiameter or 0.2
    diameter = diameter or 0.2
    
	local rayCenter = ray.Origin + ray.Direction/2

	local part = Instance.new("Part")
	part.Anchored = true
	part.Archivable = false
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CFrame = CFrame.new(rayCenter, ray.Origin + ray.Direction) * CFrame.Angles(math.pi/2, 0, 0)
	part.Color = color
	part.Name = "DebugRay"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(1 * diameter, ray.Direction.Magnitude, 1 * diameter)
	part.TopSurface = Enum.SurfaceType.Smooth
    part.Transparency = 0.5

	local mesh = Instance.new("SpecialMesh")
	mesh.Scale = Vector3.new(0, 1, 0) + Vector3.new(meshDiameter, 0, meshDiameter) / diameter
	mesh.Parent = part

    part.Parent = parent
    return part
end

--- Draws a point for debugging
-- @tparam {Vector3} vector3 Point to Draw
-- @tparam[opt] {color3} color The color to Draw in
-- @tparam[opt] {Instance} parent
-- @tparam[opt] {number} diameter
function Draw.point(position, color, parent, diameter)
	assert(position, "no vector3")
	if typeof(position) == "CFrame" then
		position = position.Position
	end

	color = color or Draw._defaultColor
	parent = parent or Draw._getDefaultParent()
	diameter = diameter or 1

	local part = Instance.new("Part")
	part.Anchored = true
	part.Archivable = false
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CFrame = CFrame.new(position)
	part.Color = color
	part.Name = "DebugPoint"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(diameter, diameter, diameter)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Transparency = 0.5

	local sphereHandle = Instance.new("SphereHandleAdornment")
	sphereHandle.Archivable = false
	sphereHandle.Radius = diameter/4
	sphereHandle.Color3 = color
	sphereHandle.AlwaysOnTop = true
	sphereHandle.Adornee = part
	sphereHandle.ZIndex = 1
	sphereHandle.Parent = part

	part.Parent = parent
	return part	
end

--- Draws a unit arrow
-- @param ray The ray to Draw
-- @tparam[opt] {color3} color The color to Draw in
-- @tparam[opt] {Instance} parent
-- @tparam[opt] {number} diameter
-- @tparam[opt] {number} meshDiameter
function Draw.vector(startPos, vector, color, parent, meshDiameter, diameter)
	
	meshDiameter = meshDiameter or 0.2
    diameter = diameter or 0.2
    
	local VectorRay = Ray.new(startPos, vector)
	local part = Draw.ray(VectorRay, color, parent, meshDiameter, diameter)
	local head = Draw.point(startPos + vector, color, part, diameter*1.5)

	return part
end

function Draw.cframe(key, startPos, cframe, color, parent, diameter)

    -- local drawMaid = Maid.new()
	-- drawMaid:GiveTask(Draw.vector(startPos or cframe.Position, cframe.UpVector, color, parent, diameter, diameter))
	-- drawMaid:GiveTask(Draw.vector(startPos or cframe.Position, cframe.RightVector, color, parent, diameter, diameter))
	-- drawMaid:GiveTask(Draw.vector(startPos or cframe.Position, cframe.LookVector, color, parent, diameter, diameter))
	
	-- return drawMaid
end

function Draw.box(cframe, size, color)
	color = color or Draw._defaultColor
	cframe = typeof(cframe) == "Vector3" and CFrame.new(cframe) or cframe

	local part = Instance.new("Part")
	part.Color = color
	part.Name = "DebugPart"
	part.Anchored = true
	part.CanCollide = false
	part.Archivable = false
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Transparency = 0.5
	part.Size = size
	part.CFrame = cframe
    part.Parent = Draw._getDefaultParent()

	return part
end

function Draw._getDefaultParent()
	return (RunService:IsServer() and Workspace) or Workspace.CurrentCamera
end

return Draw