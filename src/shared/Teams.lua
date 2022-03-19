local Teams = {}

Teams.Alliances = {
    Attackers = {},
    Defenders = {},
    Neutral = {},
}

Teams.Teams = {
    Raiders = {
        allianceName = "Attackers",
        color = Color3.new(1, 0.254901, 0.254901),
        autoAssignable = true,
    },
    Guards = {
        allianceName = "Defenders",
        color = Color3.new(0, 0.549019, 1),
        autoAssignable = true,
    },
    Officials = {
        allianceName = "Neutral",
        color = Color3.new(1, 1, 1),
    },
}

-- should be filled in by server and client separately
Teams.NameToId = {}
Teams.IdToName = {}
Teams.IdToInfo = {}

return Teams