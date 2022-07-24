return {
	Name = "promptProductPurchase";
	Aliases = {"devproduct", "product"};
	Description = "Prompts the targeted player(s) to buy the given product ID.";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "recipients";
			Description = "Players to prompt";
		},
		{
			Type = "integer";
			Name = "productId";
			Description = "The numerical ID of the product";
		}
	};
}
