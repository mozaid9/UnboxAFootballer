local Constants = {}

Constants.StartingCoins = 5000
Constants.DailyRewardCoins = 1000
Constants.FreePackCooldown = 4 * 60 * 60
Constants.DailyRewardCooldown = 24 * 60 * 60

Constants.BaseRebirthCoinCost = 50000
Constants.RebirthCostMultiplier = 1.5
Constants.RebirthLuckBonus = 0.05

Constants.AutoSaveInterval = 60
Constants.DataStoreRetries = 3
Constants.DataStoreRetryBackoff = {
	1,
	2,
	3,
}

-- Sell values and market floors cover every rating used in CardData (78-97).
-- Ratings are internal only — players never see them directly.
Constants.SellValues = {
	-- Gold tier (78-91)
	[78] = 300,
	[79] = 300,
	[80] = 500,
	[81] = 500,
	[82] = 750,
	[83] = 750,
	[84] = 1000,
	[85] = 1000,
	[86] = 1200,
	[87] = 1500,
	[88] = 2000,
	[89] = 2500,
	[90] = 3000,
	[91] = 3500,
	-- Premium / Talisman / Maestro tier (92-94)
	[92] = 5000,
	[93] = 7000,
	[94] = 10000,
	-- Immortal / POTY tier (95-97)
	[95] = 15000,
	[96] = 20000,
	[97] = 25000,
}

Constants.MarketFloors = {
	-- Gold tier
	[78] = 800,
	[79] = 800,
	[80] = 1500,
	[81] = 1500,
	[82] = 2500,
	[83] = 2500,
	[84] = 3500,
	[85] = 3500,
	[86] = 5000,
	[87] = 6000,
	[88] = 8000,
	[89] = 10000,
	[90] = 12000,
	[91] = 15000,
	-- Premium / Talisman / Maestro tier
	[92] = 20000,
	[93] = 30000,
	[94] = 45000,
	-- Immortal / POTY tier
	[95] = 65000,
	[96] = 85000,
	[97] = 110000,
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
	EntrancePillarWidth = 4.8,
	PackPadSize = Vector3.new(10, 0.6, 10),
	PadInfoMaxDistance = 55,
	DisplaySlotCount = 6,
	DisplaySlotSize = Vector3.new(5, 3.5, 5),
}

Constants.FanZone = {
	CrowdNpcCount = 20,
	FloodlightAssetId = 16893178499,
	ModelAssets = {
		SoccerPitchLines = 76319198813958,
		StadiumSeats = 76307049854808,
		GoalPost = 71337096414715,
		Scoreboard = 132186518014609,
		EntranceGate = 130179320229653,
		CrowdBarrier = 9103648774,
		FootballStatue = 117298205135076,
		Bench = 741384218,
		Planter = 5477129144,
		DirectionSign = 102532409227953,
		TicketBooth = 3999244765,
		WalkingNpc = 127964771902906,
	},
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

-- Each milestone fires once when totalPacksOpened crosses `threshold`.
-- packId must match a PackConfig entry. label/color are used on the board.
Constants.PackMilestones = {
	{ threshold = 25,  packId = "GoldPack",    reward = "Gold Pack",    label = "COMMON",    color = Color3.fromRGB(90,  200, 90)  },
	{ threshold = 50,  packId = "RarePack",    reward = "Rare Pack",    label = "RARE",      color = Color3.fromRGB(80,  130, 255) },
	{ threshold = 75,  packId = "PremiumPack", reward = "Premium Pack", label = "EPIC",      color = Color3.fromRGB(170, 75,  255) },
	{ threshold = 100, packId = "JumboPack",   reward = "Jumbo Pack",   label = "SPECIAL",   color = Color3.fromRGB(255, 185, 0)   },
	{ threshold = 150, packId = "DeluxePack",  reward = "Deluxe Pack",  label = "LEGENDARY", color = Color3.fromRGB(220, 75,  30)  },
}

Constants.Rebirth = {
	StartingFansAfterRebirth = Constants.StartingCoins,

	-- Requirements to go from tier N-1 → N.
	-- cards = list of { count, rarity } where the player must own that many
	-- cards OF THAT RARITY OR HIGHER to qualify.
	TierRequirements = {
		[1]  = { fans = 1000000,   cards = { { count = 1, rarity = "Talisman"           } } },
		[2]  = { fans = 2000000,   cards = { { count = 1, rarity = "Maestro"            } } },
		[3]  = { fans = 4000000,   cards = { { count = 2, rarity = "Maestro"            } } },
		[4]  = { fans = 8000000,   cards = { { count = 2, rarity = "Immortal"           } } },
		[5]  = { fans = 16000000,  cards = { { count = 3, rarity = "Immortal"           } } },
		[6]  = { fans = 32000000,  cards = { { count = 3, rarity = "Player of the Year" } } },
	},

	-- Display slots
	BaseSlots      = 6,   -- every player starts with this many
	SlotsPerRebirth = 1,  -- +1 slot per rebirth
	MaxSlots       = 18,  -- hard cap; rebirth terrace supports 12 upper slots

	MultiplierMilestones = {
		{ tier = 0,  multiplier = 1   },
		{ tier = 1,  multiplier = 1.2 },
		{ tier = 2,  multiplier = 1.4 },
		{ tier = 5,  multiplier = 2   },
		{ tier = 10, multiplier = 5   },
	},
}

Constants.Pitchfork = {
	BaseDamage = 1,
	SwingCooldown = 0.42,
	HitRange = 18,       -- studs; close but not painfully strict
	HitFacingDot = 0.35, -- ~70° cone; needs to face pack but not perfectly
}

-- ── Upgrade specs ─────────────────────────────────────────────
-- Each upgrade has levels 0..maxLevel; cost(level) = floor(baseCost * costMultiplier^level)
-- is the cost to go from `level` to `level+1`.
Constants.UpgradeKeys = { "PitchforkDamage", "PackSpawnRate", "PadLuck", "MoveSpeed" }

Constants.Upgrades = {
	PitchforkDamage = {
		displayName = "Pitchfork Power",
		description = "Each swing hits harder — multiply your damage per crack.",
		maxLevel = 12,
		-- Cost to go from level N → N+1 (index 1 = level 0→1, index 12 = level 11→12)
		levelCosts = { 600, 1800, 5000, 14000, 38000, 100000, 260000, 650000, 1600000, 4000000, 10000000, 25000000 },
		-- Damage multiplier at each level (index 1 = level 0, index 13 = level 12)
		multipliers = { 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.3, 2.6, 3.0, 3.5, 4.0, 4.5, 5.0 },
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
		description = "Better packs spawn on your red pad. Lower luck = mostly Gold rubbish.",
		maxLevel = 15,
		-- Cost to go from level N → N+1
		levelCosts = { 1500, 5000, 14000, 40000, 110000, 300000, 800000, 2200000, 6000000, 16000000, 45000000, 120000000, 320000000, 850000000, 2200000000 },
		-- Pack pad spawn weights [Gold, Rare, Premium, Jumbo, Deluxe] at each luck level.
		-- These are used directly in rollPadPackForPlayer.
		padWeightsPerLevel = {
			[0]  = { 55, 28, 12, 4, 1 },
			[1]  = { 52, 29, 13, 5, 1 },
			[2]  = { 49, 29, 14, 6, 2 },
			[3]  = { 46, 29, 16, 7, 2 },
			[4]  = { 43, 29, 17, 8, 3 },
			[5]  = { 40, 28, 19, 10, 3 },
			[6]  = { 37, 27, 21, 11, 4 },
			[7]  = { 33, 26, 23, 13, 5 },
			[8]  = { 29, 25, 25, 15, 6 },
			[9]  = { 25, 23, 27, 18, 7 },
			[10] = { 20, 21, 29, 21, 9 },
			[11] = { 15, 19, 31, 24, 11 },
			[12] = { 10, 16, 32, 28, 14 },
			[13] = { 5,  13, 33, 32, 17 },
			[14] = { 2,  10, 33, 35, 20 },
			[15] = { 0,   8, 30, 38, 24 },
		},
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
	BaseRating    = 78,
	BasePerSecond = 20,    -- fans/sec at rating 78
	GrowthRate    = 1.23,  -- exponential multiplier per rating point above BaseRating
	-- Resulting fan income by key rating:
	--   78 →   20  (base Gold)
	--   84 →   69  (mid Gold)
	--   88 →  157  (top Gold)
	--   91 →  294  (Talisman)
	--   93 →  444  (Maestro tier)
	--   95 →  672  (Immortal)
	--   96 →  826  (Messi Immortal)
	--   97 → 1016  (Maradona / Mbappe POTY)
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

Constants.RarityStyles = {
	["Gold"] = {
		label = "GOLD",
		primary = Color3.fromRGB(255, 215, 0),
		secondary = Color3.fromRGB(190, 126, 26),
		dark = Color3.fromRGB(44, 29, 8),
		trim = Color3.fromRGB(255, 218, 82),
		text = Color3.fromRGB(255, 246, 214),
		glow = Color3.fromRGB(255, 210, 74),
	},
	["Rare Gold"] = {
		label = "RARE GOLD",
		primary = Color3.fromRGB(255, 174, 44),
		secondary = Color3.fromRGB(116, 68, 15),
		dark = Color3.fromRGB(35, 22, 7),
		trim = Color3.fromRGB(255, 196, 70),
		text = Color3.fromRGB(255, 246, 220),
		glow = Color3.fromRGB(255, 162, 44),
	},
	["Premium Gold"] = {
		label = "PREMIUM GOLD",
		primary = Color3.fromRGB(255, 238, 172),
		secondary = Color3.fromRGB(36, 31, 23),
		dark = Color3.fromRGB(9, 9, 10),
		trim = Color3.fromRGB(255, 226, 112),
		text = Color3.fromRGB(255, 250, 230),
		glow = Color3.fromRGB(255, 235, 158),
	},
	["Talisman"] = {
		label = "TALISMAN",
		primary = Color3.fromRGB(235, 56, 43),
		secondary = Color3.fromRGB(92, 11, 14),
		dark = Color3.fromRGB(24, 6, 8),
		trim = Color3.fromRGB(255, 126, 76),
		text = Color3.fromRGB(255, 235, 222),
		glow = Color3.fromRGB(255, 76, 58),
	},
	["Maestro"] = {
		label = "MAESTRO",
		primary = Color3.fromRGB(157, 80, 255),
		secondary = Color3.fromRGB(45, 18, 94),
		dark = Color3.fromRGB(17, 10, 34),
		trim = Color3.fromRGB(226, 174, 255),
		text = Color3.fromRGB(247, 232, 255),
		glow = Color3.fromRGB(176, 96, 255),
	},
	["Immortal"] = {
		label = "IMMORTAL",
		primary = Color3.fromRGB(226, 248, 255),
		secondary = Color3.fromRGB(162, 119, 255),
		dark = Color3.fromRGB(18, 24, 38),
		trim = Color3.fromRGB(245, 255, 255),
		text = Color3.fromRGB(245, 252, 255),
		glow = Color3.fromRGB(202, 244, 255),
	},
	["Player of the Year"] = {
		label = "PLAYER OF THE YEAR",
		primary = Color3.fromRGB(255, 218, 76),
		secondary = Color3.fromRGB(20, 15, 8),
		dark = Color3.fromRGB(5, 5, 6),
		trim = Color3.fromRGB(255, 230, 116),
		text = Color3.fromRGB(255, 246, 214),
		glow = Color3.fromRGB(255, 221, 86),
	},
}
Constants.RarityStyles.POTY = Constants.RarityStyles["Player of the Year"]

return Constants
