local MarketplaceService = game:GetService("MarketplaceService")

return function(context, player, passId)
    local success, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.userId, passId)
    end)
    if not success then
        context:Reply("Could not get response:")
        return result
    end

    if result then
        context:Reply("Player owns the gamepass!")
    else
        context:Reply("Player does NOT own the gamepass.")
    end
end