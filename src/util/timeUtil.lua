local timeUtil = {}

-- Checks how long it's been since the last time the function was called with the same id.
-- The first time the function is called, it starts a timer and returns true.
-- The initBlocked parameter is used to ensure the first call is blocked instead of returning true immediately.

timeUtil.debounceTimers = {}

timeUtil.getTick = function()
    return tick()
end

timeUtil.getDebounce = function(id, duration, initBlocked)
    local lastTime = timeUtil.debounceTimers[id]
    local currTime = timeUtil.getTick()

    if lastTime then
        local elapsedTime = currTime - lastTime
        if elapsedTime < duration then
            return false
        else
            timeUtil.debounceTimers[id] = currTime
            return true
        end
    else
        timeUtil.debounceTimers[id] = currTime
        if initBlocked then
            return false
        else
            return true
        end
    end
end

return timeUtil