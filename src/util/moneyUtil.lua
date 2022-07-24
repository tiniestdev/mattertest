--[[
    A standalone addon that allows any game to have monetization features
    with minimal dependencies
    Just add ProfileService!
    Then after adding all handlers, do moneyUtil.Init()
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local ProfileService = require(ServerScriptService.ServerPackages.profileservice)

local moneyUtil = {}
local PurchaseIdLog = 50 -- Store this amount of purchase id's in MetaTags;
    -- This value must be reasonably big enough so the player would not be able
    -- to purchase products faster than individual purchases can be confirmed.
    -- Anything beyond 30 should be good enough.

local MonetizationTemplate = {
    -- RobuxSpent = 0, -- doesn't work as of now. poo
    Gamepasses = {}, -- a STRING id -> boolean
    ProductAmounts = {}, -- a STRING id -> INT amount of times bought map
}

moneyUtil.ProductHandlers = {} -- a map from STRING id to callback (player, profile) => ()
moneyUtil.GamepassHandlers = {} -- map from STRING id to {Callback = (player, profile)=>(), FirstCallback = (player, profile)=>()}
-- First callback is done for the very first time you buy a product, and callback happens anytime the player who owns it joins or upon buying.
-- Upon FIRST BUY, firstCallback and callback is called.
-- Upon JOINING ANYTIME AFTER THAT, callback is called.

----- Loaded Modules -----

----- Private Variables -----
local GameProfileStore = ProfileService.GetProfileStore(
    "PlayerData",
    MonetizationTemplate
)

local Profiles = {} -- {player = profile, ...}

moneyUtil.setProductCallback = function(id, callback)
    moneyUtil.ProductHandlers[tostring(id)] = callback
end

moneyUtil.setGamepassCallback = function(id, callback, firstCallback)
    moneyUtil.GamepassHandlers[tostring(id)] = {
        Callback = callback,
        FirstCallback = firstCallback,
    }
end

----- Private Functions -----
local function GetPlayerProfileAsync(player) --> [Profile] / nil
    -- Yields until a Profile linked to a player is loaded or the player leaves
    local profile = Profiles[player]
    while profile == nil and player:IsDescendantOf(Players) == true do
        task.wait()
        profile = Profiles[player]
    end
    return profile
end
moneyUtil.GetPlayerProfileAsync = GetPlayerProfileAsync


local function GrantProduct(player, productId)
    productId = tostring(productId)

    local profile = GetPlayerProfileAsync(player)
    local productMap = profile.Data.ProductAmounts
    if not productMap[productId] then
        productMap[productId] = 0
    end
    productMap[productId] = productMap[productId] + 1

    local callback = moneyUtil.ProductHandlers[productId]
    if not callback then
        warn("No callback for product " .. productId)
        return
    end

    task.spawn(function()
        callback(player, profile)
    end)
end


local function GrantGamepass(player, gamepassId, justPurchased)
    gamepassId = tostring(gamepassId)

    local profile = GetPlayerProfileAsync(player)
    local gamepassSet = profile.Data.Gamepasses

    if justPurchased then
        if gamepassSet[gamepassId] then
            -- If they JUST purchased a gamepass they already own..... FAIL!!!!!!!!!!!!!
            warn("Player " .. player.Name .. " already has gamepass " .. gamepassId .. ", mistake?")
            return
        end
        -- profile.Data.RobuxSpent = profile.Data.RobuxSpent + MarketplaceService:GetProductInfo(gamepassId).PriceInRobux
    end
    gamepassSet[gamepassId] = true

    local callbacks = moneyUtil.GamepassHandlers[gamepassId]
    if not callbacks then
        warn("No callbacks for gamepass " .. gamepassId)
        return
    end

    task.spawn(function()
        callbacks.Callback(player, profile)
    end)
    task.spawn(function()
        if justPurchased and callbacks.FirstCallback then
            callbacks.FirstCallback(player, profile)
        end
    end)
end


local function PlayerAdded(player)
    local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick() -- The profile could've been loaded on another Roblox server
        end)
        if not player:IsDescendantOf(Players) then
            profile:Release() -- Player left before the profile loaded
            return
        end
        Profiles[player] = profile

        -- Gamepass handling
        for gamepassId, _ in pairs(profile.Data.Gamepasses) do
            GrantGamepass(player, gamepassId)
        end
    else
        -- The profile couldn't be loaded possibly due to other
        --   Roblox servers trying to load this profile at the same time:
        player:Kick()
    end
end


function PurchaseIdCheckAsync(profile, purchase_id, grant_product_callback) --> Enum.ProductPurchaseDecision
    -- Yields until the purchase_id is confirmed to be saved to the profile or the profile is released
    if profile:IsActive() ~= true then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    else

        local meta_data = profile.MetaData

        local local_purchase_ids = meta_data.MetaTags.ProfilePurchaseIds
        if local_purchase_ids == nil then
            local_purchase_ids = {}
            meta_data.MetaTags.ProfilePurchaseIds = local_purchase_ids
        end

        -- Granting product if not received:
        if table.find(local_purchase_ids, purchase_id) == nil then
            while #local_purchase_ids >= PurchaseIdLog do
                table.remove(local_purchase_ids, 1)
            end
            table.insert(local_purchase_ids, purchase_id)
            task.spawn(grant_product_callback)
        end

        -- Waiting until the purchase is confirmed to be saved:
        local result = nil

        local function check_latest_meta_tags()
            local saved_purchase_ids = meta_data.MetaTagsLatest.ProfilePurchaseIds
            if saved_purchase_ids ~= nil and table.find(saved_purchase_ids, purchase_id) ~= nil then
                result = Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end
        check_latest_meta_tags()

        local meta_tags_connection = profile.MetaTagsUpdated:Connect(function()
            check_latest_meta_tags()
            -- When MetaTagsUpdated fires after profile release:
            if profile:IsActive() == false and result == nil then
                result = Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end)

        while result == nil do
            task.wait()
        end

        meta_tags_connection:Disconnect()

        return result
    end
end


----- Connections -----
MarketplaceService.ProcessReceipt = function(receipt_info)
    local player = Players:GetPlayerByUserId(receipt_info.PlayerId)
    if player == nil then return Enum.ProductPurchaseDecision.NotProcessedYet end

    local profile = GetPlayerProfileAsync(player)
    if profile ~= nil then
        return PurchaseIdCheckAsync(
            profile,
            receipt_info.PurchaseId,
            function()
                GrantProduct(player, receipt_info.ProductId)
            end
        )
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
    if wasPurchased then
        GrantGamepass(player, gamepassId, true)
    end
end)

moneyUtil.Init = function()

    Players.PlayerAdded:Connect(PlayerAdded)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(PlayerAdded, player)
    end
    Players.PlayerRemoving:Connect(function(player)
        local profile = Profiles[player]
        if profile ~= nil then
            profile:Release()
        end
    end)

end

return moneyUtil