local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.Components)

local MatterStart = {}

MatterStart.AxisName = "MatterStartAxis"
MatterStart.World = Matter.World.new()

function MatterStart:AxisPrepare()
    print("MatterStart: Axis prepare")
    MatterStart.MainLoop = Matter.Loop.new(MatterStart.World)
    print("MatterStart: Made Matter World + Loop")
end

function MatterStart:BindInstanceToComponent(instance, component)
    print("Binding instance ", instance, " to component ", component)
	local id = MatterStart.World:spawn(
		component(),
		Components.Instance({
			instance = instance,
		})
	)
	print("Bound instance ", instance, " with component ", component, " and ID ", id)
	instance:SetAttribute("entityId", id)
end

function MatterStart:AxisStarted()
    print("MatterStart: Axis started")

    print("MatterStart: Starting systems...")
    local systems = {}
    for _, systemModule in ipairs(ServerScriptService.Systems:GetChildren()) do
        table.insert(systems, require(systemModule))
    end

    print("MatterStart: Scheduling systems")
    MatterStart.MainLoop:scheduleSystems(systems)
    MatterStart.MainLoop:begin({ default = RunService.Heartbeat })

    print("MatterStart: Binding components from tags")
    for tagName, component in pairs(Components) do
        print("LOOP:", tagName, component)
        for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
            MatterStart:BindInstanceToComponent(instance, component)
        end
    
        CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
            MatterStart:BindInstanceToComponent(instance, component)
        end)
    
        CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
            local id = instance:GetAttribute("entityId")
            if id then
                MatterStart.World:despawn(id)
            end
        end)
    end
end

return MatterStart