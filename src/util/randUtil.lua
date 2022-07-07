local randUtil = {}
local RDM = Random.new()

function randUtil.getChance(chance)
    return RDM:NextNumber() < chance
end

function randUtil.getNum(min, max)
    if min and max then
        return RDM:NextNumber(min, max)
    else
        return RDM:NextNumber()
    end
end

function randUtil.chooseFrom(tab)
    return tab[RDM:NextInteger(1, #tab)]
end

return randUtil