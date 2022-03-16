local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Axis = require(ReplicatedStorage.Packages.axis)
local Matter = require(ReplicatedStorage.Packages.matter)

local MatterStart = require(ServerScriptService.Providers.MatterStart)
local Components = require(ReplicatedStorage.Components)

Axis:AddProvider(MatterStart)
Axis:Start()