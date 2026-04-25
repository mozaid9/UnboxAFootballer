local Constants = {}

Constants.StartingCoins = 5000
Constants.DailyRewardCoins = 1000
Constants.FreePackCooldown = 4 * 60 * 60
Constants.DailyRewardCooldown = 24 * 60 * 60

Constants.BaseRebirthCoinCost = 50000
Constants.RebirthCostMultiplier = 1.5
Constants.RebirthLuckBonus = 0.05

Constants.AutoSaveInterval = 60
Constants.DataStoreRetries = 4
Constants.DataStoreRetryBackoff = {
	1,
	2,
	4,
	8,
}

Constants.SellValues = {
	[92] = 5000,
	[89] = 2500,
	[88] = 2500,
	[87] = 1500,
	[86] = 1500,
	[85] = 1500,
	[84] = 750,
	[83] = 750,
	[82] = 750,
	[81] = 750,
	[80] = 750,
	[79] = 300,
	[78] = 300,
}

Constants.MarketFloors = {
	[92] = 20000,
	[89] = 10000,
	[88] = 10000,
	[87] = 6000,
	[86] = 6000,
	[85] = 6000,
	[84] = 2500,
	[83] = 2500,
	[82] = 2500,
	[81] = 2500,
	[80] = 2500,
	[79] = 800,
	[78] = 800,
}

Constants.MarketCeilingMultiplier = 5

Constants.BaseLayout = {
	MaxPlots = 6,
	PlotsPerSide = 3,
	SideOffset = 88,
	StartZ = -96,
	PlotSpacing = 96,
	PlotSize = Vector3.new(56, 1, 44),
	FenceHeight = 4.5,
	WallThickness = 1.2,
	EntranceWidth = 16,
	EntrancePillarWidth = 2.2,
	PackPadSize = Vector3.new(10, 0.6, 10),
	PadInfoMaxDistance = 38,
	DisplaySlotCount = 6,
	DisplaySlotSize = Vector3.new(7, 3.5, 7),
}

Constants.FanZone = {
	CrowdNpcCount = 20,
	FansPerVisibleNpc = 75000,
	BaseStadiumCapacity = 4,
	MaxStadiumVisitors = 8,
	VisitorRouteChance = 0.48,
	FoodStopChance = 0.55,
	NpcWalkSpeed = 13,
	StadiumVisitPauseMin = 30,
	StadiumVisitPauseMax = 90,
	KioskAssets = {
		{ id = 124755798177818, label = "POPCORN" },
		{ id = 91415101160071,  label = "HOT DOGS" },
		{ id = 73722014035299,  label = "BURGERS" },
		{ id = 92061684664312,  label = "DRINKS" },
	},
}

Constants.PackMilestones = {
	{ interval = 50, reward = "Rare Pack" },
	{ interval = 100, reward = "Special Pack" },
	{ interval = 500, reward = "Player Pick" },
}

Constants.Rebirth = {
	BaseFanRequirement = 1000000,
	FanRequirementMultiplier = 2,
	RequiredSpecialCards = 3,
	SpecialRarity = "Premium Gold",
	StartingFansAfterRebirth = Constants.StartingCoins,
	MultiplierMilestones = {
		{ tier = 0, multiplier = 1 },
		{ tier = 1, multiplier = 1.2 },
		{ tier = 2, multiplier = 1.4 },
		{ tier = 5, multiplier = 2 },
		{ tier = 10, multiplier = 5 },
	},
}

Constants.Pitchfork = {
	BaseDamage = 1,
	SwingCooldown = 0.42,
	HitRange = 12,
	HitFacingDot = 0.5,
}

-- ── Upgrade specs ─────────────────────────────────────────────
-- Each upgrade has levels 0..maxLevel; cost(level) = floor(baseCost * costMultiplier^level)
-- is the cost to go from `level` to `level+1`.
Constants.UpgradeKeys = { "PitchforkDamage", "PackSpawnRate", "PadLuck", "MoveSpeed" }

Constants.Upgrades = {
	PitchforkDamage = {
		displayName = "Pitchfork Power",
		description = "Deal more damage per swing, crack packs faster.",
		maxLevel = 9,
		baseCost = 400,
		costMultiplier = 1.7,
		baseDamage = 1,
		damagePerLevel = 1,
	},
	PackSpawnRate = {
		displayName = "Pack Spawn Speed",
		description = "Packs respawn on your red pad faster.",
		maxLevel = 8,
		baseCost = 500,
		costMultiplier = 1.8,
		baseDelay = 1.1,
		delayReductionPerLevel = 0.1,
		minDelay = 0.3,
	},
	PadLuck = {
		displayName = "Pad Luck",
		description = "Shifts your pad odds toward Rare and Premium packs.",
		maxLevel = 10,
		baseCost = 700,
		costMultiplier = 1.85,
		shiftPerLevel = 3,
		maxShift = 30,
	},
	MoveSpeed = {
		displayName = "Sprint Speed",
		description = "Move around the map and your stadium faster.",
		maxLevel = 8,
		baseCost = 300,
		costMultiplier = 1.7,
		baseWalkSpeed = 16,
		speedPerLevel = 2,
		maxWalkSpeed = 32,
	},
}

Constants.PassiveIncome = {
	BaseRating = 78,
	BasePerSecond = 20,
	PerRatingStep = 8,
}

Constants.UI = {
	Background = Color3.fromRGB(7, 11, 20),
	Panel = Color3.fromRGB(14, 18, 31),
	PanelAlt = Color3.fromRGB(18, 23, 39),
	Gold = Color3.fromRGB(255, 215, 0),
	RareGold = Color3.fromRGB(255, 170, 48),
	PremiumGold = Color3.fromRGB(240, 248, 255),
	Text = Color3.fromRGB(245, 238, 220),
	Muted = Color3.fromRGB(170, 165, 150),
	Success = Color3.fromRGB(78, 181, 105),
	Danger = Color3.fromRGB(180, 78, 58),
}

return Constants
