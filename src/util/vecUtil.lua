local vecUtil = {}

local RDM = Random.new()

function vecUtil.randomColor()
    return Color3.new(
        RDM:NextNumber(),
        RDM:NextNumber(),
        RDM:NextNumber()
    )
end

function vecUtil.randomVel(noise)
    return Vector3.new(
        RDM:NextNumber(-noise, noise),
        RDM:NextNumber(-noise, noise),
        RDM:NextNumber(-noise, noise)
    )
end


return vecUtil