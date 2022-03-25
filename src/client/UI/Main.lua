local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Fusion)
local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed

local TeamChoose = require(script.Parent.TeamChoose)
local Sidebar = require(script.Parent.Sidebar)
local Toolbar = require(script.Parent.Toolbar)
local ClearFrame = require(script.Parent.ClearFrame)

return function(props)

    local showTeamChoice = Value(false)

    return ClearFrame {
        Name = "ChoiceFrame";
        [Fusion.Children] = {
            TeamChoose {
                showState = showTeamChoice,
            },
            Sidebar {
                SidebarButtons = {
                    {
                        Text = "CHANGE TEAMS",
                        OnClick = function()
                            showTeamChoice:set(not showTeamChoice:get())
                        end,
                    },
                    {
                        Text = "SHOP",
                        OnClick = function()
                        end,
                        Disabled = true,
                    },
                    {
                        Text = "SETTINGS",
                        OnClick = function()
                        end,
                        Disabled = true,
                    },
                },
                isOpen = false,
            },
            Toolbar {
                storableProps = props.storableProps
            },
        }
    }
end
