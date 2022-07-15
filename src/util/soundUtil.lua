--[[

Sound: a library for quick and easy sound-related utilities
tiniestman 1/3/2021

just renamed to fit naming convention LOULW. LOAWL LAL
7/6/2022

]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local soundUtil = {}
local Sounds = ReplicatedStorage.Assets.Sounds
if not Sounds then
    warn("There are no \"Sounds\" folder in ReplicatedStorage!")
end
local SoundsMap = {}
for _, sound in ipairs(Sounds:GetChildren()) do
    SoundsMap[sound.Name] = sound
end
soundUtil.DefaultGroup = Instance.new("SoundGroup")

soundUtil.soundCategories = {
    Dirt = {
        "bulletHitDirt",
        "bulletHitDirt2",
        "bulletHitDirt3",
    },
    Ground = {
        "bulletHitGround",
        "bulletHitGround2",
        "bulletHitGround3",
    },
    Metal = {
        "bulletHitMetal",
        "bulletHitMetal2",
        "bulletHitMetal3",
    },
    Flesh = {
        "bulletHitFlesh",
        "bulletHitFlesh2",
    },
    Hit = {
        "bodyHit",
        "bodyHit2",
        "bodyHit3",
        "bodyHit4",
    },
    HeavyHit = {
        "heavyHit",
        "heavyHit1",
        "heavyHit2",
        "heavyHit3",
        "heavyHit4",
        "heavyHit5",
    },
    Death = {
        "death",
        "death2",
        "death3",
    },
}

soundUtil.materialMap = {
    [Enum.Material.Sand] = soundUtil.soundCategories["Dirt"],
    [Enum.Material.Grass] = soundUtil.soundCategories["Dirt"],
    [Enum.Material.Snow] = soundUtil.soundCategories["Dirt"],

    [Enum.Material.Plastic] = soundUtil.soundCategories["Ground"],
    [Enum.Material.Concrete] = soundUtil.soundCategories["Ground"],
    [Enum.Material.Marble] = soundUtil.soundCategories["Ground"],

    [Enum.Material.Metal] = soundUtil.soundCategories["Metal"],
    [Enum.Material.CorrodedMetal] = soundUtil.soundCategories["Metal"],
    [Enum.Material.DiamondPlate] = soundUtil.soundCategories["Metal"],
}

-- used to get a new sound from an existing sound object or a name to look up
-- also applies whatever's in the config table (these are multipliers, not absolute numbers)
-- also this sound automatically cleans itself up if it's not looped

-- config keys = Looped, Volume, PlaybackSpeed, StartPosition, EndPosition,
function soundUtil.AssertSoundsFolder()
	assert(Sounds ~= nil, "Sounds module has no sound directory!")
end

function soundUtil.SetSoundsFolder(folder)
	Sounds = folder
end

function soundUtil.GetNewSoundWithConfig(identifier, config)
	if not identifier then warn("No sound identifier provided") return end
	if not config then config = {} end
	soundUtil.AssertSoundsFolder()
	
	local newSound
	local selectedSound --need a reference to original's properties since newSound's may be 0 or somethin weird
	if typeof(identifier) == "string" then
		selectedSound = SoundsMap[identifier]
		if not selectedSound then warn("Cannot find sound ", identifier) return end
		newSound = selectedSound:Clone()
	end
	if typeof(identifier) == "Instance" and identifier:IsA("Sound") then
		selectedSound = identifier
		newSound = identifier:Clone()
	end
	if not newSound then
		warn("Could not convert sound identifier ", identifier)
	end
	
	--apply config
	newSound.SoundGroup = config.SoundGroup or soundUtil.DefaultGroup
	newSound.PlayOnRemove = false
	newSound.Looped = (config.Looped ~= nil and config.Looped) or selectedSound.Looped
	newSound.Volume = selectedSound.Volume * (config.Volume or 1)
	newSound.PlaybackSpeed = selectedSound.PlaybackSpeed * (config.PlaybackSpeed or 1)
	newSound.TimePosition = config.StartPosition or 0
	
	if not newSound.Looped then
		task.delay(config.EndPosition or selectedSound.TimeLength, function()
			selectedSound:Destroy()
		end)
	end
	
	return newSound
end

function soundUtil.PlaySound(identifier, config)
	local newSound = soundUtil.GetNewSoundWithConfig(identifier, config)
	if not newSound then return end
	SoundService:PlayLocalSound(newSound)
end

function soundUtil.PlaySoundAtPos(identifier, position, config)
	local newSound = soundUtil.GetNewSoundWithConfig(identifier, config)
	if not newSound then return end
	local soundAttachment = Instance.new("Attachment")
	soundAttachment.Parent = workspace.Terrain
	soundAttachment.CFrame = CFrame.new(position)

	newSound.Parent = soundAttachment
	newSound:Play()
	
	local changeListener
	changeListener = newSound.Changed:Connect(function()
		task.delay(newSound.TimeLength, function()
			soundAttachment:Destroy()
			newSound:Destroy()
		end)
		changeListener:Disconnect()
	end)
	task.delay(5, function()
		if soundAttachment.Parent then
			soundAttachment:Destroy()
			newSound:Destroy()
		end
	end)
end

function soundUtil.PlaySoundInObject(identifier, object, config)
	local newSound = soundUtil.GetNewSoundWithConfig(identifier, config)
	if not newSound then return end
	newSound.Parent = object
	newSound:Play()
end

return soundUtil
