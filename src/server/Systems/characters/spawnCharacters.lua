local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.components)
local Matter = require(ReplicatedStorage.Packages.matter)
local Llama = require(ReplicatedStorage.Packages.llama)
local matterUtil = require(ReplicatedStorage.Util.matterUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)
local ragdollUtil = require(ReplicatedStorage.Util.ragdollUtil)
local Remotes = require(ReplicatedStorage.Remotes)
local Rx = require(ReplicatedStorage.Packages.rx)

local Assets = ReplicatedStorage.Assets

local Teams = require(ReplicatedStorage.Teams)
local Constants = require(ReplicatedStorage.Constants)
local TeamUtil = require(ReplicatedStorage.Util.teamUtil)
local PlayerUtil = require(ReplicatedStorage.Util.playerUtil)
local toolUtil = require(ReplicatedStorage.Util.toolUtil)
local ToolInfos = require(ReplicatedStorage.ToolInfos)
local replicationUtil = require(ReplicatedStorage.Util.replicationUtil)
local physicsUtil = require(ReplicatedStorage.Util.physicsUtil)


local CharacterEvent = matterUtil.ObservableToEvent(PlayerUtil.getCharactersObservable())

return function(world)
    for _, character in Matter.useEvent(CharacterEvent, "Event") do
        local player = Players:GetPlayerFromCharacter(character)
        local playerEntityId = matterUtil.getEntityId(player)
        local playerC = world:get(playerEntityId, Components.Player)

        local startingTools = toolUtil.makePresetTools({
            "Iron",
            "Apple",
        }, world)

        local hum = character:WaitForChild("Humanoid")
        hum.BreakJointsOnDeath = false
        hum.RequiresNeck = false

        local grabberAtt = Instance.new("Attachment")
        grabberAtt.Name = "Grabber"
        local grabberFX = Assets.Particles.GrabberFX:Clone()
        grabberFX.Parent = grabberAtt
        grabberFX.Enabled = false
        grabberAtt.Parent = character:WaitForChild("Head")

        local charEntityId = world:spawn(
            Components.ReplicateToClient({
                archetypes = {"CharacterArchetype"}
            }),
            Components.Instance({
                instance = character,
            }),
            Components.Character({
                playerId = playerEntityId,
            }),
            Components.Skeleton({}),
            Components.Ragdollable({
                downed = false,
                stunned = false,
                sleeping = false,
            }),
            Components.Health({
                health = 100,
                maxHealth = 100,
            }),
            Components.Storage({
                storableIds = Llama.List.toSet(startingTools),
                capacity = 0,
                maxCapacity = 10,
            }),
            Components.Equipper({
                equippableId = nil,
            }),
            Components.Grabber({
                grabbableId = nil,
                attachmentInstance = grabberAtt,
                grabbableAttachmentInstance = nil,
                grabberOffset = Vector3.new(0,0,0),
            }),
            Components.Walkspeed({
                walkspeed = 16,
            }),
            Components.Teamed({
                teamId = world:get(playerEntityId, Components.Teamed).teamId,
            })
        )

        world:insert(playerEntityId, playerC:patch({
            characterId = charEntityId,
        }))
        print("Player ID " .. playerEntityId .. " has character ID " .. charEntityId)
        matterUtil.setEntityId(character, charEntityId)
    end
end


