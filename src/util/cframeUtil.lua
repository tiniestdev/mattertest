--[[

OCFrame.getRotatedCFAroundPoint(targetCF, pivotCF, axis, r)
OCFrame.transformCFAroundPivot(targetCF, pivotCF, transCF)
OCFrame.getCFLookingAtPoint(basePos, targetPos)
OCFrame.getCFrameToPosition(cframe, pos)
OCFrame.getMatchingRelativeCF(rootCF, rootCFRef, partCFRef)

OCFrame.getTopCenterPoint(part)
OCFrame.getBotCenterPoint(part)
OCFrame.getTopCenterCF(part)
OCFrame.getBotCenterCF(part)

OCFrame.getCAngleFromSSS(a,b,c)
OCFrame.getAAngleFromSSS(a,b,c)
OCFrame.getBAngleFromSSS(a,b,c)

OCFrame.getAngleBetweenVectors(a, b)
OCFrame.getAngularVelocityFromPoses(cf1, cf2, elapsed)
OCFrame.getVelocityFromPoses(cf1, cf2, elapsed)

]]

local OCFrame = {}

function OCFrame.getRotatedCFAroundPoint(targetCF, pivotCF, axis, r)
	local offset = pivotCF:ToObjectSpace(targetCF)
	local rotatedPivotCF = pivotCF * CFrame.fromAxisAngle(axis, r)
	local newCF = rotatedPivotCF:ToWorldSpace(offset)
	return newCF
end

function OCFrame.transformCFAroundPivot(targetCF, pivotCF, transCF)
	local offset = pivotCF:ToObjectSpace(targetCF)
	local transformedPivot = pivotCF * transCF
	local newCF = transformedPivot:ToWorldSpace(offset)
	return newCF
end

function OCFrame.getCFLookingAtPoint(basePos, targetPos)
	local newCF = CFrame.new(basePos)

	local t_Point_in_Object_Perspective = newCF:PointToObjectSpace(targetPos)
	local t_Pos_Z = -t_Point_in_Object_Perspective.z
	local t_Pos_X = t_Point_in_Object_Perspective.x
	local angle = math.atan2(t_Pos_Z, t_Pos_X)
	local angleChange = (math.pi / 2) - angle

	newCF = newCF * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -angleChange)

	t_Point_in_Object_Perspective = newCF:PointToObjectSpace(targetPos)
	t_Pos_Z = -t_Point_in_Object_Perspective.Z
	local t_Pos_Y = t_Point_in_Object_Perspective.Y
	angle = math.atan2(t_Pos_Y, t_Pos_Z)

	newCF = newCF * CFrame.fromAxisAngle(Vector3.new(1, 0, 0), angle)
	return newCF
end

function OCFrame.getCFrameToPosition(cframe, pos)
	return CFrame.fromMatrix(pos, cframe.RightVector, cframe.UpVector)
end

--[[
	getMatchingRelativeCF
	rootRef and partRef must be known,
	partRef's relative-to-rootRef CFrame will be applied to the
	root cframe to get a matching relationship
	(like animbody relation positions to use for puppet relation positions)
]]
function OCFrame.getMatchingRelativeCF(rootCF, rootCFRef, partCFRef)
	return rootCF:ToWorldSpace(rootCFRef:ToObjectSpace(partCFRef))
end

function OCFrame.getTopCenterPoint(part)
	return part.CFrame:PointToWorldSpace(Vector3.new(0, part.Size.Y / 2, 0))
end
function OCFrame.getBotCenterPoint(part)
	return part.CFrame:PointToWorldSpace(Vector3.new(0, -part.Size.Y / 2, 0))
end
function OCFrame.getTopCenterCF(part)
	return part.CFrame:ToWorldSpace(CFrame.new(0, part.Size.Y / 2, 0))
end
function OCFrame.getBotCenterCF(part)
	return part.CFrame:ToWorldSpace(CFrame.new(0, -part.Size.Y / 2, 0))
end

function OCFrame.getCAngleFromSSS(a, b, c)
	local cosine_of_angle = (a ^ 2 + b ^ 2 - c ^ 2) / (2 * a * b)
	local angle = math.acos(math.clamp(cosine_of_angle, -1, 1))
	return angle
end

function OCFrame.getAAngleFromSSS(a, b, c)
	local cosine_of_angle = (b ^ 2 + c ^ 2 - a ^ 2) / (2 * b * c)
	local angle = math.acos(math.clamp(cosine_of_angle, -1, 1))
	return angle
end

function OCFrame.getBAngleFromSSS(a, b, c)
	local cosine_of_angle = (c ^ 2 + a ^ 2 - b ^ 2) / (2 * c * a)
	local angle = math.acos(math.clamp(cosine_of_angle, -1, 1))
	return angle
end

function OCFrame.getAngleBetweenVectors(a, b)
	return math.atan2(a:Cross(b).magnitude, a:Dot(b))
	--[[
	if a.Magnitude <= 0 or b.Magnitude <= 0 then
		return 0
	end
	local angle = math.acos(a:Dot(b)/(a.Magnitude * b.Magnitude));
	if angle ~= angle then
		-- this is a NAN thing
		return 0
	end
	angle = math.clamp(angle, 0, math.pi)
	return angle]]
end

function OCFrame.getAngularVelocityFromPoses(cf1, cf2, elapsed)
	local refcf2 = cf1:ToObjectSpace(cf2)
	local dx, dy, dz = refcf2:ToOrientation()
	return Vector3.new(dx, dy, dz) / elapsed
	-- I added the * elapsed here cause at first it was literally just Vector3.new(dx, dy, dz).
	-- If it's too weak, just multiply it by some factor or somefin
end

function OCFrame.getVelocityFromPoses(cf1, cf2, elapsed)
	return (cf2.Position - cf1.Position) / elapsed
end

return OCFrame
