local MarketplaceService = game:GetService("MarketplaceService")

return function(context, players, productId)
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(productId)
    end)
    if not success then
        context:Reply("Could not get gamepass:")
        return result
    end

    local productInfo = result
    print("productInfo:", productInfo)

    if productInfo.ProductId then
        -- This is a dev product
        for _, player in ipairs(players) do
            MarketplaceService:PromptProductPurchase(player, productId)
        end
    else
        for _, player in ipairs(players) do
            MarketplaceService:PromptPurchase(player, productId)
        end
    end
end