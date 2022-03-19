local lockedGroups = {
    DefaultUtil = true,
    DefaultAdmin = true,
    DefaultDebug = true,
}

local admins = {
    [2961438] = true,
}

return function(registry)
    registry:RegisterHook("BeforeRun", function(context)
        if lockedGroups[context.Group] and not admins[context.Executor.UserId] then
            return "Insufficient permissions for userid " .. context.Executor.UserId
        end
    end)
end