local MarketplaceService = game:GetService("MarketplaceService")

return function(context, players, passId)
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
    end)
    if not success then
        context:Reply("Could not get gamepass:")
        return result
    end

    local productInfo = result
    print("productInfo:", productInfo)

    for _, player in ipairs(players) do
        MarketplaceService:PromptGamePassPurchase(player, passId)
    end
end