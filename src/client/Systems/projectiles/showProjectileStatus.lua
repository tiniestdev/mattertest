local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Remotes = require(ReplicatedStorage.Remotes)
local Matter = require(ReplicatedStorage.Packages.matter)
local Plasma = require(ReplicatedStorage.Packages.plasma)

local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local randUtil = require(ReplicatedStorage.Util.randUtil)

return function(world, _, ui)
    if not ui.checkbox("Show projectiles"):checked() then return end
    for id, projC in world:query(Components.Projectile) do

        local function renderProj(cframe, projC, id)
            ui.portal(workspace, function()
                local part = Plasma.useInstance(function()
                    local part = Instance.new("Part")
                    part.Anchored = true
                    part.Size = Vector3.new(0.1, 0.1, 0.1)
                    part.Color = randUtil.color()
                    part.CFrame = cframe
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(8, 100, 4, 50)
                    billboard.Adornee = part
                    billboard.Parent = part
                    local label = Instance.new("TextLabel")
                    label.Text = tableUtil.ToString(projC, id)
                    label.Parent = billboard
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 1, 0)
                    
                    return part
                end)
                part.CFrame = cframe
            end)
        end
        if not projC.dead then
            renderProj(projC.cframe, projC, id)
        end
    end
end