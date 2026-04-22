local PackConfig = {}

PackConfig.WeightTiers = {
	{ label = "Common Gold", minRating = 78, maxRating = 80, weight = 45 },
	{ label = "Uncommon Gold", minRating = 81, maxRating = 84, weight = 30 },
	{ label = "Rare Gold", minRating = 85, maxRating = 87, weight = 15 },
	{ label = "Elite Gold", minRating = 88, maxRating = 89, weight = 7 },
	{ label = "Iconic Gold", minRating = 92, maxRating = 92, weight = 3 },
}

PackConfig.WeightFloorPerTier = {
	30,
	20,
	10,
	5,
	3,
}

PackConfig.MaxLuckShift = 12

PackConfig.ShopOrder = {
	{
		id = "GoldPack",
		displayName = "Gold Pack",
		description = "One balanced gold pull for new clubs.",
		cost = 0,
		futureCost = 5000,
		cardCount = 1,
		hitsRequired = 3,
		padWeight = 74,
		color = Color3.fromRGB(255, 215, 0),
		displayRating = 80,
		station = {
			position = Vector3.new(-10, 1.5, -16),
		},
	},
	{
		id = "RareGoldPack",
		displayName = "Rare Gold Pack",
		description = "One rare pull with a guaranteed 85+ player.",
		cost = 0,
		futureCost = 10000,
		cardCount = 1,
		hitsRequired = 4,
		padWeight = 20,
		color = Color3.fromRGB(255, 168, 42),
		displayRating = 85,
		guaranteed = {
			minRating = 85,
			slotIndex = 1,
		},
		station = {
			position = Vector3.new(10, 1.5, -16),
		},
	},
	{
		id = "PremiumGoldPack",
		displayName = "Premium Gold Pack",
		description = "One premium pull with a guaranteed 88+ player.",
		cost = 0,
		futureCost = 18000,
		cardCount = 1,
		hitsRequired = 5,
		padWeight = 6,
		color = Color3.fromRGB(255, 118, 58),
		displayRating = 88,
		guaranteed = {
			minRating = 88,
			slotIndex = 1,
		},
	},
}

PackConfig.ById = {}
for _, pack in ipairs(PackConfig.ShopOrder) do
	PackConfig.ById[pack.id] = pack
end

PackConfig.PadSpawnOrder = PackConfig.ShopOrder

return PackConfig
