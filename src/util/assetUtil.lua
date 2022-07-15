local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets
local randUtil = require(ReplicatedStorage.Util.randUtil)
local assetUtil = {}

local images = {}

local imageCategories = {
    Splatters = {
        "splatter",
        "splatter2",
    },
    LightSplatters = {
        "splatterLight",
        "splatterLight2",
        "splatterLight3",
    },
    SplatterDrops = {
        "splatterDrops",
        "splatterDrops2",
    },
}

function assetUtil.getImage(name)
    if images[name] then
        return images[name]
    else
        local found = Assets.Images:FindFirstChild(name)
        if not found then error("nothing found for image " .. name) end
        images[name] = found
        return found
    end
end

function assetUtil.getRandomImageFromCategory(categoryName)
    local category = imageCategories[categoryName]
    if not category then error("no category found for " .. categoryName) end
    return assetUtil.getImage(randUtil.chooseFrom(category))
end

return assetUtil