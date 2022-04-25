local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tableUtil = require(ReplicatedStorage.Util.tableUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)
local Constants = require(ReplicatedStorage.Constants)
local Components = require(ReplicatedStorage.components)
local ragdollUtil = {}

ragdollUtil.RegularLimb_To_SkeletonLimb = {
    ["Left Arm"] = "Arm_L";
    ["Left Leg"] = "Leg_L";
    ["Right Arm"] = "Arm_R";
    ["Right Leg"] = "Leg_R";
    ["Torso"] = "Torso";
    ["Head"] = "Head";
}

local R6_MOTOR6DS = {
	{"Neck", "Torso"},
	{"Left Shoulder", "Torso"},
	{"Right Shoulder", "Torso"},
	{"Left Hip", "Torso"},
	{"Right Hip", "Torso"},
}

local function getMotorSet(model, motorSet)
	local motors = {}

	-- Disable all regular joints:
	for _, params in pairs(motorSet) do
		local part = model:FindFirstChild(params[2])
		if part then
			local motor = part:FindFirstChild(params[1])
			if motor and motor:IsA("Motor6D") then
				table.insert(motors, motor)
			end
		end
	end

	return motors
end

ragdollUtil.getMotors = function(model)
	-- Note: We intentionally do not disable the root joint so that the mechanism root of the
	-- character stays consistent when we break joints on the client. This avoid the need for the client to wait
	-- for re-assignment of network ownership of a new mechanism, which creates a visible hitch.
	local motors
    motors = getMotorSet(model, R6_MOTOR6DS)
	return motors
end

ragdollUtil.SkeletonLimb_To_RegularLimb = tableUtil.Flip(ragdollUtil.RegularLimb_To_SkeletonLimb)

ragdollUtil.initSkeleton = function(character)
    local newSkeleton = ReplicatedStorage.Assets.Models.Skeleton:Clone()
    newSkeleton.Parent = workspace
    local charTorso = character:WaitForChild("Torso", 3)
    if not charTorso then error("No torso found") end
    newSkeleton:SetPrimaryPartCFrame(charTorso.CFrame)

    for _, skeletonLimb in ipairs(physicsUtil.GetParts(newSkeleton))do
        local regularLimbName = ragdollUtil.SkeletonLimb_To_RegularLimb[skeletonLimb.Name]
        local foundRegularLimb = character:FindFirstChild(regularLimbName)
        if foundRegularLimb then
            skeletonLimb.CFrame = foundRegularLimb.CFrame
        else
           warn("could not find regular limb "..regularLimbName)
        end
        skeletonLimb.Massless = true
        skeletonLimb.Anchored = false
    end

    for _, skeletonLimb in ipairs(physicsUtil.GetParts(newSkeleton))do
        local regularLimbName = ragdollUtil.SkeletonLimb_To_RegularLimb[skeletonLimb.Name]
        local foundRegularLimb = character:FindFirstChild(regularLimbName)
        if foundRegularLimb then
            physicsUtil.weldPartsStrong(skeletonLimb, foundRegularLimb)
        end
    end

    physicsUtil.DeepTask(character, function(part)
        if part.Name == "HumanoidRootPart" then
            PhysicsService:SetPartCollisionGroup(part, Constants.CollisionNames.HRP)
        else
            PhysicsService:SetPartCollisionGroup(part, Constants.CollisionNames.CHAR)
        end
    end)

    return newSkeleton
end






ragdollUtil.Ragdoll = function(char, skeleton)
    if not skeleton then warn("Character has no skeleton to unragdoll") return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("Torso")
    local humanoid = char:FindFirstChild("Humanoid")
	local animator = humanoid:FindFirstChildWhichIsA("Animator")

    if hrp and torso then
        local hrpWeld = physicsUtil.weldPartsExact(hrp, torso)
        hrpWeld.Name = "RagdollHRPWeld"
    else
        warn("Character does not have a torso or HRP")
        return
    end

    ragdollUtil.DisableAnimationJoints(char)
    ragdollUtil.EnableSkeletonJoints(skeleton)

    local hum = char:FindFirstChild("Humanoid")
    if hum then ragdollUtil.DisableHumanoid(hum) end
	if animator then
		animator:ApplyJointVelocities(ragdollUtil.getMotors(char))
	end

    physicsUtil.DeepSetCollisionGroup(char, Constants.CollisionNames.RAGDOLL)
    physicsUtil.DeepSetCanCollide(skeleton, true)
    physicsUtil.DeepSetCanCollide(char, false)

    -- Maintain momentum at time of ragdoll
    -- this block of code doesn't work, but i might bother to make it work in the future
    --[[
    local currentForces = {}
    for regularLimbName, skeletonLimbName in pairs(ragdollUtil.RegularLimb_To_SkeletonLimb) do
        local regularLimb = char:FindFirstChild(regularLimbName)
        local skeletonLimb = skeleton:FindFirstChild(skeletonLimbName)
        skeletonLimb.AssemblyLinearVelocity = regularLimb.AssemblyLinearVelocity
        skeletonLimb.AssemblyAngularVelocity = regularLimb.AssemblyAngularVelocity
    end
    ]]
    local assemblyVel = torso.AssemblyLinearVelocity
    local assemblyRotVel = torso.AssemblyAngularVelocity
    skeleton.Torso.AssemblyLinearVelocity = assemblyVel
    skeleton.Torso.AssemblyAngularVelocity = assemblyRotVel

    -- Cleanup for when unragdolling
    -- local skeletonTorso = skeleton:FindFirstChild("Torso")
    -- if skeletonTorso then
    --     local carryPrompt = skeletonTorso:FindFirstChild("CarryPrompt")
    --     if carryPrompt then
    --         carryPrompt.Enabled = true
    --     else
    --         warn("no carryPrompt found in torso of ", char)
    --     end
    -- end
end

ragdollUtil.Unragdoll = function(char, skeleton)
    --if not skeleton then warn("Character has no skeleton to unragdoll") return end
    -- local skeleton = char:FindFirstChild("Skeleton") and char.Skeleton.Value
    if not skeleton then warn("Character has no skeleton to unragdoll") return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hrpWeld = hrp and hrp:FindFirstChild("RagdollHRPWeld")
    if hrp and hrpWeld then
        hrpWeld:Destroy()
    end

    ragdollUtil.EnableAnimationJoints(char)
    ragdollUtil.DisableSkeletonJoints(skeleton)

    local hum = char:FindFirstChild("Humanoid")
    if hum then ragdollUtil.EnableHumanoid(hum) end

    physicsUtil.DeepSetCollisionGroup(char, Constants.CollisionNames.CHAR)
    physicsUtil.DeepSetCanCollide(skeleton, false)
    physicsUtil.DeepSetCanCollide(char, true)

    -- local skeletonTorso = skeleton:FindFirstChild("Torso")
    -- if skeletonTorso then
    --     local carryPrompt = skeletonTorso:FindFirstChild("CarryPrompt")
    --     if carryPrompt then
    --         carryPrompt.Enabled = false
    --     else
    --         warn("no carryPrompt found in torso of ", char)
    --     end
    -- end
end

ragdollUtil.DisableAnimationJoints = function(char)
    for i,v in ipairs(char:GetDescendants())do
        if v:IsA("Motor6D") then
            v.Enabled = false
        end
    end
end

ragdollUtil.EnableAnimationJoints = function(char)
    for i,v in ipairs(char:GetDescendants())do
        if v:IsA("Motor6D") then
            v.Enabled = true
        end
    end
end

ragdollUtil.DisableSkeletonJoints = function(skeleton)
    for i,v in ipairs(skeleton:GetDescendants())do
        if v:IsA("Constraint") then
            v.Enabled = false
        end
    end
end

ragdollUtil.EnableSkeletonJoints = function(skeleton)
    for i,v in ipairs(skeleton:GetDescendants())do
        if v:IsA("Constraint") then
            v.Enabled = true
        end
    end
end

ragdollUtil.DisableHumanoid = function(hum)
    hum.PlatformStand = true
    hum.AutoRotate = false
    hum.AutoJumpEnabled = false
    for enumID, enum in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if enum.Name ~= "None" and enum.Name ~= "Physics" and enum.Name ~= "Dead" then
            hum:SetStateEnabled(Enum.HumanoidStateType[enum.Name], false)
        end
    end
    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end

ragdollUtil.EnableHumanoid = function(hum)
    hum.PlatformStand = false
    hum.AutoRotate = true
    hum.AutoJumpEnabled = true
    for enumID, enum in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if enum.Name ~= "None" then
            hum:SetStateEnabled(Enum.HumanoidStateType[enum.Name], true)
        end
    end
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
end



ragdollUtil.shouldBeRagdolled = function(state)
    return state.downed or state.stunned or state.sleeping
end

ragdollUtil.shouldBeDowned = function(entityId, world)
    local healthC = world:get(entityId, Components.Health)
    -- this won't down someone if they have nil health O_O
    return healthC.health and healthC.health <= Constants.Ragdoll.DOWNED_HEALTH
end


return ragdollUtil