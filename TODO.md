ok so i just need to figure out a good way to display debug info about entities and quickly check a player's info
probably like
have a separate billboard display for characters in specific, because they'll have a player associated with them
so on characters, it displays the player entity ids on top of them as well

you know what thats probably good enough

then i need to figure out how equipping stuff works.
on equip, the id should be checked if it's in the player backpack or if it is NOT stored anywhere
(this implies the only time a player CAN'T equip something is if it's inside another storage, but they CAN equip it from the ground (nil) or their backpack)
so it'll remove it from storage and it'll assign to their equippedId

maybe a rule where equippedCannotBeInStorage?

an equipper, because it's not limited to characters (thinking turrets or planes or machinery), must be able to do functions based on:
    * what kind of archetype the equipper wants to be (is a character holding it? or a turret?)
        * entities that fit many archetypes can choose from any one of these and it is implied it has the necessary faculties to equip it in that way
    * how does the tool recieve input? client tools, server tools
        * a gun can be mounted on a turret, and recieve input from the server
        * oh yeah
        * so any tool can have like wire inputs like BAS, and then the equipper must have an interface for using it
        * if an equippable is owned by a client, it will follow a separate client-side logic and interface with the server via remotes
        * if an equippable is owend by a server, it will follow a separate server-side logic natively
        how do i make this modular
        how do i make this compatible with NPCs

        idk, think about it more