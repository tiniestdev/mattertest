return {
	Name = "checkGamepass";
	Aliases = {};
	Description = "Checks if the target player has a gamepass";
	Group = "Admin";
	Args = {
		{
			Type = "player";
			Name = "target";
			Description = "Player to check";
		},
		{
			Type = "integer";
			Name = "passId";
			Description = "The numerical ID of the gamepass";
		}
	};
}
