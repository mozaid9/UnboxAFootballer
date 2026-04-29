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

-- Sell values and market floors cover every powerScore used in CardData (78-99).
-- powerScore is internal only — players never see it directly.
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
	-- Immortal / POTY tier (95-99)
	[95] = 15000,
	[96] = 20000,
	[97] = 25000,
	[98] = 32500,
	[99] = 40000,
}

Constants.RaritySellMultipliers = {
	["Gold"] = 1.00,
	["Rare Gold"] = 1.10,
	["Premium Gold"] = 1.25,
	["Talisman"] = 1.45,
	["Maestro"] = 1.75,
	["Immortal"] = 2.00,
	["Player of the Year"] = 2.25,
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
	[98] = 145000,
	[99] = 190000,
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

-- Pack pity milestones. These repeat independently: every 50th pack gives
-- Rare Gold+, every 150th Premium Gold+, every 500th Talisman+, and every
-- 1000th pack can break normal pack caps for a special high-tier pull.
Constants.PackMilestones = {
	{ threshold = 50,   minRarity = "Rare Gold",    reward = "Rare Gold+ Guarantee",     label = "RARE+",     color = Color3.fromRGB(255, 170, 48)  },
	{ threshold = 150,  minRarity = "Premium Gold", reward = "Premium Gold+ Guarantee",  label = "PREM+",     color = Color3.fromRGB(255, 226, 112) },
	{ threshold = 500,  minRarity = "Talisman",     reward = "Talisman+ Guarantee",      label = "TALISMAN",  color = Color3.fromRGB(235, 56, 43)   },
	{ threshold = 1000, minRarity = "Maestro",      reward = "Special High-Tier Reward", label = "SPECIAL",   color = Color3.fromRGB(157, 80, 255), allowBeyondPackCap = true },
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
		{ tier = 1,  multiplier = 1.25 },
		{ tier = 2,  multiplier = 2.00 },
		{ tier = 3,  multiplier = 3.00 },
		{ tier = 5,  multiplier = 4.00 },
		{ tier = 10, multiplier = 7.50 },
	},
}

Constants.Pitchfork = {
	BaseDamage = 1,
	SwingCooldown = 0.42,
	HitRange = 18,       -- studs; close but not painfully strict
	HitFacingDot = 0.35, -- ~70° cone; needs to face pack but not perfectly
}

-- ── Upgrade specs ─────────────────────────────────────────────
-- Each upgrade has levels 0..maxLevel. Power-cost upgrades use
-- floor(baseCost * nextLevel^costExponent) for intentionally slow scaling.
Constants.UpgradeKeys = { "PitchforkDamage", "PackSpawnLuck", "CardPullLuck", "MoveSpeed" }

Constants.Upgrades = {
	PitchforkDamage = {
		displayName = "Tool Power",
		description = "Break packs faster with stronger pitchfork hits.",
		maxLevel = 12,
		-- Cost to go from level N → N+1 (index 1 = level 0→1, index 12 = level 11→12)
		levelCosts = { 600, 1800, 5000, 14000, 38000, 100000, 260000, 650000, 1600000, 4000000, 10000000, 25000000 },
		-- Damage multiplier at each level (index 1 = level 0, index 13 = level 12)
		multipliers = { 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.3, 2.6, 3.0, 3.5, 4.0, 4.5, 5.0 },
	},
	PackSpawnLuck = {
		displayName = "Pack Spawn Luck",
		description = "Better packs appear on your red pad.",
		maxLevel = 50,
		startLevel = 1,
		baseCost = 650,
		costExponent = 2.05,
	},
	CardPullLuck = {
		displayName = "Card Pull Luck",
		description = "Higher chance of better footballers inside packs.",
		maxLevel = 50,
		startLevel = 1,
		baseCost = 850,
		costExponent = 2.10,
	},
	-- Hidden legacy/support upgrades. They remain load-safe for old data but
	-- are no longer shown in the upgrade shop.
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
	BasePerSecond = 20,    -- fans/sec at powerScore 78
	GrowthRate    = 1.23,  -- exponential multiplier per powerScore point above BaseRating
	-- Resulting fan income by key powerScore:
	--   78 →   20  (base Gold)
	--   84 →   69  (mid Gold)
	--   88 →  158  (top Gold)
	--   91 →  294  (Talisman)
	--   93 →  446  (Maestro tier)
	--   95 →  672  (Immortal)
	--   96 →  826  (Messi Immortal)
	--   97 → 1021  (Messi / Ronaldo / Mbappe POTY)
	--   99 → 1545  (top POTY)
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
		primary = Color3.fromRGB(255, 216, 48),
		secondary = Color3.fromRGB(214, 158, 36),
		dark = Color3.fromRGB(132, 96, 18),
		trim = Color3.fromRGB(255, 207, 66),
		text = Color3.fromRGB(255, 246, 214),
		glow = Color3.fromRGB(255, 222, 88),
	},
	["Rare Gold"] = {
		label = "RARE GOLD",
		primary = Color3.fromRGB(255, 188, 34),
		secondary = Color3.fromRGB(255, 142, 18),
		dark = Color3.fromRGB(118, 43, 4),
		trim = Color3.fromRGB(255, 230, 96),
		text = Color3.fromRGB(255, 246, 220),
		glow = Color3.fromRGB(255, 176, 34),
	},
	["Premium Gold"] = {
		label = "PREMIUM GOLD",
		primary = Color3.fromRGB(255, 232, 128),
		secondary = Color3.fromRGB(13, 13, 15),
		dark = Color3.fromRGB(0, 0, 0),
		trim = Color3.fromRGB(255, 221, 82),
		text = Color3.fromRGB(255, 250, 230),
		glow = Color3.fromRGB(255, 235, 158),
	},
	["Talisman"] = {
		label = "TALISMAN",
		primary = Color3.fromRGB(255, 66, 48),
		secondary = Color3.fromRGB(196, 22, 26),
		dark = Color3.fromRGB(72, 4, 10),
		trim = Color3.fromRGB(255, 98, 72),
		text = Color3.fromRGB(255, 235, 222),
		glow = Color3.fromRGB(255, 76, 58),
	},
	["Maestro"] = {
		label = "MAESTRO",
		primary = Color3.fromRGB(176, 92, 255),
		secondary = Color3.fromRGB(116, 44, 214),
		dark = Color3.fromRGB(28, 8, 72),
		trim = Color3.fromRGB(218, 160, 255),
		text = Color3.fromRGB(247, 232, 255),
		glow = Color3.fromRGB(190, 104, 255),
	},
	["Immortal"] = {
		label = "IMMORTAL",
		primary = Color3.fromRGB(245, 255, 255),
		secondary = Color3.fromRGB(116, 184, 255),
		dark = Color3.fromRGB(232, 248, 255),
		trim = Color3.fromRGB(245, 255, 255),
		text = Color3.fromRGB(12, 22, 36),
		glow = Color3.fromRGB(228, 252, 255),
	},
	["Player of the Year"] = {
		label = "POTY",
		primary = Color3.fromRGB(255, 218, 76),
		secondary = Color3.fromRGB(70, 52, 8),
		dark = Color3.fromRGB(0, 0, 0),
		trim = Color3.fromRGB(255, 226, 74),
		text = Color3.fromRGB(255, 246, 214),
		glow = Color3.fromRGB(255, 226, 88),
	},
}
Constants.RarityStyles.POTY = Constants.RarityStyles["Player of the Year"]

return Constants
