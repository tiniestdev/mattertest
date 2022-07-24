local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.promise) 
local Remotes = require(ReplicatedStorage.Remotes)
local Intercom = require(ReplicatedStorage.Intercom)

local ResetLogic = {}

ResetLogic.AxisName = "ResetLogicAxis"

function ResetLogic:AxisPrepare()
    -- print("ResetLogic: Axis prepare")
end

function ResetLogic:AxisStarted()
    -- print("ResetLogic: Axis started")

    local resetBindable = Instance.new("BindableEvent")
    resetBindable.Event:Connect(function()
        Remotes.Client:Get("RequestRespawn"):SendToServer()
    end)
    
    Promise.retryWithDelay(function()
        local success = pcall(function()
            StarterGui:SetCore("ResetButtonCallback", resetBindable)
        end)
        if success then 
            return Promise.resolve()
        else
            return Promise.reject()
        end 
    end, 20, 1)
end

return ResetLogic
