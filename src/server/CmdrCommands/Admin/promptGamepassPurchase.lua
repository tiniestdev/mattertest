return {
	Name = "promptGamepassPurchase";
	Aliases = {"gamepass"};
	Description = "Prompts the targeted player(s) to buy the given gamepass ID.";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "recipients";
			Description = "Players to prompt";
		},
		{
			Type = "integer";
			Name = "passId";
			Description = "The numerical ID of the gamepass";
		}
	};
}
