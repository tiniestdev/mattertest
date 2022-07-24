local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Constants)
local moneyUtil = require(ReplicatedStorage.Util.moneyUtil)

local MoneyStart = {}

MoneyStart.AxisName = "MoneyStartAxis"

function MoneyStart:AxisPrepare()
    workspace.AllowThirdPartySales = true
    moneyUtil.setProductCallback("1288824340", function(player, profile)
        print("Bought product1")
        print(player, profile)
    end)
    moneyUtil.setGamepassCallback("64774398",
        function(player, profile)
            print("Bought gamepass1 for the first time woo")
            print(player, profile)
        end,
        function(player, profile)
            print("Gamepass1 callback")
            print(player, profile)
        end
    )
    moneyUtil.Init()
end

function MoneyStart:AxisStarted()
end

return MoneyStart
