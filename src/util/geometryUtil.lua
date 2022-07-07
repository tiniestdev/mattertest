local geometryUtil = {}

--[[
    envision a capsule like shape
    at its ends are l0 and l1, forming a line - the center of the pill
    it will return the distance from p0 to the center of this pill,
    including distances from the very edge of the pill
]]
function geometryUtil.closestPointOnLine(p0, l0, l1)
    local l0ToPoint = (p0-l0)
    local l1ToPoint = (p0-l1)
    local lineVec = (l1-l0)
	local d0 = (p0 - l0).Magnitude
	local d1 = (p0 - l1).Magnitude

    if l0 == l1 then return l0 end

	local inBetween = l0ToPoint:Dot(lineVec) > 0
                and (l1ToPoint):Dot(-lineVec) > 0

	if inBetween then
		local shadow = l0ToPoint:Dot(lineVec) / lineVec.Magnitude
		return l0 + (lineVec * shadow)
	else
		return d0 < d1 and l0 or l1
	end
end

function geometryUtil.distanceToLine(p0, l0, l1)
    local closestPoint = geometryUtil.closestPointOnLine(p0, l0, l1)
    return (p0 - closestPoint).Magnitude
end

return geometryUtil