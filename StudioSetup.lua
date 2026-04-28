-- ============================================================
-- UNBOX A FOOTBALLER v16 -- ROJO-SYNCED FALLBACK SETUP
-- Paste this ENTIRE script into the Roblox Studio Command Bar
-- and press Enter to install the current prototype.
-- ============================================================

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SP = game:GetService("StarterPlayer")
local STP = game:GetService("StarterPack")

local function wipe(name, parent)
    if not parent then
        return
    end

    while true do
        local old = parent:FindFirstChild(name)
        if not old then
            break
        end
        old:Destroy()
    end
end

local function makeFolder(name, parent)
    wipe(name, parent)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function makeModule(name, parent, source)
    wipe(name, parent)
    local module = Instance.new("ModuleScript")
    module.Name = name
    module.Source = source
    module.Parent = parent
    return module
end

local function makeScript(name, parent, source)
    wipe(name, parent)
    local scriptObj = Instance.new("Script")
    scriptObj.Name = name
    scriptObj.Source = source
    scriptObj.Parent = parent
    return scriptObj
end

local function makeLocal(name, parent, source)
    wipe(name, parent)
    local localScript = Instance.new("LocalScript")
    localScript.Name = name
    localScript.Source = source
    localScript.Parent = parent
    return localScript
end

local sps = SP:WaitForChild("StarterPlayerScripts")

wipe('Shared', RS)
wipe('Remotes', RS)
wipe('Services', SSS)
wipe('Main', SSS)
wipe('BaseService', SSS)
wipe('CrowdService', SSS)
wipe('DataService', SSS)
wipe('EconomyService', SSS)
wipe('MarketService', SSS)
wipe('PackService', SSS)
wipe('RebirthService', SSS)
wipe('TradeService', SSS)
wipe('BaseUI', sps)
wipe('CollectionUI', sps)
wipe('HUDClient', sps)
wipe('InventoryUI', sps)
wipe('MarketUI', sps)
wipe('PackOpeningUI', sps)
wipe('RebirthUI', sps)
wipe('ShopUI', sps)
wipe('ToolClient', sps)
wipe('TradeUI', sps)
wipe('UpgradesUI', sps)
wipe('Pitchfork', STP)
wipe('Bat', STP)
wipe('Crates', workspace)
wipe('PackStations', workspace)
wipe('PlayerBases', workspace)

local shared = makeFolder("Shared", RS)

makeModule('CardData', shared, [[-- ============================================================
-- CardData.lua
-- The master card pool for the launch set.
-- ModuleScript → goes in ReplicatedStorage/Shared/
-- ============================================================

local CardData = {}

-- ── Card Pool ─────────────────────────────────────────────────
-- Each card has a unique numeric id used everywhere internally
-- (inventory keys, trade requests, market listings, etc.)
CardData.Pool = {
    -- ★ 92-rated (Rare Gold) ──────────────────────────────────
    { id = 1,  name = "Leonel Messi",       nation = "Argentina", position = "RW",  rating = 92, rarity = "Rare Gold" },
    { id = 2,  name = "Cristian Ronaldo",   nation = "Portugal",  position = "ST",  rating = 92, rarity = "Rare Gold" },
    -- ★ 88-89 rated (Rare Gold) ───────────────────────────────
    { id = 3,  name = "Kylann Mbappe",      nation = "France",    position = "ST",  rating = 89, rarity = "Rare Gold" },
    { id = 4,  name = "Erling Halland",     nation = "Norway",    position = "ST",  rating = 88, rarity = "Rare Gold" },
    -- ★ 85-87 rated (Rare Gold) ───────────────────────────────
    { id = 5,  name = "Rodrigo Bellingham", nation = "England",   position = "CM",  rating = 87, rarity = "Rare Gold" },
    { id = 6,  name = "Vinicius Jr",        nation = "Brazil",    position = "LW",  rating = 86, rarity = "Rare Gold" },
    { id = 7,  name = "Keven De Bruin",     nation = "Belgium",   position = "CM",  rating = 85, rarity = "Rare Gold" },
    -- ★ 81-84 rated (Gold) ────────────────────────────────────
    { id = 8,  name = "Jamal Musley",       nation = "Germany",   position = "CAM", rating = 84, rarity = "Gold" },
    { id = 9,  name = "Pedri Gonzalez",     nation = "Spain",     position = "CM",  rating = 83, rarity = "Gold" },
    { id = 10, name = "Bukayo Sako",        nation = "England",   position = "RW",  rating = 82, rarity = "Gold" },
    { id = 11, name = "Toni Kruger",        nation = "Germany",   position = "CM",  rating = 81, rarity = "Gold" },
    -- ★ 78-80 rated (Gold) ────────────────────────────────────
    { id = 12, name = "Phil Fodo",          nation = "England",   position = "CAM", rating = 80, rarity = "Gold" },
    { id = 13, name = "Alison Becker",      nation = "Brazil",    position = "GK",  rating = 80, rarity = "Gold" },
    { id = 14, name = "Luca Modric",        nation = "Croatia",   position = "CM",  rating = 79, rarity = "Gold" },
    { id = 15, name = "Marcus Rashford",    nation = "England",   position = "LW",  rating = 78, rarity = "Gold" },
}

-- ── Fast lookup by ID ─────────────────────────────────────────
-- CardData.ById[3] → the Mbappe card table
CardData.ById = {}
for _, card in ipairs(CardData.Pool) do
    CardData.ById[card.id] = card
end

-- ── Nation groupings (used by collection milestones) ──────────
CardData.NationGroups = {
    England   = { 5, 10, 12, 15 },  -- Bellingham, Sako, Fodo, Rashford
    Germany   = { 8, 11 },           -- Musley, Kruger
    Brazil    = { 6, 13 },           -- Vinicius, Becker
}

return CardData
]])

makeModule('Constants', shared, [[local Constants = {}

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
	DisplaySlotSize = Vector3.new(7, 3.5, 7),
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

]])

makeModule('PackConfig', shared, [[local PackConfig = {}

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
]])

makeModule('Utils', shared, [[local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Utils = {}

function Utils.WeightedRandom(weights)
	local total = 0
	for _, weight in ipairs(weights) do
		total += weight
	end

	local roll = math.random() * total
	local running = 0
	for index, weight in ipairs(weights) do
		running += weight
		if roll <= running then
			return index
		end
	end

	return #weights
end

function Utils.DeepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = type(value) == "table" and Utils.DeepCopy(value) or value
	end
	return copy
end

function Utils.FormatNumber(numberValue)
	local source = tostring(math.floor(numberValue))
	local result = source:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return result:match("^,(.+)$") or result
end

function Utils.FormatCountdown(seconds)
	local value = math.max(0, math.floor(seconds))
	local hours = math.floor(value / 3600)
	local minutes = math.floor((value % 3600) / 60)
	local secs = value % 60

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	end
	if minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	end
	return string.format("%ds", secs)
end

function Utils.GetSellValue(rating)
	return Constants.SellValues[rating] or 0
end

function Utils.GetMarketFloor(rating)
	return Constants.MarketFloors[rating] or 0
end

function Utils.GetPassiveIncome(rating)
	local config = Constants.PassiveIncome
	local ratingSteps = math.max(0, (rating or config.BaseRating) - config.BaseRating)
	return config.BasePerSecond + (ratingSteps * config.PerRatingStep)
end

function Utils.GetCardIncomeRating(cardOrRating)
	if type(cardOrRating) == "table" then
		return cardOrRating.internalRating or cardOrRating.rating or Constants.PassiveIncome.BaseRating
	end

	return cardOrRating or Constants.PassiveIncome.BaseRating
end

function Utils.GetRarityStyle(rarity)
	local styles = Constants.RarityStyles or {}
	return styles[rarity] or styles.Gold or {
		label = rarity or "GOLD",
		primary = Constants.UI.Gold,
		secondary = Constants.UI.RareGold,
		dark = Constants.UI.PanelAlt,
		trim = Constants.UI.Gold,
		text = Constants.UI.Text,
		glow = Constants.UI.Gold,
	}
end

function Utils.GetRarityColor(rarity)
	return Utils.GetRarityStyle(rarity).primary
end

return Utils
]])

makeModule('BaseService', SSS, [[local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Utils = require(ReplicatedStorage.Shared.Utils)

local BaseService = {}

local layout = Constants.BaseLayout
local fanZoneConfig = Constants.FanZone
local packMilestones = Constants.PackMilestones
local basesFolder
local plots = {}
local assignedPlots = {}
local animatedTurnstiles = {}

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function replaceLightingEffect(className, name, props)
	local oldEffect = Lighting:FindFirstChild(name)
	if oldEffect then
		oldEffect:Destroy()
	end

	props = props or {}
	props.Name = name
	return make(className, props, Lighting)
end

local function configureMapLighting()
	Lighting.ClockTime = 19.25
	Lighting.Brightness = 1.9
	Lighting.Ambient = Color3.fromRGB(96, 108, 136)
	Lighting.OutdoorAmbient = Color3.fromRGB(68, 78, 104)
	Lighting.EnvironmentDiffuseScale = 0.58
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.FogColor = Color3.fromRGB(42, 51, 68)
	Lighting.FogStart = 320
	Lighting.FogEnd = 760

	replaceLightingEffect("Atmosphere", "UnboxNightAtmosphere", {
		Density = 0.16,
		Offset = 0.04,
		Color = Color3.fromRGB(185, 204, 230),
		Decay = Color3.fromRGB(38, 46, 62),
		Glare = 0.18,
		Haze = 0.95,
	})

	replaceLightingEffect("BloomEffect", "UnboxGoldBloom", {
		Intensity = 0.018,
		Size = 8,
		Threshold = 3.4,
	})

	replaceLightingEffect("ColorCorrectionEffect", "UnboxColorGrade", {
		Brightness = 0,
		Contrast = 0.05,
		Saturation = 0.08,
		TintColor = Color3.fromRGB(242, 247, 255),
	})
end

local function createSignLabel(text, size, position, color, parent)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Size = size,
		Position = position,
		Text = text,
		TextColor3 = color,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, parent)
end

local function createOwnerSignText(text, size, position, color, style, parent)
	style = style or {}

	local label = make("TextLabel", {
		BackgroundTransparency = 1,
		Size = size,
		Position = position,
		Text = text,
		TextColor3 = color,
		TextStrokeColor3 = style.textStrokeColor or Color3.fromRGB(5, 8, 14),
		TextStrokeTransparency = style.textStrokeTransparency or 0.65,
		TextScaled = style.textScaled == true,
		TextSize = style.textSize or 30,
		Font = style.font or Enum.Font.GothamBold,
		TextWrapped = style.textWrapped == true,
		TextXAlignment = style.textXAlignment or Enum.TextXAlignment.Center,
		TextYAlignment = style.textYAlignment or Enum.TextYAlignment.Center,
	}, parent)

	if style.textScaled then
		make("UITextSizeConstraint", {
			MinTextSize = style.minTextSize or 20,
			MaxTextSize = style.maxTextSize or 150,
		}, label)
	end

	return label
end

local function formatStadiumTitle(ownerName)
	if not ownerName or ownerName == "" then
		return "OPEN"
	end

	return string.upper(ownerName) .. "'S"
end

local function getNextPackMilestone(totalPacks)
	totalPacks = math.max(0, totalPacks or 0)
	-- Milestones repeat every CYCLE packs (= the last milestone's threshold)
	local CYCLE = packMilestones and packMilestones[#packMilestones].threshold or 150
	local cycleNum    = math.floor(totalPacks / CYCLE)
	local posInCycle  = totalPacks % CYCLE
	local prevAt      = cycleNum * CYCLE  -- absolute start of current cycle

	for _, milestone in ipairs(packMilestones or {}) do
		local T = milestone.threshold
		if type(T) == "number" and posInCycle < T then
			local absoluteNext = cycleNum * CYCLE + T
			local span = absoluteNext - prevAt
			local progress = span > 0 and math.clamp((totalPacks - prevAt) / span, 0, 1) or 1
			return {
				nextAt    = absoluteNext,
				prevAt    = prevAt,
				progress  = progress,
				reward    = milestone.reward or "Pack",
				packId    = milestone.packId,
				label     = milestone.label  or "REWARD",
				color     = milestone.color  or Color3.fromRGB(255, 215, 0),
				threshold = T,
				cycleNum  = cycleNum,
			}
		end
		if type(T) == "number" then
			prevAt = cycleNum * CYCLE + T
		end
	end

	-- All milestones done in this cycle — show teaser for first in next cycle
	local nextCycle = cycleNum + 1
	local firstMs   = packMilestones and packMilestones[1]
	local firstT    = firstMs and firstMs.threshold or 25
	local absNext   = nextCycle * CYCLE + firstT
	local span      = absNext - prevAt
	local progress  = span > 0 and math.clamp((totalPacks - prevAt) / span, 0, 1) or 1
	return {
		nextAt    = absNext,
		prevAt    = prevAt,
		progress  = progress,
		reward    = firstMs and firstMs.reward or "Gold Pack",
		packId    = firstMs and firstMs.packId,
		label     = firstMs and firstMs.label  or "COMMON",
		color     = firstMs and firstMs.color  or Color3.fromRGB(90, 200, 90),
		threshold = firstT,
		cycleNum  = nextCycle,
	}
end

local function updateOwnerSign(plot, ownerName, subtitle)
	if ownerName and ownerName ~= "" then
		plot.ownerTopLabel.Text = "HOME CLUB"
		plot.ownerNameLabel.Text = formatStadiumTitle(ownerName)
		plot.ownerSubtitleLabel.Text = "STADIUM"
	else
		plot.ownerTopLabel.Text = "AVAILABLE PLOT"
		plot.ownerNameLabel.Text = "OPEN"
		plot.ownerSubtitleLabel.Text = "STADIUM"
	end

	plot.ownerTopLabel.Visible = true
	plot.ownerSubtitleLabel.Visible = true
end

local function updatePadLabel(plot, title, subtitle, color)
	plot.padTitleLabel.Text = title
	plot.padSubtitleLabel.Text = subtitle
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = false
end

local function updatePadHealth(plot, title, currentValue, maxValue, color)
	local ratio = maxValue > 0 and math.clamp(currentValue / maxValue, 0, 1) or 0
	plot.padTitleLabel.Text = title
	-- Show percentage remaining instead of raw hit numbers
	local pct = math.ceil(ratio * 100)
	plot.padSubtitleLabel.Text = pct .. "% remaining"
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = true
	-- Bar colour shifts green → yellow → red as health drops
	local r = math.clamp(2 * (1 - ratio), 0, 1)
	local g = math.clamp(2 * ratio, 0, 1)
	plot.padBarFill.BackgroundColor3 = Color3.new(r, g, 0)
	plot.padBarFill.Size = UDim2.new(ratio, 0, 1, 0)
end

local function createFence(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(28, 36, 50),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createStadiumTier(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(112, 124, 148),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createStadiumWedge(parent, size, cframe)
	make("WedgePart", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(78, 88, 108),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createGlowStrip(parent, name, size, cframe, color, transparency)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = color or Color3.fromRGB(255, 215, 0),
		Transparency = transparency or 0.18,
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createGroundDisk(parent, name, position, diameter, height, color, material, transparency)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Shape = Enum.PartType.Cylinder,
		Material = material or Enum.Material.SmoothPlastic,
		Color = color,
		Transparency = transparency or 0,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
	}, parent)
end

local function createFloatingHubLabel(parent, position, title, subtitle)
	local anchor = make("Part", {
		Name = "FloatingHubLabelAnchor",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
	}, parent)

	local gui = make("BillboardGui", {
		Name = "FloatingHubLabel",
		AlwaysOnTop = false,
		Size = UDim2.fromOffset(320, 96),
		StudsOffset = Vector3.zero,
		MaxDistance = 230,
	}, anchor)

	local frame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 18) }, frame)
	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 2,
		Transparency = 0.16,
	}, frame)

	local titleLabel = createSignLabel(title, UDim2.fromScale(0.92, 0.54), UDim2.fromScale(0.04, 0.08), Color3.fromRGB(255, 215, 0), frame)
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextStrokeTransparency = 0.45
	local subtitleLabel = createSignLabel(subtitle, UDim2.fromScale(0.88, 0.24), UDim2.fromScale(0.06, 0.64), Color3.fromRGB(235, 229, 210), frame)
	subtitleLabel.Font = Enum.Font.GothamBold

	return anchor
end

local function createParticleAnchor(parent, name, position, rate, colorSequence, texture, sizeSequence)
	local anchor = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
	}, parent)

	make("ParticleEmitter", {
		Name = "Particles",
		Texture = texture,
		Color = colorSequence,
		LightEmission = 0.65,
		Rate = rate,
		Lifetime = NumberRange.new(1.4, 2.6),
		Speed = NumberRange.new(1.4, 3.0),
		SpreadAngle = Vector2.new(180, 180),
		Size = sizeSequence,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.72, 0.42),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Acceleration = Vector3.new(0, 1.2, 0),
	}, anchor)

	return anchor
end

local function createPitchLine(parent, name, size, cframe, transparency)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(238, 240, 232),
		Transparency = transparency or 0.02,
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createPitchCircle(parent, baseCFrame, y, radius)
	local segments = 28
	local lineWidth = 0.18
	local segmentLength = (2 * math.pi * radius) / segments * 0.74

	for index = 1, segments do
		local angle = ((index - 1) / segments) * 2 * math.pi
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local yaw = -(angle + (math.pi / 2))

		createPitchLine(
			parent,
			"CenterCircleSegment",
			Vector3.new(segmentLength, 0.045, lineWidth),
			baseCFrame * CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0),
			0.03
		)
	end
end

local function createPenaltyBox(parent, baseCFrame, endX, y, depth, width, lineThickness, namePrefix)
	local direction = endX >= 0 and -1 or 1
	local innerX = endX + direction * depth
	local centerX = endX + direction * (depth / 2)

	createPitchLine(parent, namePrefix .. "InnerLine", Vector3.new(lineThickness, 0.05, width), baseCFrame * CFrame.new(innerX, y, 0), 0.03)
	createPitchLine(parent, namePrefix .. "NorthSide", Vector3.new(depth, 0.05, lineThickness), baseCFrame * CFrame.new(centerX, y, -(width / 2)), 0.03)
	createPitchLine(parent, namePrefix .. "SouthSide", Vector3.new(depth, 0.05, lineThickness), baseCFrame * CFrame.new(centerX, y, width / 2), 0.03)
end

local function createCornerGoal(parent, name, goalCFrame)
	local model = make("Model", {
		Name = name,
	}, parent)

	local goalWidth = 5.4
	local goalHeight = 2.65
	local goalDepth = 1.9
	local thickness = 0.18
	local postColor = Color3.fromRGB(245, 247, 240)
	local netColor = Color3.fromRGB(205, 222, 238)

	local function goalPart(partName, size, localOffset)
		make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = postColor,
			Size = size,
			CFrame = goalCFrame * CFrame.new(localOffset),
		}, model)
	end

	local function netPart(partName, size, localOffset)
		make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = netColor,
			Transparency = 0.24,
			Size = size,
			CFrame = goalCFrame * CFrame.new(localOffset),
		}, model)
	end

	goalPart("LeftPost", Vector3.new(thickness, goalHeight, thickness), Vector3.new(-goalWidth / 2, goalHeight / 2, 0))
	goalPart("RightPost", Vector3.new(thickness, goalHeight, thickness), Vector3.new(goalWidth / 2, goalHeight / 2, 0))
	goalPart("Crossbar", Vector3.new(goalWidth + thickness, thickness, thickness), Vector3.new(0, goalHeight, 0))
	goalPart("BackLeftPost", Vector3.new(thickness, goalHeight * 0.78, thickness), Vector3.new(-goalWidth / 2, (goalHeight * 0.78) / 2, goalDepth))
	goalPart("BackRightPost", Vector3.new(thickness, goalHeight * 0.78, thickness), Vector3.new(goalWidth / 2, (goalHeight * 0.78) / 2, goalDepth))
	goalPart("BackCrossbar", Vector3.new(goalWidth + thickness, thickness, thickness), Vector3.new(0, goalHeight * 0.78, goalDepth))
	goalPart("LeftRoofRail", Vector3.new(thickness, thickness, goalDepth), Vector3.new(-goalWidth / 2, goalHeight * 0.89, goalDepth / 2))
	goalPart("RightRoofRail", Vector3.new(thickness, thickness, goalDepth), Vector3.new(goalWidth / 2, goalHeight * 0.89, goalDepth / 2))

	for index = -2, 2 do
		netPart("BackNetVertical", Vector3.new(0.045, goalHeight * 0.66, 0.045), Vector3.new((goalWidth / 5) * index, goalHeight * 0.36, goalDepth + 0.03))
	end

	for index = 1, 4 do
		netPart("BackNetHorizontal", Vector3.new(goalWidth, 0.045, 0.045), Vector3.new(0, goalHeight * (index / 5), goalDepth + 0.035))
	end

	return model
end

local function createAngledCornerGoal(parent, name, baseCFrame, localX, localZ)
	local worldPosition = (baseCFrame * CFrame.new(localX, 0.6, localZ)).Position
	local lookPosition = (baseCFrame * CFrame.new(0, 0.6, 0)).Position
	createCornerGoal(parent, name, CFrame.lookAt(worldPosition, lookPosition))
end

local function createFootballPitchDetails(parent, baseCFrame)
	local pitchFolder = make("Folder", {
		Name = "FootballPitchDetails",
	}, parent)

	local y = 0.63
	local lineThickness = 0.26
	local pitchLength = layout.PlotSize.X - 10
	local pitchWidth = layout.PlotSize.Z - 8
	local halfLength = pitchLength / 2
	local halfWidth = pitchWidth / 2

	createPitchLine(pitchFolder, "NorthTouchline", Vector3.new(pitchLength, 0.05, lineThickness), baseCFrame * CFrame.new(0, y, -halfWidth), 0.02)
	createPitchLine(pitchFolder, "SouthTouchline", Vector3.new(pitchLength, 0.05, lineThickness), baseCFrame * CFrame.new(0, y, halfWidth), 0.02)
	createPitchLine(pitchFolder, "FrontGoalLine", Vector3.new(lineThickness, 0.05, pitchWidth), baseCFrame * CFrame.new(halfLength, y, 0), 0.02)
	createPitchLine(pitchFolder, "BackGoalLine", Vector3.new(lineThickness, 0.05, pitchWidth), baseCFrame * CFrame.new(-halfLength, y, 0), 0.02)
	createPitchLine(pitchFolder, "HalfwayLine", Vector3.new(lineThickness, 0.05, pitchWidth), baseCFrame * CFrame.new(0, y, 0), 0.06)
	createPitchCircle(pitchFolder, baseCFrame, y + 0.01, 5.7)
	createPitchLine(pitchFolder, "CenterSpot", Vector3.new(0.72, 0.06, 0.72), baseCFrame * CFrame.new(0, y + 0.02, 0), 0.02)

	createPenaltyBox(pitchFolder, baseCFrame, halfLength, y + 0.01, 8.4, 19, lineThickness, "FrontPenalty")
	createPenaltyBox(pitchFolder, baseCFrame, -halfLength, y + 0.01, 8.4, 19, lineThickness, "BackPenalty")
	createPenaltyBox(pitchFolder, baseCFrame, halfLength, y + 0.02, 4.4, 11, lineThickness, "FrontSixYard")
	createPenaltyBox(pitchFolder, baseCFrame, -halfLength, y + 0.02, 4.4, 11, lineThickness, "BackSixYard")

	local cornerGoalX = halfLength - 3
	local cornerGoalZ = halfWidth - 2.6
	createAngledCornerGoal(pitchFolder, "NorthEastCornerGoal", baseCFrame, cornerGoalX, -cornerGoalZ)
	createAngledCornerGoal(pitchFolder, "SouthEastCornerGoal", baseCFrame, cornerGoalX, cornerGoalZ)
	createAngledCornerGoal(pitchFolder, "NorthWestCornerGoal", baseCFrame, -cornerGoalX, -cornerGoalZ)
	createAngledCornerGoal(pitchFolder, "SouthWestCornerGoal", baseCFrame, -cornerGoalX, cornerGoalZ)

	return pitchFolder
end

local createSurfaceText

local function createPlanter(parent, position, scale)
	scale = scale or 1

	local model = make("Model", {
		Name = "Planter",
	}, parent)

	make("Part", {
		Name = "Base",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 23, 34),
		Size = Vector3.new(4.2, 1.2, 4.2) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 0.6 * scale, 0)),
	}, model)

	make("Part", {
		Name = "Bush",
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(42, 126, 52),
		Size = Vector3.new(4.6, 3.4, 4.6) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 2.4 * scale, 0)),
	}, model)

	return model
end

local function prepareImportedModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			descendant.Enabled = false
		end
	end
end

local function tryCreateImportedFloodlight(parent, name, position, targetPosition, targetHeight)
	local assetId = fanZoneConfig.FloodlightAssetId
	if type(assetId) ~= "number" or assetId <= 0 then
		return nil
	end

	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not ok or not loaded then
		warn("[UnboxAFootballer] Could not load floodlight asset " .. tostring(assetId) .. ": " .. tostring(loaded))
		return nil
	end

	loaded.Name = name
	loaded.Parent = parent
	prepareImportedModel(loaded)

	local _, size = loaded:GetBoundingBox()
	local scale = math.clamp((targetHeight or 31) / math.max(size.Y, 0.1), 0.12, 4)
	pcall(function()
		loaded:ScaleTo(scale)
	end)

	local targetFlat = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
	loaded:PivotTo(CFrame.lookAt(position, targetFlat))

	local boundsCFrame, boundsSize = loaded:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	loaded:PivotTo(loaded:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))

	return loaded
end

local function tryCreateImportedDecor(parent, name, assetId, position, facingPos, targetHeight)
	if type(assetId) ~= "number" or assetId <= 0 then
		return nil
	end

	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not ok or not loaded then
		warn("[UnboxAFootballer] Could not load decor asset " .. tostring(assetId) .. ": " .. tostring(loaded))
		return nil
	end

	loaded.Name = name
	loaded.Parent = parent
	prepareImportedModel(loaded)

	local _, size = loaded:GetBoundingBox()
	local scale = math.clamp((targetHeight or 8) / math.max(size.Y, 0.1), 0.08, 5)
	pcall(function()
		loaded:ScaleTo(scale)
	end)

	local lookAt = facingPos or (position + Vector3.new(0, 0, -1))
	loaded:PivotTo(CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)))

	local boundsCFrame, boundsSize = loaded:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	loaded:PivotTo(loaded:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))

	return loaded
end

-- Loads the shared stadium seats/bleacher model and places one copy on each
-- of the three stand sides (north, south, back).  Scales by the widest
-- horizontal axis so the seats span the full stand width.  Fails silently.
local function tryAddStadiumSeats(parent, baseCFrame, facingDirection, assetId)
	if type(assetId) ~= "number" or assetId <= 0 then return end

	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not loaded then
		warn("[BaseService] Stadium seats load failed:", assetId, loaded)
		return
	end
	prepareImportedModel(loaded)

	local _, rawSize = loaded:GetBoundingBox()
	local rawSpan = math.max(rawSize.X, rawSize.Z, 0.1)
	if rawSpan <= 0.1 then loaded:Destroy() return end

	local pitchPos   = baseCFrame.Position
	local floorY     = pitchPos.Y + layout.PlotSize.Y / 2
	local sideWidth  = layout.PlotSize.X - 10           -- 46 studs
	local backWidth  = layout.PlotSize.Z + 8            -- 52 studs
	local sideStandZ = layout.PlotSize.Z / 2 + 9        -- centre of side stand
	local backStandX = layout.PlotSize.X / 2 + 7        -- centre of back stand

	local function placeSide(name, worldPos, lookTarget, widthTarget)
		local scaleF = math.clamp(widthTarget / rawSpan, 0.04, 10)
		local clone = loaded:Clone()
		clone.Name = name
		clone.Parent = parent
		pcall(function() clone:ScaleTo(scaleF) end)
		clone:PivotTo(CFrame.lookAt(worldPos, Vector3.new(lookTarget.X, worldPos.Y, lookTarget.Z)))
		local bc, bs = clone:GetBoundingBox()
		clone:PivotTo(clone:GetPivot() + Vector3.new(0, floorY - (bc.Position.Y - bs.Y * 0.5), 0))
	end

	-- North stand (Z negative): fans face south toward the pitch
	placeSide("StadiumSeatsNorth",
		pitchPos + Vector3.new(0, 0, -sideStandZ),
		pitchPos,
		sideWidth)

	-- South stand (Z positive): fans face north toward the pitch
	placeSide("StadiumSeatsSouth",
		pitchPos + Vector3.new(0, 0, sideStandZ),
		pitchPos,
		sideWidth)

	-- Back stand: fans face toward the entrance / pitch front
	placeSide("StadiumSeatsBack",
		pitchPos + Vector3.new(-facingDirection * backStandX, 0, 0),
		pitchPos + Vector3.new(facingDirection * 20, 0, 0),
		backWidth)

	loaded:Destroy()
end

local function createFloodlightBeam(parent, name, position, targetPosition, poleHeight, options)
	options = options or {}
	local anchorPosition = position + Vector3.new(0, poleHeight + 1.5, 0)
	local anchor = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.lookAt(anchorPosition, targetPosition),
	}, parent)

	make("SpotLight", {
		Name = "FloodBeam",
		Face = Enum.NormalId.Front,
		Color = Color3.fromRGB(255, 245, 218),
		Range = options.range or 112,
		Angle = options.angle or 52,
		Brightness = options.brightness or 1.85,
		Shadows = false,
	}, anchor)

	make("PointLight", {
		Name = "FloodFill",
		Color = Color3.fromRGB(255, 235, 190),
		Range = options.fillRange or 28,
		Brightness = options.fillBrightness or 0.18,
		Shadows = false,
	}, anchor)

	return anchor
end

local function createFloodlightRig(parent, name, position, targetPosition, options)
	options = options or {}
	local model = make("Model", {
		Name = name,
	}, parent)

	local poleHeight = options.poleHeight or 30
	local imported = tryCreateImportedFloodlight(model, "ImportedFloodlight", position, targetPosition, options.modelHeight or 31)
	createFloodlightBeam(model, "LightAnchor", position, targetPosition, poleHeight, options)

	if imported then
		return model
	end

	make("Part", {
		Name = "Pole",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(1.2, poleHeight, 1.2),
		CFrame = CFrame.new(position + Vector3.new(0, poleHeight / 2, 0)),
	}, model)

	local panelPosition = position + Vector3.new(0, poleHeight + 1.5, 0)
	local panel = make("Part", {
		Name = "LightPanel",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(12.5, 6.2, 0.55),
		CFrame = CFrame.lookAt(panelPosition, targetPosition),
	}, model)

	for row = 1, 2 do
		for column = 1, 4 do
			local x = -3.9 + ((column - 1) * 2.6)
			local y = -1.15 + ((row - 1) * 2.3)
			make("Part", {
				Name = "Bulb",
				Anchored = true,
				CanCollide = false,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 250, 225),
				Size = Vector3.new(1.45, 1.45, 0.42),
				CFrame = panel.CFrame * CFrame.new(x, y, -0.38),
			}, model)
		end
	end

	return model
end

local function createLightPost(parent, name, position, targetPosition)
	local model = make("Model", {
		Name = name,
	}, parent)

	local poleHeight = 11
	make("Part", {
		Name = "Pole",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(0.55, poleHeight, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, poleHeight / 2, 0)),
	}, model)

	local headPosition = position + Vector3.new(0, poleHeight + 0.65, 0)
	local head = make("Part", {
		Name = "LightHead",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(3.5, 1.55, 0.42),
		CFrame = CFrame.lookAt(headPosition, targetPosition),
	}, model)

	for index = 1, 3 do
		make("Part", {
			Name = "Bulb",
			Anchored = true,
			CanCollide = false,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 245, 210),
			Size = Vector3.new(0.72, 0.72, 0.25),
			CFrame = head.CFrame * CFrame.new(-1.1 + ((index - 1) * 1.1), 0, -0.3),
		}, model)
	end

	make("SpotLight", {
		Name = "PostBeam",
		Face = Enum.NormalId.Front,
		Color = Color3.fromRGB(255, 236, 188),
		Range = 48,
		Angle = 42,
		Brightness = 0.86,
		Shadows = false,
	}, head)

	make("PointLight", {
		Name = "PostFill",
		Color = Color3.fromRGB(255, 220, 150),
		Range = 13,
		Brightness = 0.18,
		Shadows = false,
	}, head)

	return model
end

local function createSoftFillLight(parent, name, position, range, brightness, color)
	local anchor = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
	}, parent)

	make("PointLight", {
		Name = "SoftFill",
		Color = color or Color3.fromRGB(255, 232, 178),
		Range = range,
		Brightness = brightness,
		Shadows = false,
	}, anchor)

	return anchor
end

local function createVerticalBanner(parent, name, position, lookTarget, title)
	local model = make("Model", {
		Name = name,
	}, parent)

	local bannerGold = Color3.fromRGB(255, 210, 50)
	local bannerW    = 4.8
	local bannerH    = 8.5
	local stripW     = 0.14

	-- Metal pole with gold cap
	make("Part", {
		Name = "Post",
		Anchored = true, CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(0.55, 10, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, 5, 0)),
	}, model)
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.40,
		Size = Vector3.new(0.55, 0.3, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, 10.2, 0)),
	}, model)

	local bannerCF = CFrame.lookAt(position + Vector3.new(0, 6.2, 0), lookTarget)

	-- Main banner panel
	local banner = make("Part", {
		Name = "Banner",
		Anchored = true, CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 11, 20),
		Size = Vector3.new(bannerW, bannerH, 0.35),
		CFrame = bannerCF,
	}, model)

	-- Neon gold left + right edge strips
	for _, xSign in ipairs({ -1, 1 }) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.35,
			Size = Vector3.new(stripW, bannerH + stripW * 2, 0.38),
			CFrame = bannerCF * CFrame.new(xSign * (bannerW / 2 + stripW / 2), 0, 0),
		}, model)
	end
	-- Neon gold top strip
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.35,
		Size = Vector3.new(bannerW + stripW * 2, stripW, 0.38),
		CFrame = bannerCF * CFrame.new(0, bannerH / 2 + stripW / 2, 0),
	}, model)
	-- Neon gold bottom strip
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.35,
		Size = Vector3.new(bannerW + stripW * 2, stripW, 0.38),
		CFrame = bannerCF * CFrame.new(0, -(bannerH / 2 + stripW / 2), 0),
	}, model)

	-- Subtle warm glow from banner face (dimmed — no bloom blast)
	make("PointLight", {
		Brightness = 0.35, Range = 8, Color = bannerGold,
	}, banner)

	createSurfaceText(banner, title, "")

	return model
end

local function createFanZoneBench(parent, name, position, facingPos)
	local model = make("Model", {
		Name = name,
	}, parent)

	local cframe = CFrame.lookAt(position + Vector3.new(0, 1.15, 0), Vector3.new(facingPos.X, position.Y + 1.15, facingPos.Z))

	make("Part", {
		Name = "Seat",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(132, 86, 42),
		Size = Vector3.new(7.2, 0.34, 1.25),
		CFrame = cframe,
	}, model)

	make("Part", {
		Name = "Back",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(116, 74, 36),
		Size = Vector3.new(7.2, 1.1, 0.28),
		CFrame = cframe * CFrame.new(0, 0.55, 0.76) * CFrame.Angles(math.rad(-10), 0, 0),
	}, model)

	for x = -2.7, 2.7, 5.4 do
		make("Part", {
			Name = "Leg",
			Anchored = true,
			CanCollide = true,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(28, 32, 42),
			Size = Vector3.new(0.26, 1.1, 0.26),
			CFrame = cframe * CFrame.new(x, -0.68, -0.28),
		}, model)
		make("Part", {
			Name = "Leg",
			Anchored = true,
			CanCollide = true,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(28, 32, 42),
			Size = Vector3.new(0.26, 1.1, 0.26),
			CFrame = cframe * CFrame.new(x, -0.68, 0.42),
		}, model)
	end

	return model
end

local function createFanZoneBoard(parent, name, position, facingPos, title, subtitle)
	local board = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(16, 3.2, 0.45),
		CFrame = CFrame.lookAt(position, Vector3.new(facingPos.X, position.Y, facingPos.Z)),
	}, parent)
	createSurfaceText(board, title, subtitle or "")
	return board
end

local function createWaypoint(parent, name, position)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(position),
	}, parent)
end

createSurfaceText = function(part, title, subtitle)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = make("SurfaceGui", {
			Face = face,
			PixelsPerStud = 90,
			LightInfluence = 0,
		}, part)

		local frame = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(8, 12, 20),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, gui)

		make("UIStroke", {
			Color = Color3.fromRGB(255, 215, 0),
			Thickness = 3,
		}, frame)

		createSignLabel(title, UDim2.fromScale(0.92, 0.42), UDim2.fromScale(0.04, 0.15), Color3.fromRGB(255, 215, 0), frame)
		if subtitle and subtitle ~= "" then
			local subtitleLabel = createSignLabel(subtitle, UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.07, 0.62), Color3.fromRGB(245, 238, 220), frame)
			subtitleLabel.Font = Enum.Font.GothamBold
		end
	end
end

local function createTurnstile(parent, cframe)
	local model = make("Model", {
		Name = "Turnstile",
	}, parent)

	local post = make("Part", {
		Name = "Post",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(170, 130, 42),
		Size = Vector3.new(0.35, 3.4, 0.35),
		CFrame = cframe,
	}, model)

	local arms = {}
	for index = 1, 4 do
		local angle = math.rad((index - 1) * 90)
		local arm = make("Part", {
			Name = "Arm" .. index,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(255, 215, 0),
			Size = Vector3.new(2.3, 0.14, 0.14),
			CFrame = cframe * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, angle, 0),
		}, model)
		table.insert(arms, { part = arm, angle = angle })
	end

	table.insert(animatedTurnstiles, {
		post = post,
		arms = arms,
		baseCFrame = cframe,
	})

	return model
end

local function startTurnstileAnimations()
	for _, turnstile in ipairs(animatedTurnstiles) do
		task.spawn(function()
			local spin = math.random() * math.pi
			while turnstile.post.Parent do
				spin += math.rad(4)
				for _, armData in ipairs(turnstile.arms) do
					if armData.part.Parent then
						armData.part.CFrame = turnstile.baseCFrame * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, spin + armData.angle, 0)
					end
				end
				task.wait(0.04)
			end
		end)
	end
end

local function createFanGate(parent, name, z, facingDirection)
	local gate = make("Model", {
		Name = name,
	}, parent)

	local center = Vector3.new(0, 0, z)
	local columnColor = Color3.fromRGB(24, 30, 42)
	local signColor = Color3.fromRGB(8, 12, 20)
	local lookDirection = Vector3.new(0, 0, facingDirection)

	make("Part", {
		Name = "LeftColumn",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = columnColor,
		Size = Vector3.new(4, 13, 4),
		CFrame = CFrame.new(center + Vector3.new(-17, 6.5, 0)),
	}, gate)

	make("Part", {
		Name = "RightColumn",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = columnColor,
		Size = Vector3.new(4, 13, 4),
		CFrame = CFrame.new(center + Vector3.new(17, 6.5, 0)),
	}, gate)

	make("Part", {
		Name = "TopBeam",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = columnColor,
		Size = Vector3.new(40, 3, 4),
		CFrame = CFrame.new(center + Vector3.new(0, 11.5, 0)),
	}, gate)

	local sign = make("Part", {
		Name = "WelcomeSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = signColor,
		Size = Vector3.new(30, 7.5, 0.5),
		CFrame = CFrame.lookAt(center + Vector3.new(0, 16.5, -facingDirection * 0.3), center + Vector3.new(0, 16.5, -facingDirection * 0.3) + lookDirection),
	}, gate)

	-- Custom sign GUI — fixed size constraints prevent text squishing on a wide panel
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = make("SurfaceGui", {
			Face = face,
			PixelsPerStud = 50,
			LightInfluence = 0,
		}, sign)

		local frame = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(8, 12, 20),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, gui)

		make("UIStroke", { Color = Color3.fromRGB(255, 215, 0), Thickness = 3 }, frame)

		-- Gold top accent bar
		make("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 215, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 8),
		}, frame)

		-- "WELCOME FANS!" — large, constrained so it doesn't over-stretch
		local title = make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.88, 0.52),
			Position = UDim2.fromScale(0.06, 0.07),
			Text = "WELCOME FANS!",
			TextColor3 = Color3.fromRGB(255, 215, 0),
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, frame)
		make("UITextSizeConstraint", { MaxTextSize = 110, MinTextSize = 20 }, title)

		-- Divider
		make("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 215, 0),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.75, 0.022),
			Position = UDim2.fromScale(0.125, 0.62),
		}, frame)

		-- "TURNSTILES" — smaller subtitle
		local sub = make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.6, 0.26),
			Position = UDim2.fromScale(0.2, 0.66),
			Text = "TURNSTILES",
			TextColor3 = Color3.fromRGB(195, 188, 168),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, frame)
		make("UITextSizeConstraint", { MaxTextSize = 55, MinTextSize = 10 }, sub)
	end

	for index = 1, 3 do
		local x = -8 + ((index - 1) * 8)
		createTurnstile(gate, CFrame.new(center + Vector3.new(x, 2.1, -facingDirection * 2)))
	end

	return gate
end

-- ── Food kiosk ────────────────────────────────────────────────────────────────
-- Concession stand with bright red/yellow market colours so it reads clearly
-- against the dark plaza.  `position` is the base centre (Y=0).
-- `facingPos` is the direction the serving counter faces (toward the walkway).
local function sanitizeImportedAsset(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = true
		end
	end
end

local function tryCreateImportedKiosk(parent, name, position, signText, facingPos, assetId)
	if type(assetId) ~= "number" or assetId <= 0 then
		return nil
	end

	local loadedOk, assetRoot = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not loadedOk or not assetRoot then
		warn("[BaseService] Could not load kiosk asset", assetId, assetRoot)
		return nil
	end

	local model = make("Model", { Name = name }, parent)
	for _, child in ipairs(assetRoot:GetChildren()) do
		child.Parent = model
	end
	assetRoot:Destroy()
	sanitizeImportedAsset(model)

	local hasParts = false
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			hasParts = true
			break
		end
	end

	if not hasParts then
		model:Destroy()
		warn("[BaseService] Kiosk asset has no usable parts", assetId)
		return nil
	end

	local _, size = model:GetBoundingBox()
	local maxHorizontal = math.max(size.X, size.Z, 0.1)
	local scale = math.clamp(8.5 / maxHorizontal, 0.15, 4)
	pcall(function()
		model:ScaleTo(scale)
	end)

	local targetCFrame = CFrame.lookAt(
		position,
		Vector3.new(facingPos.X, position.Y, facingPos.Z)
	)
	model:PivotTo(targetCFrame)

	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	model:PivotTo(model:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))

	local sign = make("Part", {
		Name = "KioskLoadedSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(255, 183, 53),
		Transparency = 0.0,
		Size = Vector3.new(5.2, 1.05, 0.2),
		CFrame = targetCFrame * CFrame.new(0, 4.6, 2.15),
	}, model)
	local signGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 90,
		LightInfluence = 0,
	}, sign)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = signText,
		TextColor3 = Color3.fromRGB(20, 12, 0),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, signGui)

	return model
end

-- Per-stall colour palettes so each fallback booth looks distinct even
-- when InsertService can't load the Toolbox model.
local KIOSK_THEMES = {
	-- 1: POPCORN — warm butter yellow
	{ booth = Color3.fromRGB(34, 28, 10),  canopy = Color3.fromRGB(252, 210, 0),  stripe = Color3.fromRGB(232, 160, 0),  sign = Color3.fromRGB(255, 210, 40),  light = Color3.fromRGB(255, 215, 80) },
	-- 2: HOT DOGS — classic red & mustard
	{ booth = Color3.fromRGB(168, 28, 18),  canopy = Color3.fromRGB(232, 48, 24),  stripe = Color3.fromRGB(248, 195, 0),  sign = Color3.fromRGB(255, 185, 30),  light = Color3.fromRGB(255, 140, 40) },
	-- 3: BURGERS — rich brown & orange
	{ booth = Color3.fromRGB(82, 44, 14),   canopy = Color3.fromRGB(188, 100, 24), stripe = Color3.fromRGB(240, 155, 30), sign = Color3.fromRGB(248, 130, 18),  light = Color3.fromRGB(240, 120, 30) },
	-- 4: DRINKS — cool blue & cyan
	{ booth = Color3.fromRGB(14, 42, 88),   canopy = Color3.fromRGB(28, 120, 200), stripe = Color3.fromRGB(60, 200, 228), sign = Color3.fromRGB(90, 200, 255),  light = Color3.fromRGB(80, 180, 255) },
}

local function createFoodKiosk(parent, name, position, kioskIndex, facingPos)
	local assets = fanZoneConfig.KioskAssets
	local asset = type(assets) == "table" and assets[kioskIndex or 1]
	local assetId = asset and asset.id or 0
	local signText = asset and asset.label or "FOOD"
	local importedModel = tryCreateImportedKiosk(parent, name, position, signText, facingPos, assetId)
	if importedModel then
		return importedModel
	end

	-- Fallback: hand-built primitive booth with a theme unique to this stall.
	local theme = KIOSK_THEMES[kioskIndex] or KIOSK_THEMES[1]

	local model = make("Model", { Name = name }, parent)

	local flatFacing = Vector3.new(facingPos.X, 0, facingPos.Z)
	local boothCF = CFrame.lookAt(position + Vector3.new(0, 2.1, 0), flatFacing + Vector3.new(0, 2.1, 0))

	-- Main booth body
	make("Part", {
		Name = "Booth",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = theme.booth,
		Size = Vector3.new(6.5, 4.2, 2.4),
		CFrame = boothCF,
	}, model)

	-- White trim band across the top of the booth front
	make("Part", {
		Name = "BoothTopTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(238, 232, 215),
		Size = Vector3.new(6.5, 0.32, 2.42),
		CFrame = boothCF * CFrame.new(0, 2.26, 0),
	}, model)

	-- Serving counter — wood-look tan slab protruding toward customers
	make("Part", {
		Name = "Counter",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(205, 172, 112),
		Size = Vector3.new(6.5, 0.30, 1.2),
		CFrame = boothCF * CFrame.new(0, 0.45, 1.32),
	}, model)

	-- Canopy
	make("Part", {
		Name = "Canopy",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = theme.canopy,
		Size = Vector3.new(8.0, 0.40, 4.6),
		CFrame = boothCF * CFrame.new(0, 2.38, 0.95),
	}, model)

	-- Three contrasting stripes across the canopy
	for i = 1, 3 do
		make("Part", {
			Name = "CanopyStripe" .. i,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.SmoothPlastic,
			Color = theme.stripe,
			Size = Vector3.new(8.0, 0.42, 0.62),
			CFrame = boothCF * CFrame.new(0, 2.39, -1.0 + (i - 1) * 1.08),
		}, model)
	end

	-- Sign above the canopy — themed colour per stall
	local sign = make("Part", {
		Name = "KioskSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = theme.sign,
		Transparency = 0.0,
		Size = Vector3.new(6.0, 1.4, 0.22),
		CFrame = boothCF * CFrame.new(0, 3.55, 1.24),
	}, model)

	local signGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 100,
		LightInfluence = 0,
	}, sign)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = signText,
		TextColor3 = Color3.fromRGB(12, 8, 2),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, signGui)

	return model
end

local function createStallWorker(parent, name, groundPosition, facingPos, shirtColor)
	local model = make("Model", {
		Name = name,
	}, parent)

	local skinColor = Color3.fromRGB(234, 184, 146)
	local pantsColor = Color3.fromRGB(22, 26, 34)
	local pivotPosition = Vector3.new(groundPosition.X, 3.1, groundPosition.Z)
	local flatFacing = Vector3.new(facingPos.X, pivotPosition.Y, facingPos.Z)
	local pivot = CFrame.lookAt(pivotPosition, flatFacing)

	local function part(partName, size, localCFrame, color, material)
		return make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = material or Enum.Material.SmoothPlastic,
			Color = color,
			Size = size,
			CFrame = pivot * localCFrame,
		}, model)
	end

	part("Torso", Vector3.new(1.45, 1.55, 0.75), CFrame.new(0, 0, 0), shirtColor)

	local head = part("Head", Vector3.new(1.05, 1.05, 1.05), CFrame.new(0, 1.33, 0), skinColor)
	make("SpecialMesh", {
		MeshType = Enum.MeshType.Head,
		Scale = Vector3.new(1.05, 1.05, 1.05),
	}, head)
	make("Decal", {
		Name = "Face",
		Texture = "rbxasset://textures/face.png",
		Face = Enum.NormalId.Front,
	}, head)

	part("Left Arm", Vector3.new(0.62, 1.5, 0.62), CFrame.new(-1.03, -0.02, 0), skinColor)
	part("Right Arm", Vector3.new(0.62, 1.5, 0.62), CFrame.new(1.03, -0.02, 0), skinColor)
	part("Left Leg", Vector3.new(0.62, 1.7, 0.62), CFrame.new(-0.36, -1.45, 0), pantsColor)
	part("Right Leg", Vector3.new(0.62, 1.7, 0.62), CFrame.new(0.36, -1.45, 0), pantsColor)

	local apron = part("Apron", Vector3.new(1.16, 0.72, 0.08), CFrame.new(0, -0.18, -0.41), Color3.fromRGB(245, 238, 215), Enum.Material.SmoothPlastic)
	_ = apron

	return model
end

local function createFanZone(mapWidth, mapLength)
	local plaza = make("Model", {
		Name = "FanZone",
	}, basesFolder)

	local modelAssets = fanZoneConfig.ModelAssets or {}
	local waypointFolder = make("Folder", {
		Name = "Waypoints",
	}, plaza)

	local northZ = (mapLength / 2) - 32
	local southZ = -(mapLength / 2) + 32

	make("Part", {
		Name = "MainWalkway",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(54, 63, 80),
		Size = Vector3.new(54, 0.18, mapLength - 64),
		CFrame = CFrame.new(0, 0.24, 0),
	}, plaza)
	make("Part", {
		Name = "MainWalkwayLeftEdge",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(210, 168, 52),
		Transparency = 0.42,
		Size = Vector3.new(0.28, 0.08, mapLength - 78),
		CFrame = CFrame.new(-27, 0.38, 0),
	}, plaza)
	make("Part", {
		Name = "MainWalkwayRightEdge",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(210, 168, 52),
		Transparency = 0.42,
		Size = Vector3.new(0.28, 0.08, mapLength - 78),
		CFrame = CFrame.new(27, 0.38, 0),
	}, plaza)

	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		make("Part", {
			Name = "StadiumPath" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(58, 66, 82),
			Size = Vector3.new((layout.SideOffset * 2) - 22, 0.14, 14),
			CFrame = CFrame.new(0, 0.28, laneZ),
		}, plaza)
		make("Part", {
			Name = "StadiumPathGuideA" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(210, 168, 52),
			Transparency = 0.78,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.08),
			CFrame = CFrame.new(0, 0.4, laneZ - 6.8),
		}, plaza)
		make("Part", {
			Name = "StadiumPathGuideB" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(210, 168, 52),
			Transparency = 0.78,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.08),
			CFrame = CFrame.new(0, 0.4, laneZ + 6.8),
		}, plaza)
	end

	-- ── Pathway lighting ─────────────────────────────────────────────────────
	-- Warm overhead lights every 56 studs along the main walkway
	do
		local LAMP_SPACING = 56
		local lampZ = southZ + 28
		while lampZ < northZ - 20 do
			local anchor = make("Part", {
				Name = "WalkwayLampAnchor",
				Anchored = true, CanCollide = false,
				Transparency = 1,
				Size = Vector3.new(1, 1, 1),
				CFrame = CFrame.new(0, 7.5, lampZ),
			}, plaza)
			make("PointLight", {
				Color = Color3.fromRGB(255, 224, 160),
				Range = 38,
				Brightness = 0.42,
				Shadows = false,
			}, anchor)
			lampZ = lampZ + LAMP_SPACING
		end
	end

	-- Gold accent lights at each stadium lane crossing
	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		for _, xSide in ipairs({ -22, 22 }) do
			local crossAnchor = make("Part", {
				Name = "LaneCrossLamp",
				Anchored = true, CanCollide = false,
				Transparency = 1,
				Size = Vector3.new(1, 1, 1),
				CFrame = CFrame.new(xSide, 5.5, laneZ),
			}, plaza)
			make("PointLight", {
				Color = Color3.fromRGB(255, 210, 80),
				Range = 26,
				Brightness = 0.32,
				Shadows = false,
			}, crossAnchor)
		end
	end

	-- ── FAN ZONE deck: a clean centre area that separates the statue and
	-- concessions from the travel lanes, so the plaza no longer feels like
	-- random props dropped into the road.
	make("Part", {
		Name = "FanZoneDeck",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(36, 43, 57),
		Size = Vector3.new(54, 0.12, 46),
		CFrame = CFrame.new(0, 0.43, 0),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckNorthTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(54, 0.08, 0.28),
		CFrame = CFrame.new(0, 0.52, -23),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckSouthTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(54, 0.08, 0.28),
		CFrame = CFrame.new(0, 0.52, 23),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckWestTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(0.28, 0.08, 46),
		CFrame = CFrame.new(-27, 0.52, 0),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckEastTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(0.28, 0.08, 46),
		CFrame = CFrame.new(27, 0.52, 0),
	}, plaza)

	-- ── Centre podium: three stepped tiers + elevated spinning football ──────────
	-- Roblox cylinders have their length along X, so we rotate 90° on Z to stand
	-- them upright (flat faces become top/bottom).

	-- Tier 1 — wide base (bottom at Y=0, top at Y=3.2)
	make("Part", {
		Name = "PedestalTier1",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 14, 24),
		Size = Vector3.new(3.2, 24, 24),
		CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Tier 2 — mid (bottom ≈ Y=3.3, top ≈ Y=5.9)
	make("Part", {
		Name = "PedestalTier2",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(14, 19, 32),
		Size = Vector3.new(2.6, 16, 16),
		CFrame = CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Tier 3 — top plinth (bottom ≈ Y=6.1, top ≈ Y=8.4)
	make("Part", {
		Name = "PedestalTier3",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 24, 40),
		Size = Vector3.new(2.3, 10, 10),
		CFrame = CFrame.new(0, 7.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- ── Planter ring around the podium ────────────────────────────────
	-- Six smaller planters form a decorative circle at radius 17, just
	-- outside the Tier1 ring (radius ≈ 12).
	local RING_RADIUS = 17
	local RING_COUNT = 6
	for ringIndex = 1, RING_COUNT do
		local angle = math.rad((ringIndex - 1) * (360 / RING_COUNT))
		createPlanter(plaza, Vector3.new(math.cos(angle) * RING_RADIUS, 0, math.sin(angle) * RING_RADIUS), 0.52)
	end

	local statue = tryCreateImportedDecor(plaza, "FootballStatue", modelAssets.FootballStatue, Vector3.new(0, 8.45, 0), Vector3.new(0, 8.45, -12), 12.0)
	if not statue then
		-- Gold football fallback (centre at Y=12.0, radius=3.5 -> bottom Y=8.5)
		local ball = make("Part", {
			Name = "GoldFootball",
			Anchored = true,
			CanCollide = false,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(255, 202, 61),
			Size = Vector3.new(7, 7, 7),
			CFrame = CFrame.new(0, 12.0, 0),
		}, plaza)

		make("PointLight", {
			Color = Color3.fromRGB(255, 215, 0),
			Range = 16,
			Brightness = 0.38,
			Shadows = false,
		}, ball)

		-- Slow spin + tilt so the ball looks like it's rolling in the air.
		task.spawn(function()
			local ballAngle = 0
			local ballBaseY = 12.0
			while ball.Parent do
				ballAngle = ballAngle + math.rad(20) / 30
				local floatOffset = math.sin(os.clock() * 0.85) * 0.38
				ball.CFrame = CFrame.new(0, ballBaseY + floatOffset, 0)
					* CFrame.Angles(math.rad(22), ballAngle, 0)
				task.wait(1 / 30)
			end
		end)
	end

	createFanZoneBoard(plaza, "FanZoneSouthBoard", Vector3.new(0, 3.2, -16), Vector3.new(0, 3.2, -40), "FAN ZONE", "FOOD  •  FANS  •  FOOTBALL")
	createFanZoneBoard(plaza, "FanZoneNorthBoard", Vector3.new(0, 3.2, 16), Vector3.new(0, 3.2, 40), "FAN ZONE", "FOOD  •  FANS  •  FOOTBALL")

	createFanGate(plaza, "NorthFanGate", northZ, -1)
	createFanGate(plaza, "SouthFanGate", southZ, 1)

	-- ── Food & drinks kiosks ──────────────────────────────────────────
	-- Four stalls form a clean food-court shape outside the central deck.
	-- NPCs detour here as they pass through the plaza, then carry on.
	-- Y=0.35 sits the booth base flush on the plaza surface (top ≈ Y=0.33)
	local center0 = Vector3.new(0, 0.35, 0)  -- all stalls face the podium

	createFoodKiosk(plaza, "KioskNW",
		Vector3.new(-36, 0.35, -15), 1, center0)  -- POPCORN

	createFoodKiosk(plaza, "KioskNE",
		Vector3.new(36, 0.35, -15),  2, center0)  -- HOT DOGS

	createFoodKiosk(plaza, "KioskSW",
		Vector3.new(-36, 0.35, 15),  3, center0)  -- BURGERS

	createFoodKiosk(plaza, "KioskSE",
		Vector3.new(36, 0.35, 15),   4, center0)  -- DRINKS

	-- Static stall workers make the food court feel staffed, while moving
	-- crowd NPCs stop at the matching named waypoints below.
	createStallWorker(plaza, "PopcornWorker", Vector3.new(-39.8, 0, -16.6), center0, Color3.fromRGB(248, 203, 42))
	createStallWorker(plaza, "HotDogWorker", Vector3.new(39.8, 0, -16.6), center0, Color3.fromRGB(218, 46, 28))
	createStallWorker(plaza, "BurgerWorker", Vector3.new(-39.8, 0, 16.6), center0, Color3.fromRGB(198, 106, 34))
	createStallWorker(plaza, "DrinkWorker", Vector3.new(39.8, 0, 16.6), center0, Color3.fromRGB(44, 150, 218))

	createFanZoneBench(plaza, "BenchSouthWest", Vector3.new(-15, 0.35, -25), center0)
	createFanZoneBench(plaza, "BenchSouthEast", Vector3.new(15, 0.35, -25), center0)
	createFanZoneBench(plaza, "BenchNorthWest", Vector3.new(-15, 0.35, 25), center0)
	createFanZoneBench(plaza, "BenchNorthEast", Vector3.new(15, 0.35, 25), center0)

	local planterPositions = {
		Vector3.new(-28, 0, -23),
		Vector3.new(28, 0, -23),
		Vector3.new(-28, 0, 23),
		Vector3.new(28, 0, 23),
		Vector3.new(-18, 0, northZ - 18),
		Vector3.new(18, 0, northZ - 18),
		Vector3.new(-18, 0, southZ + 18),
		Vector3.new(18, 0, southZ + 18),
	}
	for _, planterPosition in ipairs(planterPositions) do
		createPlanter(plaza, planterPosition, 0.9)
	end

	createSoftFillLight(plaza, "CenterPlazaFill", Vector3.new(0, 13, 0), 78, 0.3, Color3.fromRGB(255, 225, 170))
	createSoftFillLight(plaza, "NorthPlazaFill", Vector3.new(0, 13, northZ - 8), 68, 0.22, Color3.fromRGB(230, 238, 255))
	createSoftFillLight(plaza, "SouthPlazaFill", Vector3.new(0, 13, southZ + 8), 68, 0.22, Color3.fromRGB(230, 238, 255))
	-- Wide overhead fills directly above the west and east stadium blocks
	createSoftFillLight(plaza, "WestStadiumFill", Vector3.new(-layout.SideOffset, 18, 0), 88, 0.24, Color3.fromRGB(240, 228, 200))
	createSoftFillLight(plaza, "EastStadiumFill", Vector3.new(layout.SideOffset, 18, 0), 88, 0.24, Color3.fromRGB(240, 228, 200))
	-- Per-lane fills so each plot row is independently lit
	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		createSoftFillLight(plaza, "WestLaneFill" .. laneIndex, Vector3.new(-layout.SideOffset, 20, laneZ), 64, 0.18, Color3.fromRGB(235, 225, 195))
		createSoftFillLight(plaza, "EastLaneFill" .. laneIndex, Vector3.new(layout.SideOffset, 20, laneZ), 64, 0.18, Color3.fromRGB(235, 225, 195))
	end

	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		createLightPost(plaza, "LaneWestLightA" .. laneIndex, Vector3.new(-47, 0, laneZ - 24), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneWestLightB" .. laneIndex, Vector3.new(-47, 0, laneZ + 24), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightA" .. laneIndex, Vector3.new(47, 0, laneZ - 24), Vector3.new(layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightB" .. laneIndex, Vector3.new(47, 0, laneZ + 24), Vector3.new(layout.SideOffset, 1, laneZ))
	end

	-- ── Player spawn ─────────────────────────────────────────────────
	-- Roblox Studio adds a default SpawnLocation at (0,0,0) which drops
	-- players onto the central podium.  Remove EVERY SpawnLocation in the
	-- Workspace (including the studio default) then place ours just inside
	-- the south gate so players start at the fan zone entrance.
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
	local spawnLoc = make("SpawnLocation", {
		Name = "FanZoneSpawn",
		Anchored = true,
		CanCollide = true,
		Neutral = true,
		AllowTeamChangeOnTouch = false,
		Duration = 0,
		Transparency = 1,
		Size = Vector3.new(8, 1, 8),
		CFrame = CFrame.new(0, 0.75, southZ + 6),
	}, Workspace)
	_ = spawnLoc

	createWaypoint(waypointFolder, "NorthGate", Vector3.new(0, 3.1, northZ - 10))
	createWaypoint(waypointFolder, "SouthGate", Vector3.new(0, 3.1, southZ + 10))
	createWaypoint(waypointFolder, "Center", Vector3.new(0, 3.1, 0))
	createWaypoint(waypointFolder, "WestLoop", Vector3.new(-16, 3.1, 0))
	createWaypoint(waypointFolder, "EastLoop", Vector3.new(16, 3.1, 0))
	-- Food stand queues: each stall has 4 queue slots running diagonally
	-- back from the counter toward the centre walkway.  Slot 1 is the
	-- front of the queue (talking to the worker), slot 4 is the back.
	-- CrowdService claims slots 1→4 in order so NPCs naturally line up.
	local stallQueueDefs = {
		{ name = "Popcorn", baseX = -36, baseZ = -15 },
		{ name = "HotDogs", baseX =  36, baseZ = -15 },
		{ name = "Burgers", baseX = -36, baseZ =  15 },
		{ name = "Drinks",  baseX =  36, baseZ =  15 },
	}
	for _, stall in ipairs(stallQueueDefs) do
		-- Direction from stall toward plaza centre (0, 0)
		local dx, dz = -stall.baseX, -stall.baseZ
		local mag = math.sqrt((dx * dx) + (dz * dz))
		local ux, uz = dx / mag, dz / mag
		for slot = 1, 4 do
			local d = 4 + (slot * 3)  -- 7, 10, 13, 16 studs from stall
			local px = stall.baseX + (ux * d)
			local pz = stall.baseZ + (uz * d)
			createWaypoint(
				waypointFolder,
				"Food" .. stall.name .. slot,
				Vector3.new(px, 3.1, pz)
			)
		end
	end

	startTurnstileAnimations()
	return plaza
end

local function createDisplayCardFace(face, card, incomePerSecond, parent)
	local style = Utils.GetRarityStyle(card.rarity)
	local rarityColor = style.primary
	local secondaryColor = style.secondary or rarityColor
	local darkColor = style.dark or Color3.fromRGB(16, 12, 8)
	local trimColor = style.trim or rarityColor
	local textColor = style.text or Constants.UI.Text
	local rarityLabel = string.upper(style.label or card.rarity or "CARD")

	local gui = make("SurfaceGui", {
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, parent)

	local frame = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = darkColor,
		BorderSizePixel = 0,
	}, gui)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12)),
			ColorSequenceKeypoint.new(0.42, secondaryColor),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 138,
	}, frame)

	make("UIStroke", {
		Color = trimColor,
		Thickness = 4,
	}, frame)

	local innerBorder = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, -14),
		Position = UDim2.fromOffset(7, 7),
	}, frame)
	make("UIStroke", {
		Color = Color3.fromRGB(24, 16, 4),
		Thickness = 1.5,
		Transparency = 0.55,
	}, innerBorder)

	local rarityBand = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(6, 7, 10),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Size = UDim2.new(0.76, 0, 0.1, 0),
		Position = UDim2.new(0.12, 0, 0.06, 0),
	}, frame)
	local rarityCorner = Instance.new("UICorner")
	rarityCorner.CornerRadius = UDim.new(1, 0)
	rarityCorner.Parent = rarityBand
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.4,
		Transparency = 0.2,
	}, rarityBand)
	local rarityText = createSignLabel(rarityLabel, UDim2.fromScale(0.92, 0.82), UDim2.fromScale(0.04, 0.09), textColor, rarityBand)
	make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 18 }, rarityText)

	local positionBadge = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(9, 11, 17),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.new(0.24, 0, 0.1, 0),
		Position = UDim2.new(0.1, 0, 0.2, 0),
	}, frame)
	local positionCorner = Instance.new("UICorner")
	positionCorner.CornerRadius = UDim.new(0.25, 0)
	positionCorner.Parent = positionBadge
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.2,
		Transparency = 0.25,
	}, positionBadge)
	createSignLabel(card.position or "--", UDim2.fromScale(0.9, 0.82), UDim2.fromScale(0.05, 0.09), textColor, positionBadge)

	local nationLabel = createSignLabel(card.nation or "Unknown", UDim2.new(0.48, 0, 0.08, 0), UDim2.new(0.41, 0, 0.21, 0), textColor, frame)
	nationLabel.TextXAlignment = Enum.TextXAlignment.Right
	make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 14 }, nationLabel)

	local portrait = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(2, 3, 6),
		BackgroundTransparency = 0.24,
		BorderSizePixel = 0,
		Size = UDim2.new(0.54, 0, 0.29, 0),
		Position = UDim2.new(0.23, 0, 0.34, 0),
	}, frame)
	local portraitCorner = Instance.new("UICorner")
	portraitCorner.CornerRadius = UDim.new(0.18, 0)
	portraitCorner.Parent = portrait
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1,
		Transparency = 0.55,
	}, portrait)

	local head = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = textColor,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.12, 0),
		Size = UDim2.fromScale(0.26, 0.25),
	}, portrait)
	local headCorner = Instance.new("UICorner")
	headCorner.CornerRadius = UDim.new(1, 0)
	headCorner.Parent = head

	local shoulders = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = textColor,
		BackgroundTransparency = 0.26,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.43, 0),
		Size = UDim2.fromScale(0.58, 0.34),
	}, portrait)
	local shouldersCorner = Instance.new("UICorner")
	shouldersCorner.CornerRadius = UDim.new(0.35, 0)
	shouldersCorner.Parent = shoulders

	make("Frame", {
		BackgroundColor3 = trimColor,
		BorderSizePixel = 0,
		Size = UDim2.new(0.72, 0, 0, 2),
		Position = UDim2.new(0.14, 0, 0.67, 0),
	}, frame)

	local nameLabel = createSignLabel(string.upper(card.name or "Player"), UDim2.new(0.84, 0, 0.12, 0), UDim2.new(0.08, 0, 0.7, 0), textColor, frame)
	make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 18 }, nameLabel)
	make("UIStroke", {
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 1.2,
		Transparency = 0.3,
	}, nameLabel)

	local incomePill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(26, 58, 32),
		Size = UDim2.new(0.72, 0, 0.11, 0),
		Position = UDim2.new(0.14, 0, 0.84, 0),
		BorderSizePixel = 0,
	}, frame)
	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = incomePill
	make("UIStroke", {
		Color = Color3.fromRGB(126, 214, 142),
		Thickness = 1.5,
		Transparency = 0.3,
	}, incomePill)

	createSignLabel("+" .. tostring(incomePerSecond) .. " fans/s", UDim2.fromScale(0.9, 0.72), UDim2.fromScale(0.05, 0.14), Color3.fromRGB(228, 255, 220), incomePill)
end

local function clearDisplayCard(slot)
	if slot.cardModel and slot.cardModel.Parent then
		slot.cardModel:Destroy()
	end
	slot.cardModel = nil
	slot.model:SetAttribute("Occupied", false)
end

local function setSlotPrompt(slot, actionText, objectText, enabled)
	slot.prompt.ActionText = actionText
	slot.prompt.ObjectText = objectText
	slot.prompt.Enabled = enabled
end

local function createDisplaySlot(parent, index, cframe, lookDirection)
	local model = make("Model", {
		Name = "DisplaySlot" .. index,
	}, parent)

	local slotW = layout.DisplaySlotSize.X
	local slotH = layout.DisplaySlotSize.Y
	local slotD = layout.DisplaySlotSize.Z
	local topY  = slotH / 2

	-- Pedestal body — dark polished concrete
	local base = make("Part", {
		Name = "Base",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(14, 19, 30),
		Size = layout.DisplaySlotSize,
		CFrame = cframe,
	}, model)

	-- Slim gold neon rim around the top edge (4 strips)
	local rimThickness = 0.22
	local rimHeight    = 0.28
	local rimY         = topY + rimHeight / 2
	local rimColor     = Color3.fromRGB(255, 210, 60)
	local rimTransp    = 0.28
	for _, axis in ipairs({
		{ Vector3.new(slotW, rimHeight, rimThickness), Vector3.new(0,  rimY, -(slotD / 2)) },
		{ Vector3.new(slotW, rimHeight, rimThickness), Vector3.new(0,  rimY,  (slotD / 2)) },
		{ Vector3.new(rimThickness, rimHeight, slotD), Vector3.new(-(slotW / 2), rimY, 0)  },
		{ Vector3.new(rimThickness, rimHeight, slotD), Vector3.new( (slotW / 2), rimY, 0)  },
	}) do
		make("Part", {
			Name = "RimStrip",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = rimColor,
			Transparency = rimTransp,
			Size = axis[1],
			CFrame = cframe + axis[2],
		}, model)
	end

	-- Gold glow display pad on top
	local top = make("Part", {
		Name = "Top",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 205, 50),
		Transparency = 0.52,
		Size = Vector3.new(slotW - 1.6, 0.14, slotD - 1.6),
		CFrame = base.CFrame + Vector3.new(0, topY + 0.08, 0),
	}, model)

	-- Slot number on the player-facing face. Ground slots face across Z; upper
	-- terrace slots face across X toward the pitch.
	local numFace
	if math.abs(lookDirection.X) > math.abs(lookDirection.Z) then
		numFace = lookDirection.X > 0 and Enum.NormalId.Right or Enum.NormalId.Left
	else
		numFace = lookDirection.Z > 0 and Enum.NormalId.Back or Enum.NormalId.Front
	end
	local numGui = make("SurfaceGui", {
		Name = "SlotNum",
		Face = numFace,
		AlwaysOnTop = false,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 30,
	}, base)
	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = tostring(index),
		TextColor3 = Color3.fromRGB(255, 210, 60),
		TextTransparency = 0.36,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, numGui)

	local prompt = make("ProximityPrompt", {
		Name = "SlotPrompt",
		ActionText = "Add Player",
		ObjectText = "Inventory Empty",
		KeyboardKeyCode = Enum.KeyCode.E,
		HoldDuration = 0.65,
		MaxActivationDistance = 10,
		RequiresLineOfSight = false,
		Enabled = false,
	}, base)

	model:SetAttribute("SlotIndex", index)
	model:SetAttribute("Occupied", false)

	return {
		model = model,
		base = base,
		top = top,
		prompt = prompt,
		slotIndex = index,
		lookDirection = lookDirection,
		cardModel = nil,
	}
end

-- ── Display-slot world offsets (local space, X scaled by facingDirection) ─────
-- Slots 1-6  : base layout (every player starts with these)
-- Slots 7-18 : unlocked one-per-rebirth on the raised Rebirth Terrace.
-- Slot X values are multiplied by facingDirection later, so negative X means
-- "toward the back wall" for both left- and right-side plots.
local ALL_SLOT_OFFSETS = {
	-- Ground floor (always present) — 2 rows of 3 across the pitch
	Vector3.new(-12, 1.75, -14),  -- 1
	Vector3.new(  0, 1.75, -14),  -- 2
	Vector3.new( 12, 1.75, -14),  -- 3
	Vector3.new(-12, 1.75,  14),  -- 4
	Vector3.new(  0, 1.75,  14),  -- 5
	Vector3.new( 12, 1.75,  14),  -- 6
	-- Rebirth Terrace row 1 — closest to pitch, six slots across the back.
	Vector3.new(-22, 17.75, -17.5), -- 7
	Vector3.new(-22, 17.75, -10.5), -- 8
	Vector3.new(-22, 17.75,  -3.5), -- 9
	Vector3.new(-22, 17.75,   3.5), -- 10
	Vector3.new(-22, 17.75,  10.5), -- 11
	Vector3.new(-22, 17.75,  17.5), -- 12
	-- Rebirth Terrace row 2 — future expansion capacity.
	Vector3.new(-30, 17.75, -17.5), -- 13
	Vector3.new(-30, 17.75, -10.5), -- 14
	Vector3.new(-30, 17.75,  -3.5), -- 15
	Vector3.new(-30, 17.75,   3.5), -- 16
	Vector3.new(-30, 17.75,  10.5), -- 17
	Vector3.new(-30, 17.75,  17.5), -- 18
}

local function slotLookDir(localOffset, facingDirection)
	if localOffset.Y > 5 then
		-- Upper terrace cards face inward toward the pitch/entrance.
		return Vector3.new(facingDirection, 0, 0)
	end

	-- Ground-floor slots use Z-based facing:
	-- back row (Z < 0) faces south (+Z); front row (Z > 0) faces north (-Z).
	return localOffset.Z < 0 and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1)
end

local function createSecondFloorDisplayGallery(parent, baseCFrame, facingDirection)
	local deckColor = Color3.fromRGB(14, 19, 31)
	local railColor = Color3.fromRGB(26, 36, 54)
	local supportColor = Color3.fromRGB(18, 26, 40)
	local gold = Color3.fromRGB(255, 210, 55)
	local stepColor = Color3.fromRGB(18, 24, 35)

	local deckLocalY = 15.72 -- top lands at local Y 16.0, matching upper slot bottoms.
	local deckCenterX = -26 * facingDirection
	local deckSize = Vector3.new(18, 0.56, 43)
	local deckTopLocalY = deckLocalY + (deckSize.Y / 2)
	local deckBottomLocalY = deckLocalY - (deckSize.Y / 2)
	local supportHeight = deckBottomLocalY - 0.5
	local supportCenterY = 0.5 + (supportHeight / 2)

	local deck = make("Part", {
		Name = "RebirthTerraceDeck",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = deckColor,
		Size = deckSize,
		CFrame = baseCFrame * CFrame.new(deckCenterX, deckLocalY, 0),
	}, parent)

	make("Part", {
		Name = "RebirthTerraceFrontGlow",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = gold,
		Transparency = 0.5,
		Size = Vector3.new(0.18, 0.1, deckSize.Z - 2),
		CFrame = baseCFrame * CFrame.new((-17.2 * facingDirection), deckLocalY + 0.34, 0),
	}, parent)

	make("Part", {
		Name = "RebirthTerraceBackRail",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = railColor,
		Size = Vector3.new(0.45, 1.25, deckSize.Z),
		CFrame = baseCFrame * CFrame.new((-35.2 * facingDirection), deckLocalY + 0.98, 0),
	}, parent)

	for _, z in ipairs({ -21.8, 21.8 }) do
		make("Part", {
			Name = "RebirthTerraceSideRail",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = railColor,
			Size = Vector3.new(deckSize.X, 1.1, 0.35),
			CFrame = baseCFrame * CFrame.new(deckCenterX, deckLocalY + 0.92, z),
		}, parent)
	end

	for _, x in ipairs({ -19, -26, -33 }) do
		for _, z in ipairs({ -18, 0, 18 }) do
			make("Part", {
				Name = "RebirthTerraceSupport",
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Material = Enum.Material.SmoothPlastic,
				Color = supportColor,
				Size = Vector3.new(0.55, supportHeight, 0.55),
				CFrame = baseCFrame * CFrame.new(x * facingDirection, supportCenterY, z),
			}, parent)
		end
	end

	-- Two staircases make the new floor read as reachable/intentional rather
	-- than a floating shelf. They are visual only, so they won't snag players.
	for _, zSign in ipairs({ -1, 1 }) do
		local stairSteps = 18
		for step = 1, stairSteps do
			local alpha = (step - 1) / (stairSteps - 1)
			local x = (-10.5 - (alpha * 12)) * facingDirection
			local y = 0.72 + (alpha * (deckTopLocalY - 0.72))
			local z = zSign * (19.4 + (alpha * 1.9))
			local stepPart = make("Part", {
				Name = "RebirthTerraceStair",
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Material = Enum.Material.SmoothPlastic,
				Color = stepColor,
				Size = Vector3.new(3.1, 0.32, 3.2),
				CFrame = baseCFrame * CFrame.new(x, y, z),
			}, parent)

			make("Part", {
				Name = stepPart.Name .. "Glow",
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Material = Enum.Material.Neon,
				Color = gold,
				Transparency = 0.58,
				Size = Vector3.new(2.6, 0.06, 0.16),
				CFrame = stepPart.CFrame * CFrame.new(0, 0.19, -1.45),
			}, parent)
		end
	end

	local signPosition = baseCFrame.Position + Vector3.new((-17.4 * facingDirection), deckLocalY + 1.8, 0)
	local signLookAt = signPosition + Vector3.new(facingDirection, 0, 0)
	local sign = make("Part", {
		Name = "RebirthTerraceSign",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(6, 8, 13),
		Size = Vector3.new(17, 2.2, 0.35),
		CFrame = CFrame.lookAt(signPosition, signLookAt),
	}, parent)

	local gui = make("SurfaceGui", {
		Name = "TerraceGui",
		Face = Enum.NormalId.Front,
		AlwaysOnTop = false,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 28,
	}, sign)
	local signFrame = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, gui)
	make("UIStroke", {
		Color = gold,
		Thickness = 2,
		Transparency = 0.25,
	}, signFrame)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.56),
		Position = UDim2.fromScale(0, 0.05),
		Text = "REBIRTH TERRACE",
		TextColor3 = Color3.fromRGB(255, 215, 72),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, signFrame)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.32),
		Position = UDim2.fromScale(0, 0.62),
		Text = "SECOND FLOOR SLOTS",
		TextColor3 = Color3.fromRGB(245, 238, 210),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, signFrame)

	for _, z in ipairs({ -19.8, 19.8 }) do
		make("Part", {
			Name = "RebirthTerraceLamp",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = supportColor,
			Size = Vector3.new(0.45, 2.4, 0.45),
			CFrame = baseCFrame * CFrame.new((-16.5 * facingDirection), deckLocalY + 1.5, z),
		}, parent)
		local bulb = make("Part", {
			Name = "RebirthTerraceLampBulb",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 226, 135),
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.8, 0.8, 0.8),
			CFrame = baseCFrame * CFrame.new((-16.5 * facingDirection), deckLocalY + 2.9, z),
		}, parent)
		make("PointLight", {
			Brightness = 0.45,
			Range = 15,
			Color = Color3.fromRGB(255, 226, 160),
		}, bulb)
	end
end

local function createPlot(plotId, side, laneIndex, position)
	local model = make("Model", {
		Name = "Base" .. plotId,
	}, basesFolder)

	local facingDirection = side == "Left" and 1 or -1
	local baseCFrame = CFrame.new(position)
	local centerDirection = Vector3.new(facingDirection, 0, 0)
	local padOffset = 16
	local wallHeight = layout.FenceHeight or 4.5
	local wallThickness = layout.WallThickness or 1.2
	local entranceWidth = layout.EntranceWidth or 16
	local entrancePillarWidth = layout.EntrancePillarWidth or 2.2
	local padInfoMaxDistance = layout.PadInfoMaxDistance or 22
	local wallY = wallHeight / 2 + layout.PlotSize.Y / 2
	local frontEdgeX = facingDirection * (layout.PlotSize.X / 2)
	local backEdgeX = -frontEdgeX

	local floor = make("Part", {
		Name = "Floor",
		Anchored = true,
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(76, 158, 82),
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY, -layout.PlotSize.Z / 2))
	createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY,  layout.PlotSize.Z / 2))
	createFence(model, Vector3.new(wallThickness, wallHeight, layout.PlotSize.Z + wallThickness), baseCFrame * CFrame.new(backEdgeX, wallY, 0))
	local frontWallSegmentLength = math.max(8, (layout.PlotSize.Z - entranceWidth) / 2)
	local frontWallZOffset = (entranceWidth / 2) + (frontWallSegmentLength / 2)
	createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY, -frontWallZOffset))
	createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY,  frontWallZOffset))
	local entrancePillarHeight = wallHeight + 5.6
	local entrancePillarX = frontEdgeX + (facingDirection * ((entrancePillarWidth - wallThickness) / 2))
	createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2, -(entranceWidth / 2)))
	createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2,  (entranceWidth / 2)))

	-- ── Neon gold trim along wall tops (positions computed, no Part refs needed) ─
	local trimH    = 0.12
	local trimNeon = Color3.fromRGB(255, 210, 50)
	local trimTransp = 0.58
	local wallTopLocalY = wallY + wallHeight / 2 + trimH / 2
	local plotX  = layout.PlotSize.X
	local plotZ  = layout.PlotSize.Z

	-- Side walls
	for _, zSign in ipairs({-1, 1}) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon, Color = trimNeon, Transparency = trimTransp,
			Size = Vector3.new(plotX + wallThickness + 0.1, trimH, wallThickness + 0.1),
			CFrame = baseCFrame * CFrame.new(0, wallTopLocalY, zSign * plotZ / 2),
		}, model)
	end
	-- Back wall
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = trimNeon, Transparency = trimTransp,
		Size = Vector3.new(wallThickness + 0.1, trimH, plotZ + wallThickness + 0.1),
		CFrame = baseCFrame * CFrame.new(backEdgeX, wallTopLocalY, 0),
	}, model)
	-- Front wall segments
	for _, zSign in ipairs({-1, 1}) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon, Color = trimNeon, Transparency = trimTransp,
			Size = Vector3.new(wallThickness + 0.1, trimH, frontWallSegmentLength + 0.1),
			CFrame = baseCFrame * CFrame.new(frontEdgeX, wallTopLocalY, zSign * frontWallZOffset),
		}, model)
	end

	-- ── Gold PointLights + Neon caps on entrance pillar tops ─────────────────────
	local pillarCapLocalY = entrancePillarHeight + layout.PlotSize.Y / 2
	for _, zSign in ipairs({-1, 1}) do
		local capCF = baseCFrame * CFrame.new(entrancePillarX, pillarCapLocalY, zSign * (entranceWidth / 2))
		local anchor = make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Transparency = 1, Size = Vector3.new(1, 1, 1), CFrame = capCF,
		}, model)
		make("PointLight", { Brightness = 0.8, Range = 16, Color = trimNeon }, anchor)
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon, Color = trimNeon, Transparency = 0.35,
			Size = Vector3.new(entrancePillarWidth + 0.3, 0.30, wallThickness + 1.1),
			CFrame = baseCFrame * CFrame.new(entrancePillarX, pillarCapLocalY - 0.18, zSign * (entranceWidth / 2)),
		}, model)
	end

	local standRise = 0.9
	local standDepth = 4.8
	for step = 1, 3 do
		local levelOffset = (step - 1) * 2.9
		local levelY = layout.PlotSize.Y / 2 + (standRise / 2) + ((step - 1) * standRise)
		local sideZ = (layout.PlotSize.Z / 2) + 2.2 + levelOffset
		createStadiumTier(model, Vector3.new(layout.PlotSize.X - 10, standRise, standDepth), baseCFrame * CFrame.new(0, levelY, sideZ))
		createStadiumTier(model, Vector3.new(layout.PlotSize.X - 10, standRise, standDepth), baseCFrame * CFrame.new(0, levelY, -sideZ))

		local backX = backEdgeX - (facingDirection * (2.6 + levelOffset))
		createStadiumTier(model, Vector3.new(standDepth, standRise, layout.PlotSize.Z + 8), baseCFrame * CFrame.new(backX, levelY, 0))
	end

	createStadiumWedge(
		model,
		Vector3.new(4.6, 3.2, layout.PlotSize.Z + 8),
		baseCFrame * CFrame.new(backEdgeX - (facingDirection * 10.6), 2.1, 0) * CFrame.Angles(0, math.rad(side == "Left" and 180 or 0), math.rad(90))
	)
	createStadiumWedge(
		model,
		Vector3.new(layout.PlotSize.X - 10, 3.2, 4.6),
		baseCFrame * CFrame.new(0, 2.1, (layout.PlotSize.Z / 2) + 10.4) * CFrame.Angles(0, 0, math.rad(180))
	)
	createStadiumWedge(
		model,
		Vector3.new(layout.PlotSize.X - 10, 3.2, 4.6),
		baseCFrame * CFrame.new(0, 2.1, -(layout.PlotSize.Z / 2) - 10.4)
	)

	createFootballPitchDetails(model, baseCFrame)

	local packPad = make("Part", {
		Name = "PackPad",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(221, 49, 49),
		Size = layout.PackPadSize,
		CFrame = baseCFrame * CFrame.new(-facingDirection * padOffset, 0.45, 0),
	}, model)

	local packPadBorder = make("Part", {
		Name = "PackPadBorder",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(86, 16, 16),
		Size = Vector3.new(layout.PackPadSize.X + 2, 0.2, layout.PackPadSize.Z + 2),
		CFrame = packPad.CFrame - Vector3.new(0, 0.22, 0),
	}, model)
	_ = packPadBorder


	local spawnPad = make("Part", {
		Name = "SpawnPad",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(76, 158, 82),
		Transparency = 1,
		Size = Vector3.new(7, 0.3, 7),
		CFrame = baseCFrame * CFrame.new(facingDirection * padOffset, 0.45, 0),
	}, model)

	local spawnCFrame = CFrame.lookAt(
		spawnPad.Position + Vector3.new(0, 3, 0),
		packPad.Position + Vector3.new(0, 3, 0)
	)

	local spawnLocation = make("SpawnLocation", {
		Name = "PlayerSpawn",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Neutral = true,
		AllowTeamChangeOnTouch = false,
		Duration = 0,
		Transparency = 1,
		Size = Vector3.new(7, 0.4, 7),
		CFrame = CFrame.lookAt(
			spawnPad.Position + Vector3.new(0, 0.9, 0),
			packPad.Position + Vector3.new(0, 0.9, 0)
		),
	}, model)

	local entranceBeamY = entrancePillarHeight + layout.PlotSize.Y / 2 - 0.6
	local ownerSignPosition = position + (centerDirection * (layout.PlotSize.X / 2 + 2.1)) + Vector3.new(0, entranceBeamY + 5.0, 0)
	createFence(
		model,
		Vector3.new(entrancePillarWidth + 1.6, 2.6, entranceWidth + 1.4),
		baseCFrame * CFrame.new(frontEdgeX + (facingDirection * 0.9), entranceBeamY + 0.6, 0)
	)
	-- Neon gold strips top and bottom of beam (positions computed from known values)
	local beamLocalX   = frontEdgeX + (facingDirection * 0.9)
	local beamCenterY  = entranceBeamY + 0.6
	local beamW        = entrancePillarWidth + 1.6 + 0.2
	local beamD        = entranceWidth + 1.4 + 0.1
	for _, ySign in ipairs({1, -1}) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 210, 50),
			Transparency = 0.45,
			Size = Vector3.new(beamW, 0.16, beamD),
			CFrame = baseCFrame * CFrame.new(beamLocalX, beamCenterY + ySign * (2.6 / 2 + 0.14), 0),
		}, model)
	end
	-- ── Owner sign: 3-layer redesign ─────────────────────────────────────────────
	local signW   = 16
	local signH   = 4.6
	local signCF  = CFrame.lookAt(ownerSignPosition, ownerSignPosition + centerDirection)
	local goldCol = Color3.fromRGB(255, 210, 50)

	-- Layer 1 — back plate (dark, larger, 0.35 studs behind)
	make("Part", {
		Name = "SignBackPlate",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(5, 8, 16),
		Size = Vector3.new(signW + 1.6, signH + 1.0, 0.5),
		CFrame = signCF * CFrame.new(0, 0, 0.38),
	}, model)

	-- Layer 2 — main sign panel
	local ownerSign = make("Part", {
		Name = "OwnerSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(9, 13, 24),
		Size = Vector3.new(signW, signH, 0.32),
		CFrame = signCF,
	}, model)

	-- Layer 3 — Neon gold border strips (always visible even when SurfaceGui is off)
	local stripT = 0.32
	local stripD = 0.36
	for _, cfg in ipairs({
		-- top
		{ Vector3.new(signW + stripT * 2, stripT, stripD), signCF * CFrame.new(0,  signH / 2 + stripT / 2, 0) },
		-- bottom
		{ Vector3.new(signW + stripT * 2, stripT, stripD), signCF * CFrame.new(0, -(signH / 2 + stripT / 2), 0) },
		-- left
		{ Vector3.new(stripT, signH, stripD), signCF * CFrame.new(-(signW / 2 + stripT / 2), 0, 0) },
		-- right
		{ Vector3.new(stripT, signH, stripD), signCF * CFrame.new( signW / 2 + stripT / 2, 0, 0) },
	}) do
		make("Part", {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = goldCol,
			Transparency = 0.32,
			Size = cfg[1],
			CFrame = cfg[2],
		}, model)
	end

	-- SurfaceLight: illuminates the entrance area below the sign
	make("SurfaceLight", {
		Face = Enum.NormalId.Front,
		Brightness = 1.4,
		Range = 14,
		Color = Color3.fromRGB(255, 238, 195),
		Angle = 60,
	}, ownerSign)

	-- Backlight: warms the area behind the sign so it reads as a 3D object, not a flat panel
	make("SurfaceLight", {
		Face = Enum.NormalId.Back,
		Brightness = 0.7,
		Range = 10,
		Color = Color3.fromRGB(255, 225, 140),
		Angle = 80,
	}, ownerSign)

	-- PointLight above sign for atmosphere
	make("PointLight", {
		Brightness = 0.5,
		Range = 16,
		Color = goldCol,
	}, ownerSign)

	-- ── SurfaceGui content ────────────────────────────────────────────────────
	local ownerGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 160,
		LightInfluence = 0,
		ClipsDescendants = true,
	}, ownerSign)

	local ownerFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(8, 12, 22),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, ownerGui)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromRGB(14, 20, 38)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(9,  13, 24)),
			ColorSequenceKeypoint.new(1,    Color3.fromRGB(6,  9,  18)),
		}),
		Rotation = 100,
	}, ownerFrame)

	-- Thin gold accent bar across the top
	make("Frame", {
		BackgroundColor3 = goldCol,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.fromOffset(0, 0),
	}, ownerFrame)

	-- HOME CLUB — tiny, faint, top of sign
	local ownerTopLabel = createOwnerSignText("AVAILABLE PLOT",
		UDim2.fromScale(0.62, 0.10),
		UDim2.fromScale(0.19, 0.08),
		Color3.fromRGB(210, 170, 55),
		{
			textScaled = true,
			minTextSize = 12,
			maxTextSize = 32,
			textStrokeTransparency = 0.96,
			font = Enum.Font.GothamBold,
		}, ownerFrame)

	-- Thin divider below HOME CLUB label
	make("Frame", {
		BackgroundColor3 = goldCol,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Size = UDim2.new(0.68, 0, 0, 1),
		Position = UDim2.fromScale(0.16, 0.195),
	}, ownerFrame)

	-- Player name — medium weight, white
	local ownerNameLabel = createOwnerSignText("OPEN",
		UDim2.fromScale(0.92, 0.30),
		UDim2.fromScale(0.04, 0.21),
		Color3.fromRGB(255, 255, 255),
		{
			textScaled = true,
			minTextSize = 36,
			maxTextSize = 160,
			textStrokeTransparency = 0.68,
			font = Enum.Font.GothamBlack,
		}, ownerFrame)

	-- Bold gold separator
	make("Frame", {
		BackgroundColor3 = goldCol,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.new(0.72, 0, 0, 4),
		Position = UDim2.fromScale(0.14, 0.525),
	}, ownerFrame)

	-- STADIUM — BIGGEST, boldest, bright gold with glow stroke
	local ownerSubtitleLabel = createOwnerSignText("STADIUM",
		UDim2.fromScale(0.96, 0.40),
		UDim2.fromScale(0.02, 0.55),
		Color3.fromRGB(255, 218, 55),
		{
			textScaled = true,
			minTextSize = 50,
			maxTextSize = 230,
			textStrokeTransparency = 0.42,
			font = Enum.Font.GothamBlack,
		}, ownerFrame)

	-- ── Pack Milestone Board ─────────────────────────────────────────────────────
	-- Raised to Y=12 so the board floats clearly above head height and is easy to read.
	local msW, msH = 28, 14
	local milestoneSignPosition = position
		+ Vector3.new(backEdgeX - (facingDirection * 5), 12, 0)
	local milestoneSign = make("Part", {
		Name = "PackMilestoneBillboard",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(6, 9, 16),
		Size = Vector3.new(msW, msH, 0.6),
		CFrame = CFrame.lookAt(milestoneSignPosition, milestoneSignPosition + centerDirection),
	}, model)

	local boardGold = Color3.fromRGB(255, 210, 50)
	for _, cfg in ipairs({
		{ Vector3.new(msW + 0.3, 0.18, 0.65), Vector3.new(0,  msH / 2 + 0.09, 0) },
		{ Vector3.new(msW + 0.3, 0.18, 0.65), Vector3.new(0, -msH / 2 - 0.09, 0) },
		{ Vector3.new(0.18, msH + 0.3, 0.65), Vector3.new(-msW / 2 - 0.09, 0,  0) },
		{ Vector3.new(0.18, msH + 0.3, 0.65), Vector3.new( msW / 2 + 0.09, 0,  0) },
	}) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = boardGold,
			Transparency = 0.28,
			Size = cfg[1],
			CFrame = CFrame.lookAt(milestoneSignPosition, milestoneSignPosition + centerDirection)
				* CFrame.new(cfg[2]),
		}, model)
	end

	make("PointLight", {
		Color = boardGold, Range = 22, Brightness = 0.5, Shadows = false,
	}, milestoneSign)

	local milestoneGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 90,
		LightInfluence = 0,
	}, milestoneSign)

	-- ── Root frame ───────────────────────────────────────────────
	local mf = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, milestoneGui)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, mf)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 20, 36)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(7,  10, 18)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(4,  6,  12)),
		}),
		Rotation = 90,
	}, mf)

	-- ── Header: "★ PACK MILESTONES" (0 – 0.10) ───────────────────
	createOwnerSignText("\u{2605} PACK MILESTONES", UDim2.fromScale(0.80, 0.07),
		UDim2.fromScale(0.10, 0.015), Color3.fromRGB(255, 215, 0), {
		textScaled = true, minTextSize = 12, maxTextSize = 28,
		textStrokeTransparency = 0.60, font = Enum.Font.GothamBlack,
	}, mf)

	-- Thin gold divider below header
	make("Frame", {
		BackgroundColor3 = boardGold, BackgroundTransparency = 0.40,
		BorderSizePixel = 0,
		Size = UDim2.new(0.80, 0, 0, 2),
		Position = UDim2.fromScale(0.10, 0.095),
	}, mf)

	-- ── Hero counter: "X PACKS OPENED" (0.10 – 0.40) ─────────────
	local milestonePacksLabel = createOwnerSignText("0 PACKS OPENED",
		UDim2.fromScale(0.90, 0.27), UDim2.fromScale(0.05, 0.105),
		Color3.fromRGB(255, 250, 230), {
		textScaled = true, minTextSize = 28, maxTextSize = 90,
		textStrokeTransparency = 0.50, font = Enum.Font.GothamBlack,
	}, mf)

	-- ── Divider (0.39) ─────────────────────────────────────────────
	make("Frame", {
		BackgroundColor3 = boardGold, BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(0.84, 0, 0, 2),
		Position = UDim2.fromScale(0.08, 0.39),
	}, mf)

	-- ── "NEXT REWARD:" label (0.40 – 0.46) ────────────────────────
	createOwnerSignText("NEXT REWARD:", UDim2.fromScale(0.60, 0.055),
		UDim2.fromScale(0.20, 0.40), Color3.fromRGB(170, 160, 140), {
		textScaled = true, minTextSize = 10, maxTextSize = 22,
		textStrokeTransparency = 0.90, font = Enum.Font.GothamBold,
	}, mf)

	-- ── Next reward text: "X / Y PACKS → PACK NAME" (0.46 – 0.58) ─
	local milestoneNextLabel = createOwnerSignText("25 / 25 PACKS \u{2192} GOLD PACK",
		UDim2.fromScale(0.82, 0.10), UDim2.fromScale(0.09, 0.46),
		Color3.fromRGB(255, 215, 0), {
		textScaled = true, minTextSize = 12, maxTextSize = 36,
		textStrokeTransparency = 0.55, font = Enum.Font.GothamBlack,
	}, mf)

	-- ── Progress bar track (0.60 – 0.72) ──────────────────────────
	local milestoneBarBack = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 24, 40),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.84, 0.085),
		Position = UDim2.fromScale(0.08, 0.60),
	}, mf)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarBack)
	make("UIStroke", {
		Color = boardGold, Thickness = 2, Transparency = 0.45,
	}, milestoneBarBack)

	local milestoneBarFill = make("Frame", {
		BackgroundColor3 = boardGold,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	}, milestoneBarBack)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarFill)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 230, 80)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 170, 0)),
		}),
		Rotation = 0,
	}, milestoneBarFill)
	-- Shimmer stripe
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 210),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0.40, 0),
	}, milestoneBarFill)

	-- % label centred on bar
	local milestoneBarPct = createOwnerSignText("0%",
		UDim2.fromScale(1, 1), UDim2.fromScale(0, 0),
		Color3.fromRGB(255, 255, 255), {
		textScaled = true, minTextSize = 8, maxTextSize = 20,
		textStrokeTransparency = 0.50, font = Enum.Font.GothamBlack,
	}, milestoneBarBack)
	milestoneBarPct.TextXAlignment = Enum.TextXAlignment.Center

	-- ── Divider before rewards row ─────────────────────────────────
	make("Frame", {
		BackgroundColor3 = boardGold, BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(0.84, 0, 0, 2),
		Position = UDim2.fromScale(0.08, 0.725),
	}, mf)

	-- ── "MILESTONE REWARDS" label ──────────────────────────────────
	createOwnerSignText("MILESTONE REWARDS", UDim2.fromScale(0.70, 0.05),
		UDim2.fromScale(0.15, 0.735), Color3.fromRGB(255, 215, 0), {
		textScaled = true, minTextSize = 8, maxTextSize = 18,
		textStrokeTransparency = 0.65, font = Enum.Font.GothamBlack,
	}, mf)

	-- ── Milestone icons row (0.78 – 1.00) ─────────────────────────
	-- Five evenly-spaced pack cards showing each milestone
	local iconY    = 0.785
	local iconH    = 0.195
	local iconW    = 0.13
	local iconGap  = (1 - 0.10 * 2 - iconW * #packMilestones) / (#packMilestones - 1)
	local milestoneIconFrames = {}

	for i, ms in ipairs(packMilestones) do
		local iconX = 0.10 + (i - 1) * (iconW + iconGap)
		local col   = ms.color or boardGold

		-- Card backing
		local card = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 16, 28),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(iconW, iconH),
			Position = UDim2.fromScale(iconX, iconY),
		}, mf)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
		make("UIStroke", { Color = col, Thickness = 2, Transparency = 0.30 }, card)

		-- Coloured top band
		local band = make("Frame", {
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0.38, 0),
		}, card)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, band)

		-- Star icon on band
		createOwnerSignText("\u{2605}", UDim2.fromScale(0.70, 0.38),
			UDim2.fromScale(0.15, 0), Color3.fromRGB(255, 255, 255), {
			textScaled = true, minTextSize = 8, maxTextSize = 22,
			textStrokeTransparency = 0.70, font = Enum.Font.GothamBlack,
		}, card)

		-- Threshold number
		createOwnerSignText(tostring(ms.threshold),
			UDim2.fromScale(0.80, 0.28), UDim2.fromScale(0.10, 0.38),
			Color3.fromRGB(255, 248, 220), {
			textScaled = true, minTextSize = 7, maxTextSize = 18,
			textStrokeTransparency = 0.60, font = Enum.Font.GothamBlack,
		}, card)

		-- Label at bottom
		createOwnerSignText(ms.label or "",
			UDim2.fromScale(0.90, 0.22), UDim2.fromScale(0.05, 0.72),
			col, {
			textScaled = true, minTextSize = 5, maxTextSize = 12,
			textStrokeTransparency = 0.80, font = Enum.Font.GothamBold,
		}, card)

		-- Tick overlay — hidden until claimed
		local tick = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 220, 80),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
		}, card)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, tick)
		tick.BackgroundTransparency = 0.35
		createOwnerSignText("\u{2713}", UDim2.fromScale(0.80, 0.60),
			UDim2.fromScale(0.10, 0.15), Color3.fromRGB(255, 255, 255), {
			textScaled = true, minTextSize = 10, maxTextSize = 32,
			textStrokeTransparency = 0.50, font = Enum.Font.GothamBlack,
		}, tick)

		milestoneIconFrames[i] = { tick = tick, threshold = ms.threshold }
	end

	local padGui = make("BillboardGui", {
		Name = "PadGui",
		Size = UDim2.fromOffset(150, 52),
		StudsOffset = Vector3.new(0, 3.2, 0),
		AlwaysOnTop = false,
		MaxDistance = padInfoMaxDistance,
	}, packPad)

	local padFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 14, 24),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, padGui)

	make("UICorner", {
		CornerRadius = UDim.new(0, 12),
	}, padFrame)

	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 1.5,
		Transparency = 0.22,
	}, padFrame)

	local padAccent = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 85, 85),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 6, 1, -12),
		Position = UDim2.new(0, 8, 0, 6),
	}, padFrame)

	make("UICorner", {
		CornerRadius = UDim.new(0, 6),
	}, padAccent)

	local padTitleLabel = createSignLabel("Pack Pad", UDim2.new(1, -24, 0, 20), UDim2.new(0, 22, 0, 4), Color3.fromRGB(245, 238, 220), padFrame)
	local padSubtitleLabel = createSignLabel("Waiting for owner", UDim2.new(1, -24, 0, 12), UDim2.new(0, 22, 0, 24), Color3.fromRGB(180, 176, 164), padFrame)
	padTitleLabel.TextScaled = false
	padTitleLabel.TextSize = 18
	padTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.TextScaled = false
	padSubtitleLabel.TextSize = 10
	padSubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.Font = Enum.Font.GothamBold

	local padBarBack = make("Frame", {
		Visible = false,
		BackgroundColor3 = Color3.fromRGB(34, 38, 48),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -28, 0, 8),
		Position = UDim2.new(0, 20, 1, -14),
	}, padFrame)

	make("UICorner", {
		CornerRadius = UDim.new(0, 5),
	}, padBarBack)

	local padBarFill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
	}, padBarBack)

	make("UICorner", {
		CornerRadius = UDim.new(0, 5),
	}, padBarFill)

	local displayFolder = make("Folder", {
		Name = "DisplaySlots",
	}, model)

	local displaySlots = {}
	for slotIndex = 1, layout.DisplaySlotCount do
		local localOffset = ALL_SLOT_OFFSETS[slotIndex]
		local worldOffset = Vector3.new(localOffset.X * facingDirection, localOffset.Y, localOffset.Z)
		displaySlots[slotIndex] = createDisplaySlot(
			displayFolder, slotIndex,
			baseCFrame * CFrame.new(worldOffset),
			slotLookDir(localOffset, facingDirection)
		)
	end

	local entranceLightX = frontEdgeX + (facingDirection * 8)
	createLightPost(model, "EntranceLightNorth", position + Vector3.new(entranceLightX, 0, -(entranceWidth / 2 + 6)), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "EntranceLightSouth", position + Vector3.new(entranceLightX, 0,  (entranceWidth / 2 + 6)), packPad.Position + Vector3.new(0, 2, 0))

	-- Decorative side banners flanking the entrance
	local bannerX = frontEdgeX + (facingDirection * 3.5)
	createVerticalBanner(model, "BannerNorth",
		position + Vector3.new(bannerX, 0, -(entranceWidth / 2 + 4.5)),
		packPad.Position,
		"FC")
	createVerticalBanner(model, "BannerSouth",
		position + Vector3.new(bannerX, 0,  (entranceWidth / 2 + 4.5)),
		packPad.Position,
		"FC")
	createLightPost(model, "BackStandLightNorth", position + Vector3.new(backEdgeX - (facingDirection * 8), 0, -(layout.PlotSize.Z / 2 + 5)), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "BackStandLightSouth", position + Vector3.new(backEdgeX - (facingDirection * 8), 0, layout.PlotSize.Z / 2 + 5), packPad.Position + Vector3.new(0, 2, 0))
	local stadiumFloodlightOptions = {
		poleHeight = 27,
		modelHeight = 29,
		range = 68,
		angle = 46,
		brightness = 1.38,
		fillRange = 18,
		fillBrightness = 0.1,
	}
	local floodlightBackX = backEdgeX - (facingDirection * 15)
	local floodlightSideZ = (layout.PlotSize.Z / 2) + 10
	local floodlightTarget = position + Vector3.new(-facingDirection * 4, 3, 0)
	createFloodlightRig(model, "StadiumFloodlightNorth", position + Vector3.new(floodlightBackX, 0, -floodlightSideZ), floodlightTarget, stadiumFloodlightOptions)
	createFloodlightRig(model, "StadiumFloodlightSouth", position + Vector3.new(floodlightBackX, 0, floodlightSideZ), floodlightTarget, stadiumFloodlightOptions)
	createSoftFillLight(model, "StadiumSoftFill", position + Vector3.new(0, 12, 0), 38, 0.22, Color3.fromRGB(255, 232, 184))
	createSoftFillLight(model, "BackStandFill", position + Vector3.new(backEdgeX - (facingDirection * 6), 8, 0), 30, 0.17, Color3.fromRGB(225, 234, 255))
	createSoftFillLight(model, "NorthStandFill", position + Vector3.new(0, 7, -(layout.PlotSize.Z / 2 + 7)), 25, 0.14, Color3.fromRGB(255, 226, 170))
	createSoftFillLight(model, "SouthStandFill", position + Vector3.new(0, 7, layout.PlotSize.Z / 2 + 7), 25, 0.14, Color3.fromRGB(255, 226, 170))

	-- ── Rebirth Machine ─────────────────────────────────────────────────────────
	-- Placed outside the entrance so it reads like a stadium add-on instead of
	-- fighting for space with the pack pad and display slots.
	-- Y offsets are from baseCFrame (floor centre = local Y 0; floor top = local Y 0.5).
	local machineLocalX = frontEdgeX + (facingDirection * 8.5)
	local machineLocalZ = -(entranceWidth / 2 + 12.5)
	local machineCF     = baseCFrame * CFrame.new(machineLocalX, 0, machineLocalZ)

	make("Part", {
		Name = "RebirthMachinePad",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(34, 24, 54),
		Size = Vector3.new(8.5, 0.22, 8.5),
		CFrame = machineCF * CFrame.new(0, 0.61, 0),
	}, model)

	-- Pedestal base (sits on floor top → local Y 0.5 + halfHeight 0.7 = 1.2)
	make("Part", {
		Name = "RebirthBase", Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(20, 15, 32),
		Size = Vector3.new(5, 1.4, 5),
		CFrame = machineCF * CFrame.new(0, 1.2, 0),
	}, model)

	-- Body column (base top = 1.9 → body centre = 1.9 + 3.0 = 4.9)
	make("Part", {
		Name = "RebirthBody", Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(22, 16, 36),
		Size = Vector3.new(3.0, 6.0, 3.0),
		CFrame = machineCF * CFrame.new(0, 4.9, 0),
	}, model)

	-- Neon purple vertical accent strips at each corner of the body
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2 + math.pi / 4   -- 45°, 135°, 225°, 315°
		local r = 1.58
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(130, 52, 255),
			Transparency = 0.28,
			Size = Vector3.new(0.26, 5.8, 0.26),
			CFrame = machineCF * CFrame.new(math.cos(angle) * r, 4.9, math.sin(angle) * r),
		}, model)
	end

	-- Gold neon trim cap at top of body (body top = 7.9)
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 208, 50),
		Transparency = 0.36,
		Size = Vector3.new(3.4, 0.28, 3.4),
		CFrame = machineCF * CFrame.new(0, 8.1, 0),
	}, model)

	-- Portal ring: flat horizontal disc floating above the column.
	-- Cylinder axis = X by default; rotate 90° around Z to make axis = Y (flat disc).
	make("Part", {
		Name = "RebirthPortalRing", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(148, 68, 255),
		Transparency = 0.16,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.42, 8.2, 8.2),
		CFrame = machineCF * CFrame.new(0, 9.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)

	-- Smaller inner ring for depth
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(200, 140, 255),
		Transparency = 0.52,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.28, 5.6, 5.6),
		CFrame = machineCF * CFrame.new(0, 9.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)

	-- Glowing orb at the centre of the portal ring
	local rebirthOrb = make("Part", {
		Name = "RebirthOrb", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(188, 118, 255),
		Transparency = 0.08,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.4, 2.4, 2.4),
		CFrame = machineCF * CFrame.new(0, 9.2, 0),
	}, model)

	make("PointLight", {
		Brightness = 2.6, Range = 26,
		Color = Color3.fromRGB(148, 68, 255),
	}, rebirthOrb)

	local rebirthPrompt = make("ProximityPrompt", {
		ActionText            = "Rebirth",
		ObjectText            = "Rebirth Machine",
		KeyboardKeyCode       = Enum.KeyCode.E,
		HoldDuration          = 0.6,
		MaxActivationDistance = 12,
		RequiresLineOfSight   = false,
		Style                 = Enum.ProximityPromptStyle.Default,
	}, rebirthOrb)

	-- Folder for visuals that change per rebirth tier (seats, lighting, etc.)
	local stadiumExtrasFolder = make("Folder", { Name = "StadiumExtras" }, model)

	local plot = {
		id = plotId,
		side = side,
		laneIndex = laneIndex,
		model = model,
		baseCFrame = baseCFrame,
		facingDirection = facingDirection,
		stadiumExtrasFolder = stadiumExtrasFolder,
		floor = floor,
		packPad = packPad,
		spawnPad = spawnPad,
		spawnLocation = spawnLocation,
		ownerSign = ownerSign,
		ownerTopLabel = ownerTopLabel,
		ownerNameLabel = ownerNameLabel,
		ownerSubtitleLabel = ownerSubtitleLabel,
		milestoneSign = milestoneSign,
		milestonePacksLabel = milestonePacksLabel,
		milestoneNextLabel = milestoneNextLabel,
		milestoneBarFill = milestoneBarFill,
		milestoneBarPct = milestoneBarPct,
		milestoneIconFrames = milestoneIconFrames,
		padTitleLabel = padTitleLabel,
		padSubtitleLabel = padSubtitleLabel,
		padAccent = padAccent,
		padGui = padGui,
		padBarBack = padBarBack,
		padBarFill = padBarFill,
		displaySlots = displaySlots,
		spawnCFrame = spawnCFrame,
		rebirthPrompt = rebirthPrompt,
	}

	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))

	return plot
end

-- Called when a player is assigned a plot or completes a rebirth.
-- Rebuilds the stadium extras folder to match the given rebirth tier.
--   Tier 0: no stands
--   Tier 1+: tiered bleacher stands built from Parts (reliable, no asset loading)
--            More rows unlock as the player progresses through tiers.
function BaseService.UpdateStadiumTier(plot, tier)
	if not plot or not plot.stadiumExtrasFolder then return end
	tier = tier or 0

	-- Clear whatever was there before
	for _, child in ipairs(plot.stadiumExtrasFolder:GetChildren()) do
		child:Destroy()
	end

	if tier < 1 then return end

	local parent   = plot.stadiumExtrasFolder
	local pitchPos = plot.baseCFrame.Position
	local fd       = plot.facingDirection               -- 1=left plot, -1=right plot
	local floorY   = pitchPos.Y + layout.PlotSize.Y / 2 -- top of floor (world Y ≈ 1)
	local PlotX    = layout.PlotSize.X                  -- 56
	local PlotZ    = layout.PlotSize.Z                  -- 44

	-- Row count scales with rebirth tier so the stadium visually grows
	local rowCount = math.min(1 + tier, 5)  -- tier1→2, tier2→3, tier3→4, tier4+→5

	local tierH  = 3.0   -- vertical rise per row
	local tierD  = 4.2   -- depth per row (away from pitch)
	local gap    = 1.5   -- clearance from fence centre so stands don't overlap fence

	-- Width of each stand face (slightly wider than plot for corner coverage)
	local sideW = PlotX + 2   -- 58 studs east-west
	local backW = PlotZ + 2   -- 46 studs north-south

	-- Alternating seat colours per row
	local colA = Color3.fromRGB(198, 44, 44)
	local colB = Color3.fromRGB(158, 30, 30)

	-- Build one bleacher face.
	-- fencePos  : world XZ of the fence line (floor height; this becomes the stand's front face)
	-- awayX/awayZ: unit step direction going away from the pitch per row
	-- partSizeX/Z: horizontal dimensions of each tier Part
	local function buildStand(fencePos, awayX, awayZ, partSizeX, partSizeZ)
		for row = 1, rowCount do
			local setback = (row - 0.5) * tierD         -- depth of row centre from fence
			local rise    = (row - 1)   * tierH         -- height of row bottom above floor
			make("Part", {
				Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
				Material = Enum.Material.SmoothPlastic,
				Color    = (row % 2 == 1) and colA or colB,
				Size     = Vector3.new(partSizeX, tierH, partSizeZ),
				CFrame   = CFrame.new(
					fencePos.X + awayX * setback,
					floorY + rise + tierH / 2,
					fencePos.Z + awayZ * setback
				),
			}, parent)
		end
	end

	-- North stand: outside north fence (−Z side), facing south toward pitch
	buildStand(
		Vector3.new(pitchPos.X, 0, pitchPos.Z - (PlotZ / 2 + gap)),
		0, -1,
		sideW, tierD
	)

	-- South stand: outside south fence (+Z side), facing north toward pitch
	buildStand(
		Vector3.new(pitchPos.X, 0, pitchPos.Z + (PlotZ / 2 + gap)),
		0, 1,
		sideW, tierD
	)

	-- Back stand: outside back fence (opposite the entrance), facing inward
	-- fd=1  → back fence is at X = pitchPos.X − PlotX/2; stand steps in −X
	-- fd=−1 → back fence is at X = pitchPos.X + PlotX/2; stand steps in +X
	buildStand(
		Vector3.new(pitchPos.X - fd * (PlotX / 2 + gap), 0, pitchPos.Z),
		-fd, 0,
		tierD, backW
	)

	-- Rebirth display slots 7-18 live on this raised terrace. Keeping the
	-- terrace in StadiumExtras lets it rebuild cleanly whenever the tier changes.
	createSecondFloorDisplayGallery(parent, plot.baseCFrame, fd)
end

function BaseService.BuildBaseMap()
	plots = {}
	assignedPlots = {}
	animatedTurnstiles = {}
	configureMapLighting()

	-- Remove the Studio-default SpawnLocation (and any leftover ones) so
	-- players don't spawn on the podium at world-origin.  We add our own
	-- SpawnLocation inside createFanZone near the south gate.
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("SpawnLocation") then
			desc:Destroy()
		end
	end

	if basesFolder then
		basesFolder:Destroy()
	end

	basesFolder = make("Folder", {
		Name = "PlayerBases",
	}, Workspace)

	local mapWidth = layout.SideOffset * 2 + layout.PlotSize.X + 40
	local mapLength = layout.PlotSpacing * layout.PlotsPerSide + layout.PlotSize.Z + 80
	make("Part", {
		Name = "LobbyGround",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(18, 24, 34),
		Size = Vector3.new(mapWidth, 4, mapLength),
		CFrame = CFrame.new(0, -2.0, 0),
	}, basesFolder)

	make("Part", {
		Name = "LobbyPlaza",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Cobblestone,
		Color = Color3.fromRGB(46, 54, 68),
		Size = Vector3.new(mapWidth - 8, 0.2, mapLength - 8),
		CFrame = CFrame.new(0, 0.1, 0),
	}, basesFolder)

	createFanZone(mapWidth, mapLength)

	for sideIndex = 1, 2 do
		for laneIndex = 1, layout.PlotsPerSide do
			local plotId = #plots + 1
			local x = sideIndex == 1 and -layout.SideOffset or layout.SideOffset
			local z = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
			local side = sideIndex == 1 and "Left" or "Right"
			table.insert(plots, createPlot(plotId, side, laneIndex, Vector3.new(x, 0.5, z)))
		end
	end

	return plots
end

function BaseService.GetPlots()
	if #plots == 0 then
		BaseService.BuildBaseMap()
	end
	return plots
end

-- Creates a single extra display slot on an already-assigned plot.
-- Called when a player rebirths and earns an additional slot.
function BaseService.AddDisplaySlot(plot, slotIndex)
	if not plot then return end
	local localOffset = ALL_SLOT_OFFSETS[slotIndex]
	if not localOffset then return end
	if plot.displaySlots[slotIndex] then return end  -- already exists

	local displayFolder = plot.model:FindFirstChild("DisplaySlots")
	if not displayFolder then return end

	local fd  = plot.facingDirection
	local worldOffset = Vector3.new(localOffset.X * fd, localOffset.Y, localOffset.Z)
	local slot = createDisplaySlot(
		displayFolder, slotIndex,
		plot.baseCFrame * CFrame.new(worldOffset),
		slotLookDir(localOffset, fd)
	)
	plot.displaySlots[slotIndex] = slot
	return slot
end

function BaseService.AssignPlot(player, rebirthTier, baseSlots)
	if assignedPlots[player] then
		return assignedPlots[player]
	end

	if #plots == 0 then
		BaseService.BuildBaseMap()
	end

	for _, plot in ipairs(plots) do
		if not plot.ownerPlayer then
			plot.ownerPlayer = player
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			plot.model:SetAttribute("OwnerName", player.DisplayName)
			updateOwnerSign(plot, player.DisplayName, "")
			updatePadLabel(plot, "Rolling Pack", "Preparing your next spawn", Color3.fromRGB(255, 170, 48))
			assignedPlots[player] = plot
			if plot.spawnLocation then
				player.RespawnLocation = plot.spawnLocation
			end
			BaseService.UpdateStadiumTier(plot, rebirthTier or 0)

			-- Build any extra slots the player has earned through rebirths
			local slotCount = math.min(baseSlots or 6, Constants.Rebirth.MaxSlots)
			for i = layout.DisplaySlotCount + 1, slotCount do
				BaseService.AddDisplaySlot(plot, i)
			end

			return plot
		end
	end

	return nil
end

function BaseService.ReleasePlot(player)
	local plot = assignedPlots[player]
	if not plot then
		return
	end

	if plot.activePackModel and plot.activePackModel.Parent then
		plot.activePackModel:Destroy()
	end

	plot.activePackModel = nil
	plot.activePackDef = nil
	plot.ownerPlayer = nil
	plot.model:SetAttribute("OwnerUserId", nil)
	plot.model:SetAttribute("OwnerName", nil)
	BaseService.ClearPlotDisplays(plot)
	BaseService.UpdatePackMilestone(plot, 0)
	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	if player.RespawnLocation == plot.spawnLocation then
		player.RespawnLocation = nil
	end
	assignedPlots[player] = nil
end

function BaseService.GetPlot(player)
	return assignedPlots[player]
end

function BaseService.GetDisplaySlots(plot)
	return plot and plot.displaySlots or {}
end

function BaseService.UpdatePackMilestone(plot, totalPacks, claimedMilestones)
	if not plot or not plot.milestonePacksLabel or not plot.milestoneNextLabel or not plot.milestoneBarFill then
		return
	end

	totalPacks = math.max(0, totalPacks or 0)
	claimedMilestones = claimedMilestones or {}

	local ms = getNextPackMilestone(totalPacks)

	-- Hero counter
	plot.milestonePacksLabel.Text = Utils.FormatNumber(totalPacks) .. " PACKS OPENED"

	-- Next reward line
	if ms.progress >= 1 then
		plot.milestoneNextLabel.Text = "\u{2605} ALL MILESTONES COMPLETE!"
	else
		plot.milestoneNextLabel.Text = string.format(
			"%s / %s PACKS  \u{2192}  %s",
			Utils.FormatNumber(totalPacks - ms.prevAt),
			Utils.FormatNumber(ms.nextAt   - ms.prevAt),
			string.upper(ms.reward)
		)
	end

	-- Progress bar + % label
	local pct = math.floor(ms.progress * 100)
	plot.milestoneBarFill.Size = UDim2.fromScale(ms.progress, 1)
	if plot.milestoneBarPct then
		plot.milestoneBarPct.Text = tostring(pct) .. "%"
	end

	-- Tick marks: show if this milestone has been claimed in the current cycle
	if plot.milestoneIconFrames then
		local CYCLE     = packMilestones and packMilestones[#packMilestones].threshold or 150
		local cycleNum  = math.floor(totalPacks / CYCLE)
		local posInCycle = totalPacks % CYCLE
		for _, entry in ipairs(plot.milestoneIconFrames) do
			if entry.tick then
				local T       = entry.threshold
				local claimed = claimedMilestones[tostring(T)]
				if claimed == true then claimed = 1 end
				claimed = tonumber(claimed) or 0
				-- Tick = reached this threshold in current cycle AND reward was granted
				entry.tick.Visible = (posInCycle >= T) and (claimed >= cycleNum + 1)
			end
		end
	end
end

function BaseService.SetPlotPadStatus(plot, title, subtitle, color)
	if plot then
		updatePadLabel(plot, title, subtitle, color or Color3.fromRGB(255, 85, 85))
	end
end

function BaseService.SetPlotPadHealth(plot, title, currentValue, maxValue, color)
	if plot then
		updatePadHealth(plot, title, currentValue, maxValue, color or Color3.fromRGB(255, 215, 0))
	end
end

function BaseService.UpdateDisplaySlot(slot, card, incomePerSecond)
	clearDisplayCard(slot)

	if not card then
		setSlotPrompt(slot, "Add Player", "Inventory Empty", false)
		return
	end

	local cardModel = make("Model", {
		Name = "DisplayCard",
	}, slot.model)

	local cardPosition = slot.top.Position + Vector3.new(0, 4.2, 0)
	local cardPart = make("Part", {
		Name = "CardPart",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 20, 10),
		Size = Vector3.new(4.25, 6.2, 0.26),
		CFrame = CFrame.lookAt(cardPosition, cardPosition + slot.lookDirection),
	}, cardModel)

	make("PointLight", {
		Color = Utils.GetRarityColor(card.rarity),
		Range = 5,
		Brightness = 0.22,
	}, cardPart)

	createDisplayCardFace(Enum.NormalId.Front, card, incomePerSecond, cardPart)
	createDisplayCardFace(Enum.NormalId.Back, card, incomePerSecond, cardPart)

	-- Floating income label above the card
	local income = incomePerSecond or 0
	if income > 0 then
		local incomeGui = make("BillboardGui", {
			Name = "IncomeLabel",
			AlwaysOnTop = false,
			Size = UDim2.fromOffset(170, 36),
			StudsOffset = Vector3.new(0, 5.8, 0),
			MaxDistance = 28,
		}, cardPart)
		local incomeLabel = make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "+" .. Utils.FormatNumber(income) .. " fans/s",
			TextColor3 = Color3.fromRGB(255, 218, 60),
			TextScaled = false,
			TextSize = 20,
			Font = Enum.Font.GothamBlack,
			TextStrokeTransparency = 0.32,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		}, incomeGui)
		_ = incomeLabel
	end

	slot.cardModel = cardModel
	slot.model:SetAttribute("Occupied", true)
	setSlotPrompt(slot, "Remove Player", card.name, true)
end

function BaseService.SetDisplaySlotAddReady(slot, objectText, enabled)
	clearDisplayCard(slot)
	setSlotPrompt(slot, "Add Player", objectText or "From Inventory", enabled)
end

function BaseService.ClearPlotDisplays(plot)
	for _, slot in ipairs(plot.displaySlots or {}) do
		clearDisplayCard(slot)
		setSlotPrompt(slot, "Add Player", "Inventory Empty", false)
	end
end

function BaseService.PlaceCharacterAtPlot(player, character)
	local plot = assignedPlots[player]
	local targetCharacter = character or player.Character
	if not plot or not targetCharacter then
		return false
	end

	local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:WaitForChild("HumanoidRootPart", 5)
	if not rootPart then
		warn("[UnboxAFootballer] Could not move player to base; HumanoidRootPart missing for " .. player.Name)
		return false
	end

	targetCharacter:PivotTo(plot.spawnCFrame)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	return true
end

return BaseService

]])

makeModule('CrowdService', SSS, [[local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)

local CrowdService = {}

local BaseService
local DataService
local fanFolder
local running = false

local plazaConfig = Constants.FanZone
local layout = Constants.BaseLayout

-- Football jersey palette — bright, varied, instantly readable as a crowd
local shirtColors = {
	Color3.fromRGB(192, 26, 26),    -- red (Arsenal / Man Utd)
	Color3.fromRGB(24, 78, 170),    -- royal blue (Chelsea)
	Color3.fromRGB(108, 174, 228),  -- sky blue (Man City)
	Color3.fromRGB(20, 110, 48),    -- green (Celtic / Forest)
	Color3.fromRGB(230, 186, 28),   -- yellow (Dortmund / Brazil)
	Color3.fromRGB(148, 20, 148),   -- purple (Fiorentina)
	Color3.fromRGB(224, 88, 24),    -- orange (Netherlands)
	Color3.fromRGB(236, 236, 236),  -- white (Real Madrid)
	Color3.fromRGB(16, 26, 86),     -- dark navy (Everton)
	Color3.fromRGB(164, 12, 58),    -- claret (Aston Villa)
	Color3.fromRGB(28, 28, 28),     -- black (Juventus)
	Color3.fromRGB(32, 96, 62),     -- dark green
	Color3.fromRGB(120, 72, 38),    -- brown / amber
}

local skinColors = {
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(199, 142, 91),
	Color3.fromRGB(141, 85, 54),
	Color3.fromRGB(246, 215, 176),
}

local STANDING_PIVOT_HEIGHT = 3.1

local FOOD_TYPES = {
	Popcorn = true,
	HotDog = true,
	Burger = true,
	Drink = true,
}
local STAND_TIERS = {
	{ zOffset = 24.2, surfaceY = 1.9 },
	{ zOffset = 27.1, surfaceY = 2.8 },
	{ zOffset = 30.0, surfaceY = 3.7 },
}

-- ── Stall queue system ─────────────────────────────────────────────
-- Each food stall has 4 queue slots (waypoints "Food<Stall>1"…"Food<Stall>4"
-- in BaseService).  When an NPC decides to visit a stall it claims the
-- lowest free slot, walks there, holds it through its food pause, then
-- releases it as it walks away.  This produces a real-looking line
-- instead of every NPC piling onto the same spot.
local QUEUE_SLOTS_PER_STALL = 4
local STALL_NAMES = { "Popcorn", "HotDogs", "Burgers", "Drinks" }

local STALL_FOOD_TYPE = {
	Popcorn = "Popcorn",
	HotDogs = "HotDog",
	Burgers = "Burger",
	Drinks  = "Drink",
}

local STALL_LOOK_AT = {
	Popcorn = Vector3.new(-36, STANDING_PIVOT_HEIGHT, -15),
	HotDogs = Vector3.new( 36, STANDING_PIVOT_HEIGHT, -15),
	Burgers = Vector3.new(-36, STANDING_PIVOT_HEIGHT,  15),
	Drinks  = Vector3.new( 36, STANDING_PIVOT_HEIGHT,  15),
}

local WEST_STALLS = { "Popcorn", "Burgers" }
local EAST_STALLS = { "HotDogs", "Drinks" }

local stallQueueState = {}
for _, stallName in ipairs(STALL_NAMES) do
	stallQueueState[stallName] = table.create(QUEUE_SLOTS_PER_STALL, false)
end

local function claimStallSlot(stallName)
	local state = stallQueueState[stallName]
	if not state then
		return nil
	end
	for i = 1, QUEUE_SLOTS_PER_STALL do
		if not state[i] then
			state[i] = true
			return i
		end
	end
	return nil
end

local function releaseStallSlot(stallName, slotIndex)
	local state = stallQueueState[stallName]
	if state and slotIndex and state[slotIndex] then
		state[slotIndex] = false
	end
end

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function getWaypoint(name)
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	local plaza = basesFolder and basesFolder:FindFirstChild("FanZone")
	local waypoints = plaza and plaza:FindFirstChild("Waypoints")
	return waypoints and waypoints:FindFirstChild(name)
end

local function getPoint(name)
	local waypoint = getWaypoint(name)
	return waypoint and waypoint.Position
end

-- True R6-style character. Pivot (HumanoidRootPart) at Y=2.8 (waist) matches plaza waypoints.
-- Humanoid + R6 part names + SpecialMesh Head + face Decal make Roblox treat this as a real player.
local function createFanNpc(index)
	local model = make("Model", {
		Name = "FanNPC" .. index,
	}, fanFolder)

	local shirtColor = shirtColors[math.random(1, #shirtColors)]
	local skinColor = skinColors[math.random(1, #skinColors)]
	-- Randomise pants so each NPC looks distinct
	local pantsColor = Color3.fromRGB(
		math.random(42, 95),
		math.random(45, 95),
		math.random(48, 105)
	)

	-- ── HumanoidRootPart ────────────────────────────────────────────
	-- Invisible waist-level anchor; PivotTo drives the whole model.
	local hrp = make("Part", {
		Name = "HumanoidRootPart",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(2, 2, 1),
		CFrame = CFrame.new(0, STANDING_PIVOT_HEIGHT, 0),
	}, model)
	model.PrimaryPart = hrp

	-- ── Humanoid ─────────────────────────────────────────────────────
	-- Tells Roblox's renderer this is a character; suppresses health bar.
	make("Humanoid", {
		DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None,
		HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff,
		MaxHealth = 100,
		Health = 100,
	}, model)

	-- ── Torso ────────────────────────────────────────────────────────
	-- Classic R6 2×2×1, shirt colour, sits at waist (same Y as HRP).
	make("Part", {
		Name = "Torso",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = shirtColor,
		Size = Vector3.new(2, 2, 1),
		CFrame = CFrame.new(0, STANDING_PIVOT_HEIGHT, 0),
	}, model)

	-- ── Head ─────────────────────────────────────────────────────────
	-- 2×1×1 Part with the classic MeshType.Head (rounded block shape)
	-- and the default Roblox face decal — this is what makes NPCs read
	-- as real players instead of coloured boxes.
	local head = make("Part", {
		Name = "Head",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(2, 1, 1),
		CFrame = CFrame.new(0, STANDING_PIVOT_HEIGHT + 1.7, 0),
	}, model)

	make("SpecialMesh", {
		MeshType = Enum.MeshType.Head,
		Scale = Vector3.new(1.25, 1.25, 1.25),
	}, head)

	make("Decal", {
		Texture = "rbxasset://textures/face.png",
		Face = Enum.NormalId.Front,
	}, head)

	-- ── Arms ─────────────────────────────────────────────────────────
	-- R6 names use a space ("Left Arm") — Roblox requires this spelling.
	make("Part", {
		Name = "Left Arm",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(1, 2, 1),
		CFrame = CFrame.new(-1.5, STANDING_PIVOT_HEIGHT, 0),
	}, model)

	make("Part", {
		Name = "Right Arm",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(1, 2, 1),
		CFrame = CFrame.new(1.5, STANDING_PIVOT_HEIGHT, 0),
	}, model)

	-- ── Legs ─────────────────────────────────────────────────────────
	-- Legs overlap the torso slightly so they stay visible on every plaza material.
	make("Part", {
		Name = "Left Leg",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = pantsColor,
		Size = Vector3.new(0.95, 2.25, 0.95),
		CFrame = CFrame.new(-0.5, 1.48, 0),
	}, model)

	make("Part", {
		Name = "Right Leg",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = pantsColor,
		Size = Vector3.new(0.95, 2.25, 0.95),
		CFrame = CFrame.new(0.5, 1.48, 0),
	}, model)

	return model
end

local function setPartLocal(model, partName, localCFrame, size)
	local part = model:FindFirstChild(partName)
	if not part or not part:IsA("BasePart") then
		return
	end

	if size then
		part.Size = size
	end
	part.CFrame = model:GetPivot() * localCFrame
end

local function setFanPose(model, pose)
	if not model.Parent then
		return
	end

	if pose == "seated" then
		setPartLocal(model, "Torso", CFrame.new(0, 0, 0), Vector3.new(2, 1.65, 1))
		setPartLocal(model, "Head", CFrame.new(0, 1.35, -0.03), Vector3.new(2, 1, 1))
		setPartLocal(model, "Left Arm", CFrame.new(-1.45, -0.1, -0.05) * CFrame.Angles(math.rad(-8), 0, 0), Vector3.new(1, 1.65, 1))
		setPartLocal(model, "Right Arm", CFrame.new(1.45, -0.1, -0.05) * CFrame.Angles(math.rad(-8), 0, 0), Vector3.new(1, 1.65, 1))
		setPartLocal(model, "Left Leg", CFrame.new(-0.5, -0.68, -0.75) * CFrame.Angles(math.rad(82), 0, 0), Vector3.new(0.9, 1.75, 0.9))
		setPartLocal(model, "Right Leg", CFrame.new(0.5, -0.68, -0.75) * CFrame.Angles(math.rad(82), 0, 0), Vector3.new(0.9, 1.75, 0.9))
		return
	end

	setPartLocal(model, "Torso", CFrame.new(0, 0, 0), Vector3.new(2, 2, 1))
	setPartLocal(model, "Head", CFrame.new(0, 1.7, 0), Vector3.new(2, 1, 1))
	setPartLocal(model, "Left Arm", CFrame.new(-1.5, 0, 0), Vector3.new(1, 2, 1))
	setPartLocal(model, "Right Arm", CFrame.new(1.5, 0, 0), Vector3.new(1, 2, 1))
	setPartLocal(model, "Left Leg", CFrame.new(-0.5, -1.62, 0), Vector3.new(0.95, 2.25, 0.95))
	setPartLocal(model, "Right Leg", CFrame.new(0.5, -1.62, 0), Vector3.new(0.95, 2.25, 0.95))
end

-- Attaches or removes a small food/drink prop near the NPC's right hand.
-- Because all parts are anchored and moved via PivotTo, the prop stays at a
-- fixed offset from the model pivot — right arm area — automatically.
local function setFoodProp(model, foodType)
	local existing = model:FindFirstChild("FoodProp")
	if existing then
		existing:Destroy()
	end
	if not foodType or not model.Parent then
		return
	end

	local selectedType = FOOD_TYPES[foodType] and foodType or "Drink"
	local pivot = model:GetPivot()
	local propModel = make("Model", {
		Name = "FoodProp",
	}, model)
	-- Front is local -Z for CFrame.lookAt. Keep the prop high, bright, and
	-- slightly in front of the right hand so it reads clearly from gameplay view.
	local propCFrame = pivot * CFrame.new(1.72, -0.05, -0.95)

	local function prop(partName, size, offset, color, material, shape)
		return make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = material or Enum.Material.SmoothPlastic,
			Color = color,
			Shape = shape or Enum.PartType.Block,
			Size = size,
			CFrame = propCFrame * offset,
		}, propModel)
	end

	if selectedType == "Popcorn" then
		prop("PopcornBucket", Vector3.new(0.78, 0.72, 0.58), CFrame.new(), Color3.fromRGB(245, 238, 220))
		prop("RedStripeL", Vector3.new(0.10, 0.74, 0.60), CFrame.new(-0.20, 0, 0), Color3.fromRGB(205, 40, 32))
		prop("RedStripeR", Vector3.new(0.10, 0.74, 0.60), CFrame.new(0.20, 0, 0), Color3.fromRGB(205, 40, 32))
		for i = 1, 5 do
			local xOffset = ((i - 3) * 0.12)
			local zOffset = (i % 2 == 0) and 0.10 or -0.08
			prop("Kernel" .. i, Vector3.new(0.16, 0.16, 0.16), CFrame.new(xOffset, 0.45, zOffset), Color3.fromRGB(255, 232, 135), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
	elseif selectedType == "HotDog" then
		prop("Tray", Vector3.new(0.96, 0.08, 0.52), CFrame.new(0, -0.20, 0), Color3.fromRGB(235, 226, 190))
		prop("Bun", Vector3.new(0.86, 0.22, 0.42), CFrame.new(0, -0.02, 0), Color3.fromRGB(221, 160, 83))
		prop("Sausage", Vector3.new(0.74, 0.16, 0.18), CFrame.new(0, 0.11, 0), Color3.fromRGB(185, 48, 34))
		prop("Mustard", Vector3.new(0.56, 0.05, 0.08), CFrame.new(0, 0.22, 0), Color3.fromRGB(255, 216, 42), Enum.Material.Neon)
	elseif selectedType == "Burger" then
		prop("BottomBun", Vector3.new(0.72, 0.16, 0.54), CFrame.new(0, -0.20, 0), Color3.fromRGB(221, 160, 83))
		prop("Patty", Vector3.new(0.78, 0.14, 0.58), CFrame.new(0, -0.06, 0), Color3.fromRGB(92, 46, 24))
		prop("Lettuce", Vector3.new(0.86, 0.08, 0.64), CFrame.new(0, 0.04, 0), Color3.fromRGB(78, 180, 68))
		prop("TopBun", Vector3.new(0.70, 0.18, 0.52), CFrame.new(0, 0.18, 0), Color3.fromRGB(234, 176, 92))
	else
		prop("DrinkCup", Vector3.new(0.58, 0.86, 0.58), CFrame.new(0, 0, 0), Color3.fromRGB(58, 180, 235))
		prop("DrinkLabel", Vector3.new(0.60, 0.22, 0.06), CFrame.new(0, 0.04, -0.30), Color3.fromRGB(255, 238, 130))
		prop("Lid", Vector3.new(0.66, 0.10, 0.66), CFrame.new(0, 0.49, 0), Color3.fromRGB(245, 245, 245))
		prop("Straw", Vector3.new(0.08, 0.74, 0.08), CFrame.new(0.16, 0.78, -0.05) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(245, 245, 245))
	end
end

local function getPlotEntrancePoint(plot)
	local floorPosition = plot.floor.Position
	local frontX = floorPosition.X + (plot.facingDirection * ((layout.PlotSize.X / 2) + 7))
	return Vector3.new(frontX, STANDING_PIVOT_HEIGHT, floorPosition.Z)
end

local function getPlotSeatPoint(plot)
	local floorPosition = plot.floor.Position
	local tier = STAND_TIERS[math.random(1, #STAND_TIERS)]
	local sideZ = math.random(1, 2) == 1 and -1 or 1
	local xSpread = math.random(-18, 18)
	local x = floorPosition.X + (xSpread * plot.facingDirection)
	local z = floorPosition.Z + (sideZ * tier.zOffset)
	local pivotY = tier.surfaceY + 1.25
	return Vector3.new(x, pivotY, z)
end

local function getPlotWeight(plot)
	if not plot.ownerPlayer or not DataService then
		return 0
	end

	local fans = DataService.GetCoins(plot.ownerPlayer)
	local visibleFromFans = math.floor((fans or 0) / plazaConfig.FansPerVisibleNpc)
	local capacity = math.min(plazaConfig.MaxStadiumVisitors, plazaConfig.BaseStadiumCapacity + math.floor((fans or 0) / 500000))
	return math.clamp(visibleFromFans, 0, capacity)
end

local function chooseVisitorPlot()
	if not BaseService then
		return nil
	end

	local weightedPlots = {}
	local totalWeight = 0
	for _, plot in ipairs(BaseService.GetPlots()) do
		local weight = getPlotWeight(plot)
		if weight > 0 then
			totalWeight += weight
			table.insert(weightedPlots, {
				plot = plot,
				weight = weight,
			})
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(weightedPlots) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.plot
		end
	end

	return weightedPlots[#weightedPlots].plot
end

-- laneOffset: X-axis nudge (studs) so each NPC walks a slightly different
-- track through the plaza — prevents them all overlapping on the centre line.
local function makeRoute(laneOffset)
	laneOffset = laneOffset or 0

	local northGate = getPoint("NorthGate")
	local southGate = getPoint("SouthGate")
	local center = getPoint("Center")
	local westLoop = getPoint("WestLoop")
	local eastLoop = getPoint("EastLoop")
	if not northGate or not southGate or not center or not westLoop or not eastLoop then
		return nil
	end

	-- Apply lane offset to all main-walkway positions (not stadium sub-paths).
	local function lane(pos)
		return Vector3.new(pos.X + laneOffset, pos.Y, pos.Z)
	end

	local rawStart = math.random(1, 2) == 1 and northGate or southGate
	local rawEnd   = rawStart == northGate and southGate or northGate
	local rawLoop  = math.random(1, 2) == 1 and westLoop or eastLoop

	local route = {
		{ position = lane(rawStart) },
		{ position = lane(center) },
		{ position = lane(rawLoop) },
	}

	-- Configured chance: detour to a real food stall counter.
	-- isFood + foodType tells runFan which prop to put in the NPC's hand.
	-- The fan claims a queue slot up-front (1 = front of line, 4 = back),
	-- holds it through its pause, then releases it as it walks away.  If
	-- both stalls on this side are full (4×2 = 8 fans queued), skip food.
	if math.random() < (plazaConfig.FoodStopChance or 0.30) then
		local sideStalls = (laneOffset < 0) and WEST_STALLS or EAST_STALLS

		local stallOrder = { sideStalls[1], sideStalls[2] }
		if math.random(1, 2) == 1 then
			stallOrder[1], stallOrder[2] = stallOrder[2], stallOrder[1]
		end

		for _, stallName in ipairs(stallOrder) do
			local slot = claimStallSlot(stallName)
			if slot then
				local waypointPos = getPoint("Food" .. stallName .. slot)
				if waypointPos then
					table.insert(route, 3, {
						position = waypointPos,
						pause = (slot == 1) and math.random(10, 18) or math.random(4, 9),
						isFood = (slot == 1),
						foodType = STALL_FOOD_TYPE[stallName],
						lookAt = STALL_LOOK_AT[stallName],
						stallName = stallName,
						stallSlot = slot,
					})
					break
				else
					releaseStallSlot(stallName, slot)
				end
			end
		end
	end

	if math.random() < plazaConfig.VisitorRouteChance then
		local plot = chooseVisitorPlot()
		if plot then
			-- Stadium sub-path: use laneOffset on the central-Z approach only
			local stadiumPathPoint = Vector3.new(laneOffset, STANDING_PIVOT_HEIGHT, plot.floor.Position.Z)
			table.insert(route, { position = stadiumPathPoint })
			table.insert(route, { position = getPlotEntrancePoint(plot), pause = 0.35 })
			table.insert(route, {
				position = getPlotSeatPoint(plot),
				pause = math.random(plazaConfig.StadiumVisitPauseMin, plazaConfig.StadiumVisitPauseMax),
				lookAt = plot.floor.Position,
				pose = "seated",
				clearFood = true,   -- drop food prop before sitting
			})
			table.insert(route, { position = getPlotEntrancePoint(plot), pause = 0.2 })
			table.insert(route, { position = stadiumPathPoint })
		end
	end

	table.insert(route, { position = lane(center) })
	table.insert(route, { position = lane(rawEnd) })
	return route
end

local function getStepPosition(step)
	return typeof(step) == "Vector3" and step or step.position
end

local function moveModelTo(model, targetPosition)
	if not model.Parent or not model.PrimaryPart then
		return false
	end

	local current = model:GetPivot()
	local currentPosition = current.Position
	local distance = (targetPosition - currentPosition).Magnitude
	if distance < 0.05 then
		return true
	end

	local direction = targetPosition - currentPosition
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
	local targetCFrame
	if horizontalDirection.Magnitude > 0.05 then
		targetCFrame = CFrame.lookAt(targetPosition, targetPosition + horizontalDirection.Unit)
	else
		targetCFrame = CFrame.new(targetPosition) * (current - currentPosition)
	end
	local duration = math.max(0.35, distance / plazaConfig.NpcWalkSpeed)

	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Value = current
	local connection = cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(cframeValue.Value)
		end
	end)

	local tween = TweenService:Create(cframeValue, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Value = targetCFrame,
	})
	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	cframeValue:Destroy()

	return model.Parent ~= nil
end

local function runFan(model)
	-- Each NPC gets a fixed lane offset for its lifetime so it always walks
	-- a consistent track through the plaza rather than drifting to the centre.
	-- Range: ±8 studs; avoid the very centre (±1) so there's a visible gap.
	local laneSign = math.random(1, 2) == 1 and 1 or -1
	local laneOffset = laneSign * (math.random(15, 80) / 10)   -- 1.5 – 8.0 studs

	task.spawn(function()
		task.wait(math.random() * 2)
		while running and model.Parent do
			local route = makeRoute(laneOffset)
			if route and #route >= 2 then
				setFanPose(model, "standing")
				local startPoint = getStepPosition(route[1])
				local nextPoint = getStepPosition(route[2])
				model:PivotTo(CFrame.lookAt(startPoint, nextPoint))
				setFanPose(model, "standing")

				local hasFood = false
				local heldStallName, heldStallSlot = nil, nil
				local function releaseHeldSlot()
					if heldStallName and heldStallSlot then
						releaseStallSlot(heldStallName, heldStallSlot)
						heldStallName, heldStallSlot = nil, nil
					end
				end

				for index = 2, #route do
					local step = route[index]
					local targetPosition = getStepPosition(step)

					if typeof(step) ~= "table" or step.pose ~= "seated" then
						setFanPose(model, "standing")
					end

					if not moveModelTo(model, targetPosition) then
						releaseHeldSlot()
						return
					end

					-- Face look-at target before pause (e.g. seated fans face the pitch)
					if typeof(step) == "table" and step.lookAt and model.Parent then
						local pivot = model:GetPivot()
						local flatLookAt = Vector3.new(step.lookAt.X, pivot.Position.Y, step.lookAt.Z)
						local delta = flatLookAt - pivot.Position
						if delta.Magnitude > 0.5 then
							model:PivotTo(CFrame.lookAt(pivot.Position, flatLookAt))
						end
					end

					-- Seated pose
					if typeof(step) == "table" and step.pose == "seated" then
						setFanPose(model, "seated")
					end

					-- Track this NPC's reserved queue slot (if any) so we can
					-- release it after the pause — and via the safety net if
					-- the model gets destroyed mid-pause.
					if typeof(step) == "table" and step.stallName and step.stallSlot then
						heldStallName = step.stallName
						heldStallSlot = step.stallSlot
					end

					-- Hand the NPC a prop BEFORE the pause so they hold it while
					-- waiting at the kiosk (looks like they received their order)
					if typeof(step) == "table" and step.isFood and not hasFood then
						setFoodProp(model, step.foodType)
						hasFood = true
					end

					-- Drop food prop before sitting so it doesn't float oddly
					if typeof(step) == "table" and step.clearFood and hasFood then
						setFoodProp(model, false)
						hasFood = false
					end

					if typeof(step) == "table" and step.pause and step.pause > 0 then
						task.wait(step.pause)
					end

					-- NPC has finished their stall stop — free the queue slot
					-- so the next fan can move up.
					releaseHeldSlot()

					task.wait(math.random(8, 22) / 100)
				end

				-- Safety: route loop exited normally — make sure no slot is left held.
				releaseHeldSlot()

				-- Clear prop at end of route
				if hasFood then
					setFoodProp(model, false)
				end
			else
				task.wait(1)
			end
		end
	end)
end

function CrowdService.Init(baseService, dataService)
	if running then
		return
	end

	BaseService = baseService
	DataService = dataService
	running = true

	task.spawn(function()
		local basesFolder = Workspace:WaitForChild("PlayerBases", 10)
		if not basesFolder then
			return
		end

		if fanFolder and fanFolder.Parent then
			fanFolder:Destroy()
		end

		fanFolder = make("Folder", {
			Name = "FanCrowd",
		}, basesFolder)

		for index = 1, plazaConfig.CrowdNpcCount do
			local fan = createFanNpc(index)
			runFan(fan)
		end
	end)
end

function CrowdService.Stop()
	running = false
	if fanFolder then
		fanFolder:Destroy()
		fanFolder = nil
	end
end

return CrowdService
]])

makeModule('DataService', SSS, [[local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Utils = require(ReplicatedStorage.Shared.Utils)

local DataService = {}

local STORE_VERSION = "v2"
local PlayerStore = DataStoreService:GetDataStore("UnboxAFootballer_PlayerData_" .. STORE_VERSION)

local DEFAULT_DATA = {
	coins = Constants.StartingCoins,
	gems = 0,
	starterGrantClaimed = false,
	inventory = {},
	rebirthTier = 0,
	rebirthTokens = 0,
	lastDailyReward = 0,
	lastFreePack = 0,
	baseLayoutData = {
		displayedCards = {},
		theme = "Default",
	},
	baseSlots = 6,
	upgrades = {
		PitchforkDamage = 0,
		PackSpawnRate = 0,
		PadLuck = 0,
		MoveSpeed = 0,
	},
	totalCardsOpened = 0,
	totalPacksOpened = 0,
	totalRebirths = 0,
	collectionRewards = {},
}

local cache = {}
local dirtyPlayers = {}

local function normalizeInventoryData(data)
	if not data then
		return false
	end

	if type(data.inventory) ~= "table" then
		data.inventory = {}
		return true
	end

	local normalized = {}
	local changed = false

	for key, amount in pairs(data.inventory) do
		local cardId = tonumber(key)
		local count = tonumber(amount)
		if cardId and count and count > 0 then
			local normalizedKey = tostring(math.floor(cardId))
			local normalizedCount = math.floor(count)
			normalized[normalizedKey] = (normalized[normalizedKey] or 0) + normalizedCount

			if type(key) ~= "string" or key ~= normalizedKey or amount ~= normalizedCount then
				changed = true
			end
		else
			changed = true
		end
	end

	for key, amount in pairs(normalized) do
		if data.inventory[key] ~= amount then
			changed = true
			break
		end
	end

	for key in pairs(data.inventory) do
		if normalized[key] == nil then
			changed = true
			break
		end
	end

	if changed then
		data.inventory = normalized
	end

	return changed
end

local function deepMergeDefaults(source, defaults)
	local merged = {}
	for key, defaultValue in pairs(defaults) do
		local value = source and source[key] or nil
		if type(defaultValue) == "table" then
			merged[key] = deepMergeDefaults(type(value) == "table" and value or {}, defaultValue)
		elseif value ~= nil then
			merged[key] = value
		else
			merged[key] = defaultValue
		end
	end
	return merged
end

local function tryDataStore(fn, retries)
	local attempts = retries or Constants.DataStoreRetries
	local lastError

	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end

		lastError = result
		if attempt < attempts then
			task.wait(Constants.DataStoreRetryBackoff[attempt] or 2)
		end
	end

	warn("[DataService] datastore failure:", lastError)
	return false, lastError
end

function DataService.MarkDirty(player)
	if player then
		dirtyPlayers[player] = true
	end
end

function DataService.LoadPlayer(player)
	local key = tostring(player.UserId)
	local ok, storedData = tryDataStore(function()
		return PlayerStore:GetAsync(key)
	end)

	cache[player] = deepMergeDefaults(ok and storedData or {}, DEFAULT_DATA)
	normalizeInventoryData(cache[player])
	DataService.MarkDirty(player)
	return cache[player]
end

function DataService.SavePlayer(player)
	local data = cache[player]
	if not data or not dirtyPlayers[player] then
		return true
	end

	local payload = Utils.DeepCopy(data)
	local key = tostring(player.UserId)
	local ok = tryDataStore(function()
		PlayerStore:SetAsync(key, payload)
	end)

	if ok then
		dirtyPlayers[player] = nil
	end

	return ok
end

function DataService.UnloadPlayer(player)
	cache[player] = nil
	dirtyPlayers[player] = nil
end

function DataService.GetData(player)
	return cache[player]
end

function DataService.GetCoins(player)
	local data = cache[player]
	return data and data.coins or 0
end

function DataService.AddCoins(player, amount)
	local data = cache[player]
	if not data then
		return false
	end

	data.coins += amount
	DataService.MarkDirty(player)
	return true
end

function DataService.SpendCoins(player, amount)
	local data = cache[player]
	if not data then
		return false, "Player data not loaded."
	end

	if amount < 0 then
		return false, "Invalid amount."
	end

	if data.coins < amount then
		return false, "Not enough Fans."
	end

	data.coins -= amount
	DataService.MarkDirty(player)
	return true
end

function DataService.AddCard(player, cardId, amount)
	local data = cache[player]
	if not data then
		return false
	end
	if normalizeInventoryData(data) then
		DataService.MarkDirty(player)
	end

	local key = tostring(cardId)
	local delta = amount or 1
	data.inventory[key] = (data.inventory[key] or 0) + delta
	DataService.MarkDirty(player)
	return true
end

function DataService.RemoveCard(player, cardId, amount)
	local data = cache[player]
	if not data then
		return false
	end
	if normalizeInventoryData(data) then
		DataService.MarkDirty(player)
	end

	local key = tostring(cardId)
	local delta = amount or 1
	local owned = data.inventory[key] or 0
	if owned < delta then
		return false
	end

	local newCount = owned - delta
	if newCount > 0 then
		data.inventory[key] = newCount
	else
		data.inventory[key] = nil
	end

	DataService.MarkDirty(player)
	return true
end

function DataService.GetCardCount(player, cardId)
	local data = cache[player]
	if not data then
		return 0
	end
	if normalizeInventoryData(data) then
		DataService.MarkDirty(player)
	end
	return data.inventory[tostring(cardId)] or 0
end

function DataService.HasCard(player, cardId)
	return DataService.GetCardCount(player, cardId) > 0
end

function DataService.GetInventory(player)
	local data = cache[player]
	if not data then
		return {}
	end
	if normalizeInventoryData(data) then
		DataService.MarkDirty(player)
	end
	return data.inventory
end

function DataService.GetDisplayedCards(player)
	local data = cache[player]
	if not data then
		return {}
	end
	return data.baseLayoutData.displayedCards
end

function DataService.GetDisplayedCard(player, slotIndex)
	local displayedCards = DataService.GetDisplayedCards(player)
	return displayedCards[tostring(slotIndex)]
end

function DataService.SetDisplayedCard(player, slotIndex, cardId)
	local data = cache[player]
	if not data then
		return false
	end

	data.baseLayoutData.displayedCards[tostring(slotIndex)] = cardId
	DataService.MarkDirty(player)
	return true
end

function DataService.ClearDisplayedCard(player, slotIndex)
	local data = cache[player]
	if not data then
		return false
	end

	data.baseLayoutData.displayedCards[tostring(slotIndex)] = nil
	DataService.MarkDirty(player)
	return true
end

function DataService.GetTotalPacksOpened(player)
	local data = cache[player]
	return data and (data.totalPacksOpened or data.totalCardsOpened or 0) or 0
end

function DataService.ResetForRebirth(player, startingFans)
	local data = cache[player]
	if not data then
		return false
	end

	data.coins = startingFans or Constants.StartingCoins
	data.inventory = {}
	data.baseLayoutData.displayedCards = {}
	data.upgrades = {
		PitchforkDamage = 0,
		PackSpawnRate = 0,
		PadLuck = 0,
		MoveSpeed = 0,
	}
	data.totalCardsOpened = 0
	data.totalPacksOpened = 0
	DataService.MarkDirty(player)
	return true
end

task.spawn(function()
	while true do
		task.wait(Constants.AutoSaveInterval)
		for player in pairs(dirtyPlayers) do
			if player and player.Parent then
				DataService.SavePlayer(player)
			end
		end
	end
end)

return DataService

]])

makeModule('EconomyService', SSS, [[local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local EconomyService = {}

local DataService

function EconomyService.Init(dataService)
	DataService = dataService
end

local function getData(player)
	return DataService and DataService.GetData(player)
end

function EconomyService.AddCoins(player, amount)
	local ok = DataService.AddCoins(player, amount)
	return ok, DataService.GetCoins(player)
end

function EconomyService.EnsureStarterCoins(player)
	local data = getData(player)
	if not data or data.starterGrantClaimed then
		return false
	end

	data.coins = math.max(data.coins or 0, Constants.StartingCoins)
	data.starterGrantClaimed = true
	DataService.MarkDirty(player)
	return true
end

function EconomyService.SpendCoins(player, amount)
	return DataService.SpendCoins(player, amount)
end

function EconomyService.CanClaimDailyReward(player)
	local data = getData(player)
	if not data then
		return false
	end
	return os.time() - (data.lastDailyReward or 0) >= Constants.DailyRewardCooldown
end

function EconomyService.TryGrantDailyReward(player)
	local data = getData(player)
	if not data then
		return false
	end
	if EconomyService.CanClaimDailyReward(player) then
		data.lastDailyReward = os.time()
		DataService.AddCoins(player, Constants.DailyRewardCoins)
		DataService.MarkDirty(player)
		return true
	end
	return false
end

function EconomyService.CanClaimFreePack(player)
	local data = getData(player)
	if not data then
		return false
	end
	return os.time() - (data.lastFreePack or 0) >= Constants.FreePackCooldown
end

function EconomyService.GetFreePackRemaining(player)
	local data = getData(player)
	if not data then
		return Constants.FreePackCooldown
	end
	return math.max(0, Constants.FreePackCooldown - (os.time() - (data.lastFreePack or 0)))
end

function EconomyService.ClaimFreePack(player)
	local data = getData(player)
	if not data then
		return false, "Your data is still loading."
	end
	if not EconomyService.CanClaimFreePack(player) then
		return false, "Free pack ready in " .. math.ceil(EconomyService.GetFreePackRemaining(player) / 60) .. "m."
	end
	data.lastFreePack = os.time()
	DataService.MarkDirty(player)
	return true
end

return EconomyService
]])

makeModule('MarketService', SSS, [[local MarketService = {}

function MarketService.ListCard()
	return false, "Transfer market has not been wired yet."
end

function MarketService.BuyListing()
	return false, "Transfer market has not been wired yet."
end

return MarketService
]])

makeModule('PackService', SSS, [[local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardData = require(ReplicatedStorage.Shared.CardData)
local PackConfig = require(ReplicatedStorage.Shared.PackConfig)
local Utils = require(ReplicatedStorage.Shared.Utils)

local PackService = {}

local DataService
local EconomyService
local Remotes

function PackService.Init(dataService, economyService, remotes)
	DataService = dataService
	EconomyService = economyService
	Remotes = remotes
end

local function buildAdjustedWeights(rebirthTier)
	local weights = {}
	for index, tier in ipairs(PackConfig.WeightTiers) do
		weights[index] = tier.weight
	end

	local upwardShift = math.min(rebirthTier or 0, PackConfig.MaxLuckShift)
	while upwardShift > 0 do
		for tierIndex = 1, #weights - 1 do
			if upwardShift <= 0 then
				break
			end

			local transferable = math.min(weights[tierIndex] - PackConfig.WeightFloorPerTier[tierIndex], 1)
			if transferable > 0 then
				weights[tierIndex] -= transferable
				weights[tierIndex + 1] += transferable
				upwardShift -= transferable
			end
		end

		if upwardShift > 0 and weights[1] <= PackConfig.WeightFloorPerTier[1] then
			break
		end
	end

	return weights
end

local function cardMatchesPack(card, packDef)
	if packDef.minimumRarity == "Rare Gold" then
		return card.rarity == "Rare Gold"
	end
	return true
end

local function getCardsInRange(minRating, maxRating, packDef)
	local results = {}
	for _, card in ipairs(CardData.Pool) do
		if card.rating >= minRating and card.rating <= maxRating and cardMatchesPack(card, packDef) then
			table.insert(results, card)
		end
	end
	return results
end

local function chooseRandomCard(pool)
	if #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

local function rollCard(weights, packDef)
	local tierIndex = Utils.WeightedRandom(weights)
	local tier = PackConfig.WeightTiers[tierIndex]
	local candidates = getCardsInRange(tier.minRating, tier.maxRating, packDef)
	if #candidates == 0 then
		candidates = CardData.Pool
	end
	return chooseRandomCard(candidates)
end

local function rollGuaranteed(minRating, packDef)
	local candidates = {}
	for _, card in ipairs(CardData.Pool) do
		if card.rating >= minRating and cardMatchesPack(card, packDef) then
			table.insert(candidates, card)
		end
	end
	return chooseRandomCard(candidates) or CardData.Pool[1]
end

local function serializeCard(card)
	return {
		id = card.id,
		name = card.name,
		nation = card.nation,
		position = card.position,
		rating = card.rating,
		rarity = card.rarity,
		sellValue = Utils.GetSellValue(card.rating),
		marketFloor = Utils.GetMarketFloor(card.rating),
	}
end

function PackService.OpenPack(player, packId, options)
	if not DataService or not EconomyService then
		return false, { error = "Pack service not ready." }
	end

	options = options or {}

	local packDef = PackConfig.ById[packId]
	if not packDef then
		return false, { error = "Unknown pack." }
	end

	local data = DataService.GetData(player)
	if not data then
		return false, { error = "Your data is still loading." }
	end

	if options.ignoreCost then
		-- Base pad spawns are free in this phase.
	elseif packDef.isFree then
		local ok, err = EconomyService.ClaimFreePack(player)
		if not ok then
			return false, { error = err or "Free pack is not ready yet." }
		end
	else
		local ok, err = EconomyService.SpendCoins(player, packDef.cost)
		if not ok then
			return false, { error = err or "Not enough Fans." }
		end
	end

	local weights = buildAdjustedWeights(data.rebirthTier or 0)
	local cards = {}

	for slot = 1, packDef.cardCount do
		local card
		if packDef.guaranteed and slot == packDef.guaranteed.slotIndex then
			card = rollGuaranteed(packDef.guaranteed.minRating, packDef)
		else
			card = rollCard(weights, packDef)
		end

		if not card then
			return false, { error = "Pack roll failed. Please try again." }
		end

		table.insert(cards, serializeCard(card))
	end

	data.totalCardsOpened = (data.totalCardsOpened or 0) + #cards
	data.totalPacksOpened = (data.totalPacksOpened or 0) + 1
	DataService.MarkDirty(player)

	if Remotes and Remotes.UpdateCoins then
		Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
	end

	return true, {
		success = true,
		packId = packId,
		packName = packDef.displayName,
		isFree = options.ignoreCost == true or packDef.cost == 0,
		newCoins = DataService.GetCoins(player),
		card = cards[1],
		cards = cards,
	}
end

return PackService

]])

makeModule('RebirthService', SSS, [[local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardData = require(ReplicatedStorage.Shared.CardData)
local Constants = require(ReplicatedStorage.Shared.Constants)

local RebirthService = {}

local DataService

local rebirthConfig = Constants.Rebirth

local function getData(player)
	return DataService and DataService.GetData(player)
end

local function getOwnedSpecialCount(data)
	local count = 0
	local inventory = data.inventory or {}
	local displayedCards = data.baseLayoutData and data.baseLayoutData.displayedCards or {}

	for _, card in ipairs(CardData.Pool) do
		if card.rarity == rebirthConfig.SpecialRarity then
			count += inventory[tostring(card.id)] or 0
		end
	end

	for _, cardId in pairs(displayedCards) do
		local card = CardData.ById[tonumber(cardId)]
		if card and card.rarity == rebirthConfig.SpecialRarity then
			count += 1
		end
	end

	return count
end

function RebirthService.Init(dataService)
	DataService = dataService
end

function RebirthService.GetRequiredFans(rebirthTier)
	return math.floor(rebirthConfig.BaseFanRequirement * (rebirthConfig.FanRequirementMultiplier ^ (rebirthTier or 0)))
end

function RebirthService.GetFanMultiplier(rebirthTier)
	rebirthTier = math.max(0, rebirthTier or 0)

	local milestones = rebirthConfig.MultiplierMilestones or {}
	if #milestones == 0 then
		return 1
	end

	local previous = milestones[1]
	for index = 2, #milestones do
		local current = milestones[index]
		if rebirthTier == current.tier then
			return current.multiplier
		end

		if rebirthTier < current.tier then
			local span = math.max(1, current.tier - previous.tier)
			local alpha = (rebirthTier - previous.tier) / span
			return previous.multiplier + ((current.multiplier - previous.multiplier) * alpha)
		end

		previous = current
	end

	return previous.multiplier + ((rebirthTier - previous.tier) * 0.5)
end

function RebirthService.GetStatus(player)
	local data = getData(player)
	if not data then
		return {
			canRebirth = false,
			reason = "Your data is still loading.",
		}
	end

	local tier = data.rebirthTier or 0
	local requiredFans = RebirthService.GetRequiredFans(tier)
	local currentFans = data.coins or 0
	local specialCount = getOwnedSpecialCount(data)
	local requiredSpecialCards = rebirthConfig.RequiredSpecialCards

	local canRebirth = currentFans >= requiredFans and specialCount >= requiredSpecialCards
	local reason
	if currentFans < requiredFans then
		reason = "You need more Fans."
	elseif specialCount < requiredSpecialCards then
		reason = string.format("You need %d %s players.", requiredSpecialCards, rebirthConfig.SpecialRarity)
	end

	return {
		canRebirth = canRebirth,
		reason = reason,
		rebirthTier = tier,
		currentFans = currentFans,
		requiredFans = requiredFans,
		specialCount = specialCount,
		requiredSpecialCards = requiredSpecialCards,
		specialRarity = rebirthConfig.SpecialRarity,
		currentMultiplier = RebirthService.GetFanMultiplier(tier),
		nextMultiplier = RebirthService.GetFanMultiplier(tier + 1),
		rebirthTokens = data.rebirthTokens or 0,
	}
end

function RebirthService.CanRebirth(player)
	local status = RebirthService.GetStatus(player)
	return status.canRebirth, status.reason, status
end

function RebirthService.PerformRebirth(player)
	local canRebirth, reason, status = RebirthService.CanRebirth(player)
	if not canRebirth then
		return false, status or { reason = reason or "You cannot rebirth yet." }
	end

	local data = getData(player)
	if not data then
		return false, { reason = "Your data is still loading." }
	end

	local nextTier = (data.rebirthTier or 0) + 1
	local nextTokens = (data.rebirthTokens or 0) + 1
	local nextTotal = (data.totalRebirths or 0) + 1

	DataService.ResetForRebirth(player, rebirthConfig.StartingFansAfterRebirth)
	data.rebirthTier = nextTier
	data.rebirthTokens = nextTokens
	data.totalRebirths = nextTotal
	DataService.MarkDirty(player)

	return true, RebirthService.GetStatus(player)
end

return RebirthService

]])

makeModule('TradeService', SSS, [[local TradeService = {}

function TradeService.RequestTrade()
	return false, "Trading has not been wired yet."
end

function TradeService.ValidateTrade()
	return false, "Trading has not been wired yet."
end

return TradeService
]])

makeScript('Main', SSS, [[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

if ServerScriptService:GetAttribute("UnboxMainBooted") then
	warn("[UnboxAFootballer] Duplicate Main detected, skipping older copy")
	return
end
ServerScriptService:SetAttribute("UnboxMainBooted", true)
Players.CharacterAutoLoads = false

for _, child in ipairs(ServerScriptService:GetChildren()) do
	if child:IsA("Script") and child ~= script and child.Name == script.Name then
		child.Disabled = true
	end
end

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared:WaitForChild("Constants"))
local DataService = require(ServerScriptService:WaitForChild("DataService"))
local EconomyService = require(ServerScriptService:WaitForChild("EconomyService"))
local PackService = require(ServerScriptService:WaitForChild("PackService"))
local BaseService = require(ServerScriptService:WaitForChild("BaseService"))
local CrowdService = require(ServerScriptService:WaitForChild("CrowdService"))
local RebirthService = require(ServerScriptService:WaitForChild("RebirthService"))

local PackConfig = require(Shared:WaitForChild("PackConfig"))
local CardData = require(Shared:WaitForChild("CardData"))
local Utils = require(Shared:WaitForChild("Utils"))

local existingRemotes = ReplicatedStorage:FindFirstChild("Remotes")
if existingRemotes then
	existingRemotes:Destroy()
end

local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local function makeEvent(name)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = Remotes
	return event
end

local function makeFunction(name)
	local fn = Instance.new("RemoteFunction")
	fn.Name = name
	fn.Parent = Remotes
	return fn
end

local UpdateCoinsEvent = makeEvent("UpdateCoins")
local PackOpenedEvent = makeEvent("PackOpened")
local PackOpenFailedEvent = makeEvent("PackOpenFailed")
local PromptPackShopEvent = makeEvent("PromptPackShop")
local RequestPitchforkHitEvent = makeEvent("RequestPitchforkHit")
local OpenSlotPickerEvent = makeEvent("OpenSlotPicker")

local GetPlayerDataFn = makeFunction("GetPlayerData")
local OpenPackFn = makeFunction("OpenPack")
local SellCardFn = makeFunction("SellCard")
local SellAllCardsFn = makeFunction("SellAllCards")
local GetInventoryFn = makeFunction("GetInventory")
local GetUpgradesFn = makeFunction("GetUpgrades")
local PurchaseUpgradeFn = makeFunction("PurchaseUpgrade")
local PlaceInventoryCardInSlotFn = makeFunction("PlaceInventoryCardInSlot")
local ClaimFreePackFn = makeFunction("ClaimFreePack")
local ClaimDailyRewardFn = makeFunction("ClaimDailyReward")
local GetRebirthStatusFn = makeFunction("GetRebirthStatus")
local RequestRebirthFn = makeFunction("RequestRebirth")

PackService.Init(DataService, EconomyService, {
	UpdateCoins = UpdateCoinsEvent,
	PackOpened = PackOpenedEvent,
	PackOpenFailed = PackOpenFailedEvent,
})
EconomyService.Init(DataService)
RebirthService.Init(DataService)

BaseService.BuildBaseMap()
CrowdService.Init(BaseService, DataService)

local swingCooldowns = {}
local initializedPlayers = {}

local function makeToolPart(name, size, color, cframe, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Anchored = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function weldParts(part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
end

local function createPitchforkTool()
	local tool = Instance.new("Tool")
	tool.Name = "Pitchfork"
	tool.ToolTip = "Swing at the pack on your red pad."
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -1.4, -0.9) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(-18))

	local handle = makeToolPart("Handle", Vector3.new(0.3, 4.4, 0.3), Color3.fromRGB(122, 84, 50), CFrame.new(), tool)
	local collar = makeToolPart("Collar", Vector3.new(0.8, 0.18, 0.8), Color3.fromRGB(70, 74, 82), handle.CFrame * CFrame.new(0, 1.9, 0), tool)
	local tineLeft = makeToolPart("TineLeft", Vector3.new(0.12, 1.3, 0.12), Color3.fromRGB(180, 182, 188), handle.CFrame * CFrame.new(-0.22, 2.45, 0), tool)
	local tineMiddle = makeToolPart("TineMiddle", Vector3.new(0.12, 1.45, 0.12), Color3.fromRGB(205, 208, 214), handle.CFrame * CFrame.new(0, 2.52, 0), tool)
	local tineRight = makeToolPart("TineRight", Vector3.new(0.12, 1.3, 0.12), Color3.fromRGB(180, 182, 188), handle.CFrame * CFrame.new(0.22, 2.45, 0), tool)
	local crossbar = makeToolPart("Crossbar", Vector3.new(0.72, 0.12, 0.12), Color3.fromRGB(160, 162, 168), handle.CFrame * CFrame.new(0, 1.95, 0), tool)

	weldParts(handle, collar)
	weldParts(handle, tineLeft)
	weldParts(handle, tineMiddle)
	weldParts(handle, tineRight)
	weldParts(handle, crossbar)

	return tool
end

local function ensurePitchfork(player)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	local starterGear = player:FindFirstChild("StarterGear") or player:WaitForChild("StarterGear", 5)
	local character = player.Character

	local hasEquipped = character and character:FindFirstChild("Pitchfork")
	if starterGear and not starterGear:FindFirstChild("Pitchfork") then
		createPitchforkTool().Parent = starterGear
	end

	if backpack and not hasEquipped and not backpack:FindFirstChild("Pitchfork") then
		createPitchforkTool().Parent = backpack
	end
end

local function placeCharacterAtOwnedPlot(player, character)
	if not player or not player.Parent or not character or not character.Parent then
		return false
	end

	local placed = BaseService.PlaceCharacterAtPlot(player, character)
	ensurePitchfork(player)

	task.delay(0.75, function()
		if player.Parent and character.Parent then
			BaseService.PlaceCharacterAtPlot(player, character)
			ensurePitchfork(player)
		end
	end)

	return placed
end

local function sendHint(player, message, extraPayload)
	if player and player.Parent then
		local payload = {
			message = message,
			coins = DataService.GetCoins(player),
		}
		for key, value in pairs(extraPayload or {}) do
			payload[key] = value
		end
		PromptPackShopEvent:FireClient(player, payload)
	end
end

local function getUpgradeLevel(player, key)
	local data = DataService.GetData(player)
	if not data or not data.upgrades then
		return 0
	end
	return data.upgrades[key] or 0
end

local function getUpgradeCost(key, level)
	local spec = Constants.Upgrades[key]
	if not spec or level >= spec.maxLevel then
		return nil
	end
	return math.floor(spec.baseCost * (spec.costMultiplier ^ level))
end

local function computePitchforkDamage(level)
	local spec = Constants.Upgrades.PitchforkDamage
	return spec.baseDamage + level * spec.damagePerLevel
end

local function computeSpawnDelay(level)
	local spec = Constants.Upgrades.PackSpawnRate
	return math.max(spec.minDelay, spec.baseDelay - level * spec.delayReductionPerLevel)
end

local function computeLuckShift(level)
	local spec = Constants.Upgrades.PadLuck
	return math.min(level * spec.shiftPerLevel, spec.maxShift)
end

local function computeWalkSpeed(level)
	local spec = Constants.Upgrades.MoveSpeed
	return math.min(spec.baseWalkSpeed + level * spec.speedPerLevel, spec.maxWalkSpeed)
end

local function getPitchforkDamage(player)
	return computePitchforkDamage(getUpgradeLevel(player, "PitchforkDamage"))
end

local function applyMovementUpgrade(player, character)
	local targetCharacter = character or player.Character
	local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = computeWalkSpeed(getUpgradeLevel(player, "MoveSpeed"))
end

local function createSurfaceLabel(face, title, subtitle, color, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 0
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(22, 18, 8)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 247, 191)),
		ColorSequenceKeypoint.new(0.35, color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(96, 66, 10)),
	})
	gradient.Rotation = 25
	gradient.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(31, 24, 10)
	stroke.Thickness = 3
	stroke.Parent = frame

	local top = Instance.new("TextLabel")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(0.42, 0, 0.28, 0)
	top.Position = UDim2.new(0.06, 0, 0.06, 0)
	top.Text = title
	top.TextColor3 = Color3.fromRGB(20, 15, 8)
	top.TextScaled = true
	top.Font = Enum.Font.GothamBlack
	top.TextXAlignment = Enum.TextXAlignment.Left
	top.Parent = frame

	local middle = Instance.new("TextLabel")
	middle.BackgroundTransparency = 1
	middle.Size = UDim2.new(0.84, 0, 0.22, 0)
	middle.Position = UDim2.new(0.08, 0, 0.61, 0)
	middle.Text = subtitle
	middle.TextColor3 = Color3.fromRGB(48, 38, 14)
	middle.TextScaled = true
	middle.Font = Enum.Font.GothamBold
	middle.Parent = frame

	local stripes = Instance.new("Frame")
	stripes.BackgroundTransparency = 0.8
	stripes.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	stripes.Size = UDim2.new(0.52, 0, 0.62, 0)
	stripes.Position = UDim2.new(0.42, 0, 0.08, 0)
	stripes.Rotation = -18
	stripes.BorderSizePixel = 0
	stripes.Parent = frame

	local stripeGradient = Instance.new("UIGradient")
	stripeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.8, 0.9),
		NumberSequenceKeypoint.new(1, 1),
	})
	stripeGradient.Rotation = 90
	stripeGradient.Parent = stripes
end

local function pulseLight(light, baseBrightness, peakBrightness, duration)
	if not light or not light.Parent then
		return
	end

	light.Brightness = peakBrightness
	task.delay(duration or 0.12, function()
		if light and light.Parent then
			light.Brightness = baseBrightness
		end
	end)
end

local function playPackHitEffect(plot, settleBrightness)
	if not plot or not plot.activePackBody then
		return
	end

	if plot.activePackHitEmitter then
		plot.activePackHitEmitter:Emit(14)
	end

	if plot.activePackHighlight then
		plot.activePackHighlight.FillTransparency = 0.2
		plot.activePackHighlight.OutlineTransparency = 0.05
		task.delay(0.08, function()
			if plot.activePackHighlight and plot.activePackHighlight.Parent then
				plot.activePackHighlight.FillTransparency = 1
				plot.activePackHighlight.OutlineTransparency = 0.82
			end
		end)
	end

	local baseBrightness = settleBrightness or plot.activePackBaseBrightness or 1.15
	pulseLight(plot.activePackLight, baseBrightness, baseBrightness + 1.25, 0.1)

	for _, part in ipairs(plot.activePackImpactParts or {}) do
		if part and part.Parent then
			local originalSize = part.Size
			local growSize = Vector3.new(originalSize.X + 0.08, originalSize.Y + 0.08, originalSize.Z + 0.08)
			TweenService:Create(part, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = growSize,
			}):Play()
			task.delay(0.07, function()
				if part and part.Parent then
					TweenService:Create(part, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = originalSize,
					}):Play()
				end
			end)
		end
	end
end

local function rollPadPackForPlayer(player)
	local weights = {}
	for _, packDef in ipairs(PackConfig.PadSpawnOrder) do
		table.insert(weights, packDef.padWeight or 1)
	end

	if player and #weights >= 3 then
		local shift = computeLuckShift(getUpgradeLevel(player, "PadLuck"))
		local takeable = math.max(0, weights[1] - 5)
		local taken = math.min(shift, takeable)
		weights[1] = weights[1] - taken
		local toRare = math.floor(taken * 0.6)
		local toPremium = taken - toRare
		weights[2] = weights[2] + toRare
		weights[3] = weights[3] + toPremium
	end

	local chosenIndex = Utils.WeightedRandom(weights)
	return PackConfig.PadSpawnOrder[chosenIndex]
end

local function getCardById(cardId)
	return cardId and CardData.ById[tonumber(cardId)] or nil
end

local function getBestInventoryCard(player)
	local inventory = DataService.GetInventory(player)
	local bestCard

	for key, amount in pairs(inventory) do
		if amount > 0 then
			local card = getCardById(key)
			if card then
				if not bestCard or card.rating > bestCard.rating or (card.rating == bestCard.rating and card.name < bestCard.name) then
					bestCard = card
				end
			end
		end
	end

	return bestCard
end

local function getDisplayedIncomePerSecond(player)
	local displayedCards = DataService.GetDisplayedCards(player)
	local total = 0
	local data = DataService.GetData(player)
	local multiplier = type(RebirthService.GetFanMultiplier) == "function"
		and RebirthService.GetFanMultiplier(data and data.rebirthTier or 0)
		or 1

	for _, cardId in pairs(displayedCards) do
		local card = getCardById(cardId)
		if card then
			total += math.floor(Utils.GetPassiveIncome(card.rating) * multiplier)
		end
	end

	return total
end

local function getCardIncome(player, card)
	if not card then
		return 0
	end

	local data = DataService.GetData(player)
	local multiplier = type(RebirthService.GetFanMultiplier) == "function"
		and RebirthService.GetFanMultiplier(data and data.rebirthTier or 0)
		or 1
	return math.floor(Utils.GetPassiveIncome(card.rating) * multiplier)
end

local function refreshPlotDisplayState(player, plot)
	if not player or not plot then
		return
	end

	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		local displayedCardId = DataService.GetDisplayedCard(player, slot.slotIndex)
		local displayedCard = getCardById(displayedCardId)
		if displayedCard then
			BaseService.UpdateDisplaySlot(slot, displayedCard, getCardIncome(player, displayedCard))
		else
			local bestInventoryCard = getBestInventoryCard(player)
			BaseService.SetDisplaySlotAddReady(slot, bestInventoryCard and "Choose Player" or "Inventory Empty", bestInventoryCard ~= nil)
		end
	end
end

local function getFirstEmptyDisplaySlot(player, plot)
	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		if not DataService.GetDisplayedCard(player, slot.slotIndex) then
			return slot
		end
	end

	return nil
end

local function getDisplaySlotByIndex(plot, slotIndex)
	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		if slot.slotIndex == slotIndex then
			return slot
		end
	end

	return nil
end

local function placeCardOnDisplay(player, plot, slot, cardId)
	local card = getCardById(cardId)
	if not card or not slot then
		return false
	end

	DataService.SetDisplayedCard(player, slot.slotIndex, card.id)
	BaseService.UpdateDisplaySlot(slot, card, getCardIncome(player, card))
	return true
end

local function autoStorePulledCard(player, plot, card)
	if not player or not plot or not card then
		return {
			storedInInventory = true,
			slotIndex = nil,
			slotWorldPosition = nil,
		}
	end

	local emptySlot = getFirstEmptyDisplaySlot(player, plot)
	if emptySlot then
		placeCardOnDisplay(player, plot, emptySlot, card.id)
		refreshPlotDisplayState(player, plot)
		return {
			storedInInventory = false,
			slotIndex = emptySlot.slotIndex,
			slotWorldPosition = emptySlot.top.Position + Vector3.new(0, 4.4, 0),
		}
	end

	DataService.AddCard(player, card.id)
	refreshPlotDisplayState(player, plot)
	return {
		storedInInventory = true,
		slotIndex = nil,
		slotWorldPosition = nil,
	}
end

local function moveDisplayedCardToInventory(player, plot, slot)
	local cardId = DataService.GetDisplayedCard(player, slot.slotIndex)
	local card = getCardById(cardId)
	if not card then
		return false, "There is no player on that slot."
	end

	DataService.ClearDisplayedCard(player, slot.slotIndex)
	DataService.AddCard(player, card.id)
	refreshPlotDisplayState(player, plot)
	return true, card
end

local function addInventoryCardToDisplay(player, plot, slot, cardId)
	local card = getCardById(cardId)
	if not card then
		return false, "Choose a valid player."
	end

	if DataService.GetDisplayedCard(player, slot.slotIndex) then
		return false, "That display slot is already occupied."
	end

	if not DataService.RemoveCard(player, card.id) then
		return false, "That player is no longer in your inventory."
	end

	placeCardOnDisplay(player, plot, slot, card.id)
	refreshPlotDisplayState(player, plot)
	return true, card
end

local function clearPlotPack(plot)
	if plot.activePackModel and plot.activePackModel.Parent then
		plot.activePackModel:Destroy()
	end
	plot.activePackModel = nil
	plot.activePackDef = nil
	plot.activePackBody = nil
	plot.activePackLight = nil
	plot.activePackBaseBrightness = nil
	plot.activePackHitsRemaining = nil
	plot.activePackMaxHits = nil
	plot.activePackHitEmitter = nil
	plot.activePackHighlight = nil
	plot.activePackImpactParts = nil
	plot.isOpeningPack = nil
end

local function spawnPackForPlot(plot)
	if not plot or not plot.ownerPlayer then
		return
	end

	clearPlotPack(plot)

	local packDef = rollPadPackForPlayer(plot.ownerPlayer)
	if not packDef then
		return
	end

	local model = Instance.new("Model")
	model.Name = packDef.id
	model.Parent = plot.model

	local basePosition = plot.packPad.Position + Vector3.new(0, 5.4, 0)
	local lookDirection = Vector3.new(plot.facingDirection, 0, 0)
	local rootCFrame = CFrame.lookAt(basePosition, basePosition + lookDirection)

	local cardBody = Instance.new("Part")
	cardBody.Name = "PackBody"
	cardBody.Anchored = true
	cardBody.Material = Enum.Material.SmoothPlastic
	cardBody.Color = Color3.fromRGB(28, 22, 8)
	cardBody.Size = Vector3.new(5.4, 8, 0.3)
	cardBody.CFrame = rootCFrame
	cardBody.Parent = model

	local topCap = Instance.new("WedgePart")
	topCap.Name = "TopCap"
	topCap.Anchored = true
	topCap.Material = Enum.Material.SmoothPlastic
	topCap.Color = Color3.fromRGB(28, 22, 8)
	topCap.Size = Vector3.new(5.4, 1.4, 0.3)
	topCap.CFrame = cardBody.CFrame * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
	topCap.Parent = model

	local bottomCap = Instance.new("WedgePart")
	bottomCap.Name = "BottomCap"
	bottomCap.Anchored = true
	bottomCap.Material = Enum.Material.SmoothPlastic
	bottomCap.Color = Color3.fromRGB(20, 16, 6)
	bottomCap.Size = Vector3.new(5.4, 1.6, 0.3)
	bottomCap.CFrame = cardBody.CFrame * CFrame.new(0, -4.8, 0)
	bottomCap.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = packDef.color
	glow.Range = 12
	glow.Brightness = 1.15
	glow.Parent = cardBody

	local hitAttachment = Instance.new("Attachment")
	hitAttachment.Name = "HitAttachment"
	hitAttachment.Parent = cardBody

	local hitEmitter = Instance.new("ParticleEmitter")
	hitEmitter.Name = "HitBurst"
	hitEmitter.Enabled = false
	hitEmitter.Rate = 0
	hitEmitter.Lifetime = NumberRange.new(0.16, 0.28)
	hitEmitter.Speed = NumberRange.new(2.5, 6.5)
	hitEmitter.SpreadAngle = Vector2.new(38, 38)
	hitEmitter.Drag = 4
	hitEmitter.LightEmission = 1
	hitEmitter.LightInfluence = 0
	hitEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 212)),
		ColorSequenceKeypoint.new(0.5, packDef.color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	hitEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.26),
		NumberSequenceKeypoint.new(0.35, 0.42),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	hitEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.6, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	hitEmitter.Parent = hitAttachment

	local hitHighlight = Instance.new("Highlight")
	hitHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	hitHighlight.FillColor = packDef.color
	hitHighlight.FillTransparency = 1
	hitHighlight.OutlineColor = Color3.fromRGB(255, 245, 190)
	hitHighlight.OutlineTransparency = 0.82
	hitHighlight.Parent = model

	createSurfaceLabel(Enum.NormalId.Front, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)
	createSurfaceLabel(Enum.NormalId.Back, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)

	-- Continuous idle: slow spin + gentle float.  All three parts updated together so
	-- they never drift apart (the old tween only moved cardBody, leaving caps behind).
	local packOriginX = basePosition.X
	local packOriginY = basePosition.Y + 5.4
	local packOriginZ = basePosition.Z
	local packSpinAngle = 0
	task.spawn(function()
		while model.Parent do
			packSpinAngle = packSpinAngle + math.rad(34) / 30 -- ≈ 34°/s slow spin
			local floatY = packOriginY + math.sin(os.clock() * 1.3) * 0.30
			local baseCF = CFrame.new(packOriginX, floatY, packOriginZ)
				* CFrame.Angles(0, packSpinAngle, 0)
			if model.Parent then
				cardBody.CFrame = baseCF
				topCap.CFrame = baseCF * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
				bottomCap.CFrame = baseCF * CFrame.new(0, -4.8, 0)
			end
			task.wait(1 / 30)
		end
	end)

	plot.activePackModel = model
	plot.activePackDef = packDef
	plot.activePackBody = cardBody
	plot.activePackLight = glow
	plot.activePackBaseBrightness = glow.Brightness
	plot.activePackMaxHits = packDef.hitsRequired or 3
	plot.activePackHitsRemaining = plot.activePackMaxHits
	plot.activePackHitEmitter = hitEmitter
	plot.activePackHighlight = hitHighlight
	plot.activePackImpactParts = { cardBody, topCap, bottomCap }

	BaseService.SetPlotPadHealth(plot, packDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, packDef.color)
	sendHint(plot.ownerPlayer, packDef.displayName .. " spawned on your red pad. Crack it with your pitchfork and use Hold E on green slots to swap players.")
end

for _, plot in ipairs(BaseService.GetPlots()) do
	BaseService.SetPlotPadStatus(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		slot.prompt.Triggered:Connect(function(player)
			if plot.ownerPlayer ~= player then
				PackOpenFailedEvent:FireClient(player, {
					error = (plot.ownerPlayer and plot.ownerPlayer.DisplayName or "Another player") .. "'s display slot is on this base.",
				})
				return
			end

			if DataService.GetDisplayedCard(player, slot.slotIndex) then
				local ok, cardOrError = moveDisplayedCardToInventory(player, plot, slot)
				if ok then
					sendHint(player, cardOrError.name .. " moved into your inventory. Hold E on this slot to place a stored player.")
				else
					PackOpenFailedEvent:FireClient(player, { error = cardOrError })
				end
			else
				if not getBestInventoryCard(player) then
					PackOpenFailedEvent:FireClient(player, {
						error = "You do not have a stored player to add.",
					})
					return
				end

				OpenSlotPickerEvent:FireClient(player, {
					slotIndex = slot.slotIndex,
				})
				sendHint(player, "Choose a stored player for display slot " .. tostring(slot.slotIndex) .. ".")
			end
		end)
	end
end

RequestPitchforkHitEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	local lastSwing = swingCooldowns[player]
	if lastSwing and (now - lastSwing) < Constants.Pitchfork.SwingCooldown then
		return
	end
	swingCooldowns[player] = now

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local equippedTool = character and character:FindFirstChildOfClass("Tool")
	if not humanoid or not rootPart or not equippedTool or equippedTool.Name ~= "Pitchfork" then
		PackOpenFailedEvent:FireClient(player, {
			error = "Equip your pitchfork first.",
		})
		return
	end

	local plot = BaseService.GetPlot(player)
	if plot and plot.isOpeningPack then
		return
	end

	if not plot or not plot.activePackDef or not plot.activePackBody then
		PackOpenFailedEvent:FireClient(player, {
			error = "Your next pack is still spawning.",
		})
		return
	end

	local packDelta = plot.activePackBody.Position - rootPart.Position
	if packDelta.Magnitude > Constants.Pitchfork.HitRange then
		PackOpenFailedEvent:FireClient(player, {
			error = "Move closer to the pack on your red pad.",
		})
		return
	end

	local flatPackDelta = Vector3.new(packDelta.X, 0, packDelta.Z)
	local flatLookVector = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
	if flatPackDelta.Magnitude > 0.1 and flatLookVector.Magnitude > 0.1 then
		local facingDot = flatLookVector.Unit:Dot(flatPackDelta.Unit)
		if facingDot < (Constants.Pitchfork.HitFacingDot or 0.5) then
			PackOpenFailedEvent:FireClient(player, {
				error = "Face the pack directly before swinging.",
			})
			return
		end
	end

	local damage = getPitchforkDamage(player)
	plot.activePackHitsRemaining = math.max(0, (plot.activePackHitsRemaining or plot.activePackMaxHits or 1) - damage)
	local newBrightness = nil

	if plot.activePackLight then
		newBrightness = 1.15 + ((plot.activePackMaxHits - plot.activePackHitsRemaining) * 0.28)
		plot.activePackLight.Brightness = newBrightness
	end

	playPackHitEffect(plot, newBrightness)

	if plot.activePackHitsRemaining > 0 then
		BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
		return
	end

	plot.isOpeningPack = true
	BaseService.SetPlotPadStatus(plot, "Pack Cracked", "Claiming your player", plot.activePackDef.color)

	-- ── Pack crack burst animation ────────────────────────────────────
	-- Fire before the card pull so players see the pack explode open.
	if plot.activePackHitEmitter then
		plot.activePackHitEmitter:Emit(44)
	end
	if plot.activePackLight then
		plot.activePackLight.Brightness = 4.8
		plot.activePackLight.Range = 24
	end
	if plot.activePackHighlight then
		plot.activePackHighlight.FillTransparency = 0
		plot.activePackHighlight.FillColor = Color3.fromRGB(255, 255, 255)
	end
	-- Expand + fade all three pack parts simultaneously
	for _, part in ipairs(plot.activePackImpactParts or {}) do
		if part and part.Parent then
			TweenService:Create(
				part,
				TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = part.Size * 1.65, Transparency = 1 }
			):Play()
		end
	end
	task.wait(0.38) -- hold the drama before the card appears

	local openedPackId = plot.activePackDef.id
	local openedPackColor = plot.activePackDef.color
	local openedPackWorldPosition = plot.activePackBody.Position + Vector3.new(0, 2.5, 0)

	local openCallOk, ok, result = pcall(PackService.OpenPack, player, openedPackId, {
		ignoreCost = true,
		source = "pitchfork",
	})

	if not openCallOk then
		warn("[UnboxAFootballer] PackService.OpenPack crashed:", ok)
		ok = false
		result = { error = "Pack opening failed. Please try again." }
	end

	if ok then
		local pulledCard = result.card or (result.cards and result.cards[1]) or nil
		if not pulledCard then
			plot.isOpeningPack = nil
			plot.activePackHitsRemaining = math.max(1, plot.activePackHitsRemaining or 1)
			BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
			PackOpenFailedEvent:FireClient(player, { error = "Pack roll failed. Please try again." })
			return
		end

		local storageOk, storageResult = pcall(autoStorePulledCard, player, plot, pulledCard)
		if not storageOk then
			warn("[UnboxAFootballer] Auto-store failed; falling back to inventory:", storageResult)
			DataService.AddCard(player, pulledCard.id)
			refreshPlotDisplayState(player, plot)
			storageResult = {
				storedInInventory = true,
				slotIndex = nil,
				slotWorldPosition = nil,
			}
		end

		local passiveIncome = getCardIncome(player, pulledCard)

		PackOpenedEvent:FireClient(player, {
			success = true,
			packId = result.packId,
			packName = result.packName,
			newCoins = result.newCoins,
			card = pulledCard,
			storedInInventory = storageResult.storedInInventory,
			slotIndex = storageResult.slotIndex,
			slotWorldPosition = storageResult.slotWorldPosition,
			packWorldPosition = openedPackWorldPosition,
			coinsPerSecond = passiveIncome,
			passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
		})

		local milestoneOk, milestoneErr = pcall(BaseService.UpdatePackMilestone, plot, DataService.GetTotalPacksOpened(player))
		if not milestoneOk then
			warn("[UnboxAFootballer] Pack milestone update failed:", milestoneErr)
		end

		if pulledCard then
			if storageResult.storedInInventory then
				sendHint(player, pulledCard.name .. " went to inventory because your display slots are full.")
			else
				sendHint(player, pulledCard.name .. " is now earning +" .. tostring(passiveIncome) .. "/s on display slot " .. tostring(storageResult.slotIndex) .. ".")
			end
		end

		clearPlotPack(plot)
		BaseService.SetPlotPadStatus(plot, "Rolling Next Pack", "Another free pack is spawning", openedPackColor)
		local respawnDelay = computeSpawnDelay(getUpgradeLevel(player, "PackSpawnRate"))
		task.delay(respawnDelay, function()
			if plot.ownerPlayer == player then
				spawnPackForPlot(plot)
			end
		end)
	else
		plot.isOpeningPack = nil
		plot.activePackHitsRemaining = math.max(1, plot.activePackHitsRemaining or 1)
		BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
		PackOpenFailedEvent:FireClient(player, result)
	end
end)

local function handlePlayerAdded(player)
	if initializedPlayers[player] then
		ensurePitchfork(player)
		if player.Character then
			placeCharacterAtOwnedPlot(player, player.Character)
		end
		return
	end
	initializedPlayers[player] = true

	local data = DataService.LoadPlayer(player)
	local plot = BaseService.AssignPlot(player)
	EconomyService.EnsureStarterCoins(player)
	EconomyService.TryGrantDailyReward(player)
	ensurePitchfork(player)

	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if player.Parent and character.Parent then
				placeCharacterAtOwnedPlot(player, character)
				applyMovementUpgrade(player, character)
			end
		end)

		task.defer(function()
			local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
			if humanoid then
				humanoid.Died:Once(function()
					task.delay(3, function()
						if player.Parent then
							player:LoadCharacter()
						end
					end)
				end)
			end
		end)
	end)

	if player.Character then
		task.defer(function()
			if player.Parent and player.Character then
				placeCharacterAtOwnedPlot(player, player.Character)
				applyMovementUpgrade(player, player.Character)
			end
		end)
	else
		task.defer(function()
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end

	if plot then
		refreshPlotDisplayState(player, plot)
		BaseService.UpdatePackMilestone(plot, DataService.GetTotalPacksOpened(player))
		spawnPackForPlot(plot)
	end

	task.defer(function()
		if player.Parent then
			UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			sendHint(player, plot and "Equip your pitchfork and crack the pack on your red pad. Hold E on green slots to move players in or out." or "This server's bases are full right now.")
		end
	end)

	return data
end

Players.PlayerAdded:Connect(handlePlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(handlePlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	initializedPlayers[player] = nil
	swingCooldowns[player] = nil
	DataService.SavePlayer(player)
	DataService.UnloadPlayer(player)
	BaseService.ReleasePlot(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
	task.wait(2)
end)

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local passiveIncome = getDisplayedIncomePerSecond(player)
			if passiveIncome > 0 then
				EconomyService.AddCoins(player, passiveIncome)
				UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			end
		end
	end
end)

GetPlayerDataFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return nil
	end

	return {
		coins = data.coins,
		gems = data.gems or 0,
		rebirthTier = data.rebirthTier or 0,
		rebirthTokens = data.rebirthTokens or 0,
		fanMultiplier = type(RebirthService.GetFanMultiplier) == "function"
			and RebirthService.GetFanMultiplier(data.rebirthTier or 0)
			or 1,
		totalCardsOpened = data.totalCardsOpened or 0,
		totalPacksOpened = DataService.GetTotalPacksOpened(player),
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
		canClaimFreePack = EconomyService.CanClaimFreePack(player),
		freePackRemaining = EconomyService.GetFreePackRemaining(player),
		canClaimDailyReward = EconomyService.CanClaimDailyReward(player),
		dailyRewardRemaining = math.max(
			0,
			Constants.DailyRewardCooldown - (os.time() - (data.lastDailyReward or 0))
		),
		inventoryCounts = data.inventory,
	}
end

GetInventoryFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return {}
	end

	local inventoryById = {}
	for key, amount in pairs(DataService.GetInventory(player)) do
		local cardId = tonumber(key)
		local card = cardId and CardData.ById[cardId]
		if card and amount > 0 then
			local existing = inventoryById[card.id]
			if existing then
				existing.quantity += amount
			else
				inventoryById[card.id] = {
					id = card.id,
					name = card.name,
					nation = card.nation,
					position = card.position,
					rating = card.rating,
					rarity = card.rarity,
					quantity = amount,
					sellValue = Utils.GetSellValue(card.rating),
				}
			end
		end
	end

	local inventory = {}
	for _, cardEntry in pairs(inventoryById) do
		table.insert(inventory, cardEntry)
	end

	table.sort(inventory, function(a, b)
		if a.rating == b.rating then
			return a.name < b.name
		end
		return a.rating > b.rating
	end)

	return inventory
end

PlaceInventoryCardInSlotFn.OnServerInvoke = function(player, slotIndex, cardId)
	if type(slotIndex) ~= "number" or type(cardId) ~= "number" then
		return { success = false, error = "Choose a valid player and display slot." }
	end

	local plot = BaseService.GetPlot(player)
	if not plot or plot.ownerPlayer ~= player then
		return { success = false, error = "You do not have an active stadium yet." }
	end

	local slot = getDisplaySlotByIndex(plot, slotIndex)
	if not slot then
		return { success = false, error = "That display slot does not exist." }
	end

	local ok, cardOrError = addInventoryCardToDisplay(player, plot, slot, cardId)
	if not ok then
		return { success = false, error = cardOrError }
	end

	sendHint(player, cardOrError.name .. " added to display slot " .. tostring(slotIndex) .. " for +" .. tostring(getCardIncome(player, cardOrError)) .. "/s.")

	return {
		success = true,
		card = cardOrError,
		slotIndex = slotIndex,
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	}
end

OpenPackFn.OnServerInvoke = function(player, packId)
	return {
		success = false,
		error = "Use your pitchfork on the pack at your red pad.",
	}
end

SellCardFn.OnServerInvoke = function(player, cardId)
	if type(cardId) ~= "number" then
		return { success = false, error = "Invalid card" }
	end

	local card = CardData.ById[cardId]
	if not card then
		return { success = false, error = "Unknown card" }
	end

	if not DataService.RemoveCard(player, cardId) then
		return { success = false, error = "Card not owned" }
	end

	local earned = Utils.GetSellValue(card.rating)
	EconomyService.AddCoins(player, earned)
	refreshPlotDisplayState(player, BaseService.GetPlot(player))
	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))

	return {
		success = true,
		coinsEarned = earned,
		newCoins = DataService.GetCoins(player),
	}
end

SellAllCardsFn.OnServerInvoke = function(player, cardIds)
	if type(cardIds) ~= "table" then
		return { success = false, error = "Invalid payload" }
	end

	local total = 0
	for _, cardId in ipairs(cardIds) do
		if type(cardId) == "number" then
			local card = CardData.ById[cardId]
			if card and DataService.RemoveCard(player, cardId) then
				total += Utils.GetSellValue(card.rating)
			end
		end
	end

	if total > 0 then
		EconomyService.AddCoins(player, total)
		UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
	end
	refreshPlotDisplayState(player, BaseService.GetPlot(player))

	return {
		success = true,
		coinsEarned = total,
		newCoins = DataService.GetCoins(player),
	}
end

local function buildUpgradePayload(player)
	local payload = {
		coins = DataService.GetCoins(player),
		upgrades = {},
	}

	for _, key in ipairs(Constants.UpgradeKeys) do
		local spec = Constants.Upgrades[key]
		local level = getUpgradeLevel(player, key)
		local nextCost = getUpgradeCost(key, level)
		local entry = {
			key = key,
			displayName = spec.displayName,
			description = spec.description,
			level = level,
			maxLevel = spec.maxLevel,
			nextCost = nextCost,
			maxed = level >= spec.maxLevel,
		}

		if key == "PitchforkDamage" then
			entry.currentValue = computePitchforkDamage(level)
			entry.nextValue = computePitchforkDamage(level + 1)
			entry.valueSuffix = " dmg/swing"
		elseif key == "PackSpawnRate" then
			entry.currentValue = computeSpawnDelay(level)
			entry.nextValue = computeSpawnDelay(level + 1)
			entry.valueSuffix = "s respawn"
		elseif key == "PadLuck" then
			entry.currentValue = computeLuckShift(level)
			entry.nextValue = computeLuckShift(level + 1)
			entry.valueSuffix = " luck shift"
		elseif key == "MoveSpeed" then
			entry.currentValue = computeWalkSpeed(level)
			entry.nextValue = computeWalkSpeed(level + 1)
			entry.valueSuffix = " studs/s"
		end

		table.insert(payload.upgrades, entry)
	end

	return payload
end

GetUpgradesFn.OnServerInvoke = function(player)
	return buildUpgradePayload(player)
end

PurchaseUpgradeFn.OnServerInvoke = function(player, upgradeKey)
	if type(upgradeKey) ~= "string" or not Constants.Upgrades[upgradeKey] then
		return { success = false, error = "Unknown upgrade." }
	end

	local level = getUpgradeLevel(player, upgradeKey)
	local spec = Constants.Upgrades[upgradeKey]
	if level >= spec.maxLevel then
		return { success = false, error = "Upgrade already maxed." }
	end

	local cost = getUpgradeCost(upgradeKey, level)
	if not cost then
		return { success = false, error = "Upgrade already maxed." }
	end

	local ok, err = DataService.SpendCoins(player, cost)
	if not ok then
		return { success = false, error = err or "Not enough Fans." }
	end

	local data = DataService.GetData(player)
	data.upgrades = data.upgrades or {}
	data.upgrades[upgradeKey] = level + 1
	DataService.MarkDirty(player)

	if upgradeKey == "MoveSpeed" then
		applyMovementUpgrade(player)
	end

	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))

	local payload = buildUpgradePayload(player)
	payload.success = true
	payload.purchasedKey = upgradeKey
	payload.coinsSpent = cost
	return payload
end

-- ── Free Pack claim ───────────────────────────────────────────────────────────
-- Player taps "CLAIM FREE PACK" in the Shop panel.  We stamp the cooldown here
-- (EconomyService.ClaimFreePack), open a Gold Pack with ignoreCost so no Fans
-- are charged, auto-store the card, then fire PackOpenedEvent so the card reveal
-- screen appears exactly like a pitchfork crack.
ClaimFreePackFn.OnServerInvoke = function(player)
	local ok, err = EconomyService.ClaimFreePack(player)
	if not ok then
		return { success = false, error = err or "Free pack not ready." }
	end

	local packOk, result = PackService.OpenPack(player, "GoldPack", { ignoreCost = true })
	if not packOk then
		-- Rare: pack logic failed after cooldown was already stamped.  Let it
		-- ride — player can retry on next cooldown.
		return { success = false, error = result and result.error or "Pack failed. Try again." }
	end

	local pulledCard = result.card or (result.cards and result.cards[1]) or nil
	local plot = BaseService.GetPlot(player)
	local storageResult

	if plot then
		storageResult = autoStorePulledCard(player, plot, pulledCard)
	else
		if pulledCard then
			DataService.AddCard(player, pulledCard.id)
		end
		storageResult = { storedInInventory = true, slotIndex = nil }
	end

	local passiveIncome = getCardIncome(player, pulledCard)
	if plot then
		BaseService.UpdatePackMilestone(plot, DataService.GetTotalPacksOpened(player))
	end

	PackOpenedEvent:FireClient(player, {
		success = true,
		packId = result.packId,
		packName = result.packName,
		newCoins = result.newCoins,
		card = pulledCard,
		storedInInventory = storageResult.storedInInventory,
		slotIndex = storageResult.slotIndex,
		slotWorldPosition = storageResult.slotWorldPosition,
		packWorldPosition = plot and (plot.packPad.Position + Vector3.new(0, 6, 0)) or nil,
		coinsPerSecond = passiveIncome,
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	})

	return {
		success = true,
		freePackRemaining = Constants.FreePackCooldown,
	}
end

-- ── Daily Reward claim ────────────────────────────────────────────────────────
-- Normally granted automatically on login, but players can also claim through
-- the Shop if 24 h have elapsed while they're still in the session.
ClaimDailyRewardFn.OnServerInvoke = function(player)
	local granted = EconomyService.TryGrantDailyReward(player)
	if not granted then
		local data = DataService.GetData(player)
		local remaining = data
				and math.max(0, Constants.DailyRewardCooldown - (os.time() - (data.lastDailyReward or 0)))
			or Constants.DailyRewardCooldown
		return {
			success = false,
			error = "Daily reward not ready yet.",
			dailyRewardRemaining = remaining,
		}
	end

	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))

	return {
		success = true,
		coinsAwarded = Constants.DailyRewardCoins,
		newCoins = DataService.GetCoins(player),
		dailyRewardRemaining = Constants.DailyRewardCooldown,
	}
end

GetRebirthStatusFn.OnServerInvoke = function(player)
	return RebirthService.GetStatus(player)
end

RequestRebirthFn.OnServerInvoke = function(player)
	local ok, result = RebirthService.PerformRebirth(player)
	if not ok then
		return {
			success = false,
			status = result,
			error = result and result.reason or "You cannot rebirth yet.",
		}
	end

	local plot = BaseService.GetPlot(player)
	if plot then
		BaseService.ClearPlotDisplays(plot)
		BaseService.UpdatePackMilestone(plot, DataService.GetTotalPacksOpened(player))
		refreshPlotDisplayState(player, plot)
	end

	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
	sendHint(player, "Rebirth complete! Your stadium reset, but your permanent fan multiplier increased.")

	return {
		success = true,
		status = result,
		coins = DataService.GetCoins(player),
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	}
end

print("[UnboxAFootballer] Pack systems ready")

]])

makeLocal('BaseUI', sps, [[return
]])

makeLocal('CollectionUI', sps, [[return
]])

makeLocal('HUDClient', sps, [[return
]])

makeLocal('InventoryUI', sps, [[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetInventoryFn = Remotes:WaitForChild("GetInventory")
local SellCardFn = Remotes:WaitForChild("SellCard")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")
local PromptPackShopEvent = Remotes:WaitForChild("PromptPackShop")
local OpenSlotPickerEvent = Remotes:WaitForChild("OpenSlotPicker")
local PlaceInventoryCardInSlotFn = Remotes:WaitForChild("PlaceInventoryCardInSlot")

local function make(className, props, parent)
	props = props or {}
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local existingGui = playerGui:FindFirstChild("InventoryUI")
if existingGui then
	existingGui:Destroy()
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local screenGui = make("ScreenGui", {
	Name = "InventoryUI",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

local toggle = make("TextButton", {
	Visible = false,
	AnchorPoint = Vector2.new(0, 1),
	Size = UDim2.fromOffset(176, 38),
	Position = UDim2.new(0, 24, 1, -116),
	BackgroundColor3 = Constants.UI.Panel,
	Text = "Inventory",
	TextColor3 = Constants.UI.Text,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
}, screenGui)
addCorner(toggle, 12)

local panel = make("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.92, 0, 0.85, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Constants.UI.Panel,
}, screenGui)
addCorner(panel, 18)

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(320, 360)
panelSize.MaxSize = Vector2.new(620, 500)
panelSize.Parent = panel

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -72, 0, 36),
	Position = UDim2.new(0, 12, 0, 10),
	Text = "Club Inventory",
	TextColor3 = Constants.UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(36, 36),
	Position = UDim2.new(1, -12, 0, 10),
	BackgroundColor3 = Constants.UI.PanelAlt,
	Text = "X",
	TextColor3 = Constants.UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, panel)
addCorner(closeButton, 10)

local statusLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 24),
	Position = UDim2.new(0, 12, 0, 48),
	Text = "",
	TextColor3 = Constants.UI.Muted,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold,
}, panel)

local scrolling = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -24, 1, -94),
	Position = UDim2.new(0, 12, 0, 82),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, panel)

local layout = make("UIGridLayout", {
	CellSize = UDim2.fromOffset(126, 190),
	CellPadding = UDim2.fromOffset(12, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scrolling)

local currentMode = "inventory"
local targetSlotIndex = nil
local isSubmitting = false
local statusOverride = nil
local refreshToken = 0
local refreshInventory

local function clearEntries()
	for _, child in ipairs(scrolling:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function closePanel()
	panel.Visible = false
	currentMode = "inventory"
	targetSlotIndex = nil
	statusOverride = nil
	statusLabel.Text = ""
end

local function openInventoryPanel()
	currentMode = "inventory"
	targetSlotIndex = nil
	statusOverride = nil
	panel.Visible = true
	refreshInventory()
end

local function mergeInventoryRows(inventory)
	local byId = {}
	local merged = {}

	for _, card in ipairs(inventory or {}) do
		local cardId = tonumber(card.id)
		if cardId then
			local existing = byId[cardId]
			if existing then
				existing.quantity += tonumber(card.quantity) or 0
			else
				local entry = {
					id = cardId,
					name = card.name,
					nation = card.nation,
					position = card.position,
					rating = card.rating,
					rarity = card.rarity,
					quantity = tonumber(card.quantity) or 1,
					sellValue = card.sellValue,
				}
				byId[cardId] = entry
				table.insert(merged, entry)
			end
		end
	end

	table.sort(merged, function(a, b)
		if a.rating == b.rating then
			return a.name < b.name
		end
		return a.rating > b.rating
	end)

	return merged
end

function refreshInventory()
	refreshToken += 1
	local myToken = refreshToken

	local inventory = mergeInventoryRows(GetInventoryFn:InvokeServer())

	-- If another refresh started while we were yielded on InvokeServer, bail so we
	-- don't append a stale render on top of (or before) the newer one.
	if myToken ~= refreshToken then
		return
	end

	clearEntries()
	local isSlotPicker = currentMode == "slotPicker"

	if isSlotPicker then
		title.Text = "Choose Player"
		statusLabel.Text = "Pick a stored player for display slot " .. tostring(targetSlotIndex) .. "."
	else
		title.Text = "Club Inventory"
		statusLabel.Text = #inventory > 0 and "Stored players earn fans when placed on green display slots." or "Stored players will appear here when your displays are full."
	end
	if statusOverride then
		statusLabel.Text = statusOverride
		statusOverride = nil
	end

	if #inventory == 0 then
		local emptyState = make("Frame", {
			BackgroundColor3 = Constants.UI.PanelAlt,
		}, scrolling)
		addCorner(emptyState, 14)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -16, 1, -16),
			Position = UDim2.fromOffset(8, 8),
			Text = "No stored players yet",
			TextColor3 = Constants.UI.Muted,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
		}, emptyState)
	end

	for index, card in ipairs(inventory) do
		local style = Utils.GetRarityStyle(card.rarity)
		local rarityColor = style.primary
		local secondaryColor = style.secondary or rarityColor
		local darkColor = style.dark or Constants.UI.PanelAlt
		local trimColor = style.trim or rarityColor
		local textColor = style.text or Constants.UI.Text
		local incomePerSecond = Utils.GetPassiveIncome(Utils.GetCardIncomeRating(card))

		local tile = make("Frame", {
			LayoutOrder = index,
			BackgroundColor3 = darkColor,
		}, scrolling)
		addCorner(tile, 14)
		addStroke(tile, trimColor, 1.5, 0.35)

		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.08)),
				ColorSequenceKeypoint.new(0.52, secondaryColor),
				ColorSequenceKeypoint.new(1, darkColor),
			}),
			Rotation = 145,
		}, tile)

		local rarityLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(9, 8),
			Size = UDim2.new(1, -18, 0, 18),
			Text = string.upper(style.label or card.rarity or "CARD"),
			TextColor3 = textColor,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBlack,
		}, tile)
		make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 10 }, rarityLabel)
		addStroke(rarityLabel, Color3.fromRGB(0, 0, 0), 1, 0.38)

		local topRow = make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 32),
			Size = UDim2.new(1, -20, 0, 28),
		}, tile)

		local positionBadge = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(6, 8, 13),
			BackgroundTransparency = 0.08,
			Size = UDim2.fromOffset(38, 24),
			BorderSizePixel = 0,
		}, topRow)
		addCorner(positionBadge, 8)
		addStroke(positionBadge, trimColor, 1, 0.35)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = card.position or "--",
			TextColor3 = textColor,
			TextScaled = false,
			TextSize = 13,
			Font = Enum.Font.GothamBlack,
		}, positionBadge)

		local quantityBadge = make("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(40, 24),
			BackgroundColor3 = Color3.fromRGB(7, 9, 14),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
		}, topRow)
		addCorner(quantityBadge, 8)
		addStroke(quantityBadge, trimColor, 1, 0.45)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "x" .. tostring(card.quantity),
			TextColor3 = textColor,
			TextScaled = false,
			TextSize = 13,
			Font = Enum.Font.GothamBlack,
		}, quantityBadge)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.39, 0),
			Size = UDim2.new(0.84, 0, 0.2, 0),
			Text = card.name,
			TextColor3 = textColor,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.62, 0),
			Size = UDim2.new(0.84, 0, 0.09, 0),
			Text = card.nation or "Unknown",
			TextColor3 = Constants.UI.Muted,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.72, 0),
			Size = UDim2.new(0.84, 0, 0.07, 0),
			Text = "+" .. tostring(incomePerSecond) .. " fans/s",
			TextColor3 = rarityColor,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, tile)

		local actionButton
		if isSlotPicker then
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(0.82, 0, 0, 30),
				BackgroundColor3 = Color3.fromRGB(74, 185, 98),
				Text = card.quantity > 1 and ("Place x" .. tostring(card.quantity)) or "Place",
				TextColor3 = Constants.UI.Text,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
			}, tile)
		else
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(0.82, 0, 0, 30),
				BackgroundColor3 = Constants.UI.Danger,
				Text = "Sell 1 +" .. tostring(card.sellValue),
				TextColor3 = Constants.UI.Text,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
			}, tile)
		end
		addCorner(actionButton, 10)

		actionButton.MouseButton1Click:Connect(function()
			if isSubmitting then
				return
			end

			isSubmitting = true

			if isSlotPicker then
				actionButton.Text = "Placing..."

				local result = PlaceInventoryCardInSlotFn:InvokeServer(targetSlotIndex, card.id)
				isSubmitting = false

				if result and result.success then
					closePanel()
					return
				end

				statusOverride = (result and result.error) or "Could not place that player."
				refreshInventory()
				return
			end

			actionButton.Text = "Selling..."
			local result = SellCardFn:InvokeServer(card.id)
			isSubmitting = false

			if result and result.success then
				statusOverride = card.name .. " sold for +" .. tostring(result.coinsEarned or card.sellValue) .. " Fans."
				refreshInventory()
				return
			end

			statusOverride = (result and result.error) or "Could not sell that player."
			refreshInventory()
		end)
	end

	task.defer(function()
		scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

toggle.MouseButton1Click:Connect(function()
	if panel.Visible and currentMode == "inventory" then
		closePanel()
	else
		openInventoryPanel()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)

toggleEvent.Event:Connect(function()
	if panel.Visible and currentMode == "inventory" then
		closePanel()
	else
		openInventoryPanel()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		closePanel()
	end
end)

local function refreshIfVisible()
	if panel.Visible then
		refreshInventory()
	end
end

PackOpenedEvent.OnClientEvent:Connect(refreshIfVisible)
PromptPackShopEvent.OnClientEvent:Connect(refreshIfVisible)

OpenSlotPickerEvent.OnClientEvent:Connect(function(payload)
	currentMode = "slotPicker"
	targetSlotIndex = payload and payload.slotIndex
	statusOverride = nil
	panel.Visible = true
	refreshInventory()
end)
]])

makeLocal('MarketUI', sps, [[return
]])

makeLocal('PackOpeningUI', sps, [[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, child in ipairs(script.Parent:GetChildren()) do
	if child:IsA("LocalScript") and child ~= script and child.Name == script.Name then
		child.Disabled = true
	end
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local UpdateCoinsEvent = Remotes:WaitForChild("UpdateCoins")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")
local PackOpenFailedEvent = Remotes:WaitForChild("PackOpenFailed")
local PromptPackShopEvent = Remotes:WaitForChild("PromptPackShop")

local UI = Constants.UI

local function make(className, props, parent)
	props = props or {}
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local existingGui = playerGui:FindFirstChild("PackOpeningUI")
if existingGui then
	existingGui:Destroy()
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local screenGui = make("ScreenGui", {
	Name = "PackOpeningUI",
	ResetOnSpawn = false,
	DisplayOrder = 8,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local watchedPlots = {}

local function getOwnedPlot()
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	if not basesFolder then
		return nil
	end

	for _, child in ipairs(basesFolder:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == player.UserId then
			return child
		end
	end

	return nil
end

local function snapCameraToOwnedBase(character)
	local camera = Workspace.CurrentCamera
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local plotModel = getOwnedPlot()
	local packPad = plotModel and plotModel:FindFirstChild("PackPad")
	if not camera or not rootPart or not humanoid or not packPad then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid

	local lookTarget = packPad.Position + Vector3.new(0, 3, 0)
	local forward = (lookTarget - rootPart.Position)
	if forward.Magnitude < 0.1 then
		return
	end
	forward = forward.Unit

	local cameraPosition = rootPart.Position - (forward * 12) + Vector3.new(0, 5, 0)
	camera.CFrame = CFrame.lookAt(cameraPosition, lookTarget)
end

local function applyPlotPadVisibility(plotModel)
	if not plotModel or not plotModel.Parent then
		return
	end

	local packPad = plotModel:FindFirstChild("PackPad")
	local padGui = packPad and packPad:FindFirstChild("PadGui")
	if padGui and padGui:IsA("BillboardGui") then
		padGui.Enabled = plotModel:GetAttribute("OwnerUserId") == player.UserId
	end
end

local function watchPlot(plotModel)
	if watchedPlots[plotModel] or not plotModel:IsA("Model") then
		return
	end

	watchedPlots[plotModel] = true
	applyPlotPadVisibility(plotModel)

	plotModel:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		applyPlotPadVisibility(plotModel)
	end)

	local packPad = plotModel:FindFirstChild("PackPad")
	if packPad then
		packPad.ChildAdded:Connect(function(child)
			if child.Name == "PadGui" then
				applyPlotPadVisibility(plotModel)
			end
		end)
	end
end

task.spawn(function()
	local basesFolder = Workspace:WaitForChild("PlayerBases", 10)
	if not basesFolder then
		return
	end

	for _, child in ipairs(basesFolder:GetChildren()) do
		watchPlot(child)
	end

	basesFolder.ChildAdded:Connect(function(child)
		watchPlot(child)
	end)
end)

local sidebar = make("Frame", {
	Name = "Sidebar",
	AnchorPoint = Vector2.new(0, 1),
	Size = UDim2.fromOffset(190, 276),
	Position = UDim2.new(0, 20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(5, 8, 15),
	BackgroundTransparency = 0.18,
}, screenGui)
addCorner(sidebar, 16)
addStroke(sidebar, UI.Gold, 1.5, 0.48)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 22, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 18)),
	}),
	Rotation = 110,
}, sidebar)

local sidebarPadding = make("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, sidebar)
_ = sidebarPadding

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local walletDock = make("Frame", {
	Name = "WalletDock",
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(232, 98),
	Position = UDim2.new(1, -20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.08,
}, screenGui)
addCorner(walletDock, 16)
addStroke(walletDock, UI.Gold, 1.5, 0.68)

local walletPadding = make("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, walletDock)
_ = walletPadding

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, walletDock)

local function drawWalletGemIcon(parent, accentColor)
	local gem = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = accentColor,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(13, 13),
		Rotation = 45,
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 2,
	}, parent)
	addCorner(gem, 3)
	addStroke(gem, Color3.fromRGB(169, 239, 255), 1, 0.05)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(176, 246, 255)),
			ColorSequenceKeypoint.new(0.5, accentColor),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 132, 219)),
		}),
		Rotation = 35,
	}, gem)

	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(221, 255, 255),
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 8),
		Rotation = 45,
		Size = UDim2.fromOffset(7, 3),
		ZIndex = 3,
	}, parent)
end

local function createWalletRow(parent, order, labelText, iconText, iconColor)
	local row = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = UI.Panel,
	}, parent)
	addCorner(row, 10)
	addStroke(row, iconColor, 1.5, 0.7)

	local icon = make("Frame", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 8, 0.5, -13),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.72),
	}, row)
	addCorner(icon, 9)
	if iconText == "Gem" then
		drawWalletGemIcon(icon, iconColor)
	else
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = iconText,
			TextColor3 = iconColor,
			TextScaled = false,
			TextSize = 17,
			Font = Enum.Font.GothamBlack,
		}, icon)
	end

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 42, 0, 3),
		Size = UDim2.new(1, -82, 0, 12),
		Text = labelText,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local valueLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 42, 0, 14),
		Size = UDim2.new(1, -82, 0, 22),
		Text = "0",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local plusButton = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(32, 128, 55),
		Text = "+",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
	}, row)
	addCorner(plusButton, 8)

	return valueLabel, plusButton
end

local fansLabel, addFansButton = createWalletRow(walletDock, 1, "Fans", "F", UI.Gold)
local gemsLabel, addGemsButton = createWalletRow(walletDock, 2, "Gems", "Gem", Color3.fromRGB(69, 207, 255))

local function makeIconLine(parent, position, size, color, rotation)
	return make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Position = position,
		Rotation = rotation or 0,
		Size = size,
	}, parent)
end

local function drawInventoryIcon(parent, accentColor)
	for index, props in ipairs({
		{ x = 17, y = 22, rot = -12, alpha = 0.25 },
		{ x = 22, y = 20, rot = 5, alpha = 0.08 },
		{ x = 26, y = 21, rot = 12, alpha = 0 },
	}) do
		local card = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(255, 255, 255), props.alpha),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(props.x, props.y),
			Rotation = props.rot,
			Size = UDim2.fromOffset(15, 22),
			ZIndex = 2 + index,
		}, parent)
		addCorner(card, 3)
		addStroke(card, accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.15), 1, 0.18)

		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(5, 14, 28),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.58, 0.52),
			Rotation = 45,
			Size = UDim2.fromOffset(5, 5),
			ZIndex = 4 + index,
		}, card)
	end
end

local function drawUpgradeIcon(parent, accentColor)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(4, -2),
		Size = UDim2.fromOffset(34, 42),
		Text = "↑",
		TextColor3 = accentColor,
		TextScaled = false,
		TextSize = 34,
		Font = Enum.Font.GothamBlack,
		ZIndex = 3,
	}, parent)
end

local function drawQuestIcon(parent, accentColor)
	for _, diameter in ipairs({ 28, 18, 8 }) do
		local ring = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(19, 23),
			Size = UDim2.fromOffset(diameter, diameter),
			ZIndex = 2,
		}, parent)
		addCorner(ring, diameter / 2)
		addStroke(ring, accentColor, 2, diameter == 8 and 0 or 0.15)
	end

	makeIconLine(parent, UDim2.fromOffset(29, 13), UDim2.fromOffset(4, 20), accentColor, 42)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 2),
		Size = UDim2.fromOffset(18, 18),
		Text = "✦",
		TextColor3 = accentColor,
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBlack,
		ZIndex = 4,
	}, parent)
end

local function drawShopIcon(parent, accentColor)
	makeIconLine(parent, UDim2.fromOffset(10, 11), UDim2.fromOffset(14, 4), accentColor, 26)
	makeIconLine(parent, UDim2.fromOffset(21, 18), UDim2.fromOffset(24, 5), accentColor)
	makeIconLine(parent, UDim2.fromOffset(20, 28), UDim2.fromOffset(23, 5), accentColor)
	makeIconLine(parent, UDim2.fromOffset(9, 23), UDim2.fromOffset(5, 15), accentColor)
	makeIconLine(parent, UDim2.fromOffset(32, 23), UDim2.fromOffset(5, 15), accentColor)

	make("Frame", {
		BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(0, 0, 0), 0.6),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(11, 19),
		Size = UDim2.fromOffset(20, 8),
		ZIndex = 2,
	}, parent)

	for _, x in ipairs({ 14, 28 }) do
		local wheel = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(x, 35),
			Size = UDim2.fromOffset(7, 7),
			ZIndex = 3,
		}, parent)
		addCorner(wheel, 4)
	end
end

local function drawMenuIcon(parent, iconKind, accentColor)
	if iconKind == "inventory" then
		drawInventoryIcon(parent, accentColor)
	elseif iconKind == "upgrades" then
		drawUpgradeIcon(parent, accentColor)
	elseif iconKind == "quests" then
		drawQuestIcon(parent, accentColor)
	elseif iconKind == "shop" then
		drawShopIcon(parent, accentColor)
	end
end

local function createMenuButton(order, text, iconKind, accentColor)
	local baseColor = accentColor:Lerp(Color3.fromRGB(5, 8, 16), 0.82)
	local hoverColor = accentColor:Lerp(Color3.fromRGB(8, 12, 22), 0.68)
	local labelColor = text == "Inventory" and UI.Text or accentColor

	local frame = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = baseColor,
		BackgroundTransparency = 0.02,
	}, sidebar)
	addCorner(frame, 12)
	local frameStroke = addStroke(frame, accentColor, 1.5, 0.38)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 24, 42)),
			ColorSequenceKeypoint.new(1, baseColor),
		}),
		Rotation = 0,
	}, frame)

	local iconBg = make("Frame", {
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(0, 7, 0.5, -21),
		BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(0, 0, 0), 0.52),
		ClipsDescendants = false,
	}, frame)
	addCorner(iconBg, 11)
	addStroke(iconBg, accentColor, 1, 0.72)
	drawMenuIcon(iconBg, iconKind, accentColor)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 62, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Text = string.upper(text),
		TextColor3 = labelColor,
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)

	local button = make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		AutoButtonColor = false,
	}, frame)
	addCorner(button, 12)

	button.MouseEnter:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.1), {
			BackgroundColor3 = hoverColor,
		}):Play()
		TweenService:Create(frameStroke, TweenInfo.new(0.1), {
			Transparency = 0.16,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.1), {
			BackgroundColor3 = baseColor,
		}):Play()
		TweenService:Create(frameStroke, TweenInfo.new(0.1), {
			Transparency = 0.38,
		}):Play()
	end)

	return button
end

local inventoryButton = createMenuButton(1, "Inventory", "inventory", Color3.fromRGB(78, 170, 255))
local upgradesButton  = createMenuButton(2, "Upgrades",  "upgrades",  UI.Gold)
local questsButton    = createMenuButton(3, "Quests",    "quests",    Color3.fromRGB(205, 88, 255))
local shopButton      = createMenuButton(4, "Shop",      "shop",      Color3.fromRGB(85, 226, 112))

-- ── Sidebar collapse tab ──────────────────────────────────────────────────────
local SIDEBAR_OPEN_POS = UDim2.new(0, 20, 1, -20)
local SIDEBAR_CLOSED_POS = UDim2.new(0, -208, 1, -20)
local TAB_OPEN_POS = UDim2.new(0, 218, 1, -158)
local TAB_CLOSED_POS = UDim2.new(0, 10, 1, -158)
local SLIDE_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local sidebarIsOpen = true

local collapseTab = make("TextButton", {
	Name = "SidebarToggle",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = TAB_OPEN_POS,
	Size = UDim2.fromOffset(34, 48),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.08,
	Text = "<",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = false,
	ZIndex = 10,
}, screenGui)
addCorner(collapseTab, 12)
addStroke(collapseTab, UI.Gold, 1.5, 0.68)

collapseTab.MouseEnter:Connect(function()
	TweenService:Create(collapseTab, TweenInfo.new(0.1), {
		BackgroundColor3 = UI.Gold:Lerp(Color3.fromRGB(8, 12, 22), 0.85),
	}):Play()
end)
collapseTab.MouseLeave:Connect(function()
	TweenService:Create(collapseTab, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	}):Play()
end)

local function setSidebarOpen(open)
	sidebarIsOpen = open
	collapseTab.Text = open and "<" or ">"
	TweenService:Create(sidebar, SLIDE_INFO, {
		Position = open and SIDEBAR_OPEN_POS or SIDEBAR_CLOSED_POS,
	}):Play()
	TweenService:Create(collapseTab, SLIDE_INFO, {
		Position = open and TAB_OPEN_POS or TAB_CLOSED_POS,
	}):Play()
end

collapseTab.MouseButton1Click:Connect(function()
	setSidebarOpen(not sidebarIsOpen)
end)

local toastHolder = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -20, 0, 92),
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(320, 420),
}, screenGui)

make("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 10),
}, toastHolder)

local function setCoinsDisplay(coins)
	fansLabel.Text = Utils.FormatNumber(coins or 0)
end

local function setGemsDisplay(gems)
	gemsLabel.Text = Utils.FormatNumber(gems or 0)
end

local function showToast(text, accent)
	local toast = make("Frame", {
		BackgroundColor3 = UI.PanelAlt,
		Size = UDim2.new(1, 0, 0, 58),
	}, toastHolder)
	addCorner(toast, 16)
	addStroke(toast, accent, 2, 0.25)

	make("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 6, 1, -12),
		Position = UDim2.new(0, 8, 0, 6),
	}, toast)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Text = text,
		TextColor3 = UI.Text,
		TextWrapped = true,
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, toast)

	toast.BackgroundTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.18), {
		BackgroundTransparency = 0,
	}):Play()

	task.delay(3.2, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.2), {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
			}):Play()
			task.wait(0.22)
			if toast.Parent then
				toast:Destroy()
			end
		end
	end)
end

local function fireGuiToggle(guiName)
	local targetGui = playerGui:FindFirstChild(guiName)
	if not targetGui then
		targetGui = playerGui:WaitForChild(guiName, 3)
	end

	local toggleEvent = targetGui and targetGui:FindFirstChild("ToggleEvent")
	if toggleEvent then
		toggleEvent:Fire()
		return true
	end

	return false
end

local function refreshStatus()
	local data = GetPlayerDataFn:InvokeServer()
	if not data then
		return
	end

	setCoinsDisplay(data.coins)
	setGemsDisplay(data.gems)
end

inventoryButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("InventoryUI") then
		showToast("Inventory UI is still loading. Try again in a second.", UI.Gold)
	end
end)

upgradesButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("UpgradesUI") then
		showToast("Upgrades UI is still loading. Try again in a second.", UI.Gold)
	end
end)

questsButton.MouseButton1Click:Connect(function()
	showToast("Quests are coming soon. This button is ready for the next system.", Color3.fromRGB(110, 130, 255))
end)

shopButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("ShopUI") then
		showToast("Shop is still loading. Try again in a second.", Color3.fromRGB(74, 185, 98))
	end
end)

addFansButton.MouseButton1Click:Connect(function()
	showToast("Fans come from displayed players. Future boosts will help you grow faster.", UI.Gold)
end)

addGemsButton.MouseButton1Click:Connect(function()
	showToast("Gems are planned for premium packs and cosmetics later.", Color3.fromRGB(69, 207, 255))
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins)
	setCoinsDisplay(coins)
end)

local function getGuiCenterTarget(guiObject, fallback)
	if not guiObject or not guiObject.Parent then
		return fallback
	end

	local size = guiObject.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return fallback
	end

	local position = guiObject.AbsolutePosition
	return UDim2.fromOffset(position.X + (size.X / 2), position.Y + (size.Y / 2))
end

local function getWorldScreenTarget(worldPosition, fallback)
	if typeof(worldPosition) ~= "Vector3" then
		return fallback
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return fallback
	end

	local screenPoint, onScreen = camera:WorldToViewportPoint(worldPosition)
	if not onScreen or screenPoint.Z <= 0 then
		return fallback
	end

	return UDim2.fromOffset(screenPoint.X, screenPoint.Y)
end

-- ── Rare pull screen effect ───────────────────────────────────────────────────
-- Talisman  = tier 1 : coloured flash only
-- Maestro   = tier 2 : flash + rarity burst label + cinematic black bars
-- Immortal / POTY = tier 3 : flash + burst + bars + brief camera shake
-- Returns the number of seconds the caller should wait before showing the card.
local REVEAL_TIERS = {
	["Talisman"]           = 1,
	["Maestro"]            = 2,
	["Immortal"]           = 3,
	["Player of the Year"] = 3,
}

local function playRevealEffect(rarity)
	local tier = REVEAL_TIERS[rarity] or 0
	if tier == 0 then
		return 0
	end

	local style = Utils.GetRarityStyle(rarity)
	local flashColor = style.glow or style.primary

	-- Flash overlay ────────────────────────────────────────────────────────────
	local startTransp = tier == 1 and 0.52 or (tier == 2 and 0.32 or 0.16)
	local flash = make("Frame", {
		AnchorPoint    = Vector2.new(0.5, 0.5),
		Position       = UDim2.fromScale(0.5, 0.5),
		Size           = UDim2.fromScale(1, 1),
		BackgroundColor3 = flashColor,
		BackgroundTransparency = startTransp,
		BorderSizePixel = 0,
		ZIndex         = 188,
	}, screenGui)

	local holdTime = tier == 1 and 0.12 or (tier == 2 and 0.22 or 0.32)
	local fadeTime = tier == 1 and 0.32 or (tier == 2 and 0.52 or 0.68)
	task.delay(holdTime, function()
		if flash.Parent then
			TweenService:Create(flash, TweenInfo.new(fadeTime), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(fadeTime + 0.05, function()
				if flash.Parent then flash:Destroy() end
			end)
		end
	end)

	-- Rarity name burst (tier 2+) ──────────────────────────────────────────────
	if tier >= 2 then
		local burstLabel = make("TextLabel", {
			AnchorPoint    = Vector2.new(0.5, 0.5),
			Position       = UDim2.fromScale(0.5, 0.43),
			Size           = UDim2.fromOffset(480, 72),
			BackgroundTransparency = 1,
			Text           = string.upper(style.label or rarity),
			TextColor3     = style.primary,
			TextTransparency = 0,
			TextScaled     = true,
			Font           = Enum.Font.GothamBlack,
			ZIndex         = 193,
		}, screenGui)
		addStroke(burstLabel, Color3.fromRGB(0, 0, 0), 2, 0.05)

		local burstScale = make("UIScale", { Scale = 0.25 }, burstLabel)
		TweenService:Create(
			burstScale,
			TweenInfo.new(0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
		-- Fade out after the pop-in settles
		TweenService:Create(
			burstLabel,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0.55),
			{ TextTransparency = 1 }
		):Play()
		task.delay(1.05, function()
			if burstLabel.Parent then burstLabel:Destroy() end
		end)
	end

	-- Cinematic black bars (tier 2+) ───────────────────────────────────────────
	local topBar, bottomBar
	if tier >= 2 then
		local BAR_H = 76
		topBar = make("Frame", {
			AnchorPoint    = Vector2.new(0, 0),
			Position       = UDim2.new(0, 0, 0, -BAR_H),   -- starts off-screen top
			Size           = UDim2.new(1, 0, 0, BAR_H),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex         = 186,
		}, screenGui)
		bottomBar = make("Frame", {
			AnchorPoint    = Vector2.new(0, 1),
			Position       = UDim2.new(0, 0, 1, BAR_H),    -- starts off-screen bottom
			Size           = UDim2.new(1, 0, 0, BAR_H),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex         = 186,
		}, screenGui)

		local slideIn = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(topBar,    slideIn, { Position = UDim2.new(0, 0, 0, 0)       }):Play()
		TweenService:Create(bottomBar, slideIn, { Position = UDim2.new(0, 0, 1, -BAR_H)  }):Play()

		-- Slide bars back out once the card reveal is done (~2.4–2.8 s from now)
		local barLifetime = tier == 2 and 2.4 or 2.8
		task.delay(barLifetime, function()
			local slideOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			if topBar.Parent    then TweenService:Create(topBar,    slideOut, { Position = UDim2.new(0, 0, 0, -BAR_H) }):Play() end
			if bottomBar.Parent then TweenService:Create(bottomBar, slideOut, { Position = UDim2.new(0, 0, 1,  BAR_H) }):Play() end
			task.delay(0.40, function()
				if topBar.Parent    then topBar:Destroy()    end
				if bottomBar.Parent then bottomBar:Destroy() end
			end)
		end)
	end

	-- Camera shake (tier 3 only) ───────────────────────────────────────────────
	if tier >= 3 then
		task.spawn(function()
			local camera = Workspace.CurrentCamera
			if not camera then return end
			local prevType = camera.CameraType
			local prevCF   = camera.CFrame
			camera.CameraType = Enum.CameraType.Scriptable
			local frames = 10
			for i = 1, frames do
				task.wait(0.032)
				if not camera or not camera.Parent then break end
				local intensity = 0.28 * (1 - (i - 1) / frames)
				camera.CFrame = prevCF * CFrame.new(
					(math.random() - 0.5) * 2 * intensity,
					(math.random() - 0.5) * 2 * intensity,
					0
				)
			end
			if camera and camera.Parent then
				camera.CFrame   = prevCF
				camera.CameraType = prevType
			end
		end)
	end

	-- Pre-delay before the card panel pops in
	return tier == 1 and 0.12 or (tier == 2 and 0.30 or 0.38)
end

-- ── Compact card reveal ───────────────────────────────────────────────────────
-- Appears near the pack, shows player info briefly, then flies toward the
-- destination slot (or inventory corner).  No full-screen overlay — keeps the
-- world visible while the card pops.  Auto-destroys in ~2 s.
local function showCardReveal(payload)
	local card = payload.card
	if not card then
		return
	end

	-- Play dramatic screen effect for Talisman+ cards; yields briefly so the
	-- flash and bars land before the card panel pops in on top of them.
	local revealPreDelay = playRevealEffect(card.rarity)
	if revealPreDelay > 0 then
		task.wait(revealPreDelay)
	end

	local style = Utils.GetRarityStyle(card.rarity)
	local rarityColor = style.primary
	local secondaryColor = style.secondary or rarityColor
	local darkColor = style.dark or Color3.fromRGB(10, 5, 2)
	local trimColor = style.trim or rarityColor
	local textColor = style.text or Color3.fromRGB(255, 255, 255)
	local income = payload.coinsPerSecond or 0
	local toInventory = payload.storedInInventory == true

	-- ── Card panel (compact: 180 × 256 px) ───────────────────────────
	local CARD_W, CARD_H = 180, 256
	-- Keep the reveal itself predictably visible. The fly-off still targets the
	-- actual 3D slot/inventory destination, which is the bit that matters.
	local revealStart = UDim2.new(0.5, 0, 0.46, 0)

	local cardPanel = make("Frame", {
		Name = "CardReveal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = revealStart,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = darkColor,
		ZIndex = 200,
	}, screenGui)
	addCorner(cardPanel, 16)
	addStroke(cardPanel, trimColor, 3)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12)),
			ColorSequenceKeypoint.new(0.48, secondaryColor),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 158,
	}, cardPanel)

	-- UIScale at 0.05 → 1 for the bounce pop-in
	local cardScale = make("UIScale", { Scale = 0.05 }, cardPanel)

	local rarityBand = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(142, 24),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 202,
	}, cardPanel)
	addCorner(rarityBand, 12)
	addStroke(rarityBand, trimColor, 1.2, 0.28)

	local rarityLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = string.upper(style.label or card.rarity or "CARD"),
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamBlack,
		ZIndex = 203,
	}, rarityBand)
	addStroke(rarityLabel, Color3.fromRGB(6, 3, 1), 1, 0.35)

	local positionBadge = make("Frame", {
		Position = UDim2.fromOffset(14, 47),
		Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 202,
	}, cardPanel)
	addCorner(positionBadge, 8)
	addStroke(positionBadge, trimColor, 1, 0.35)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = card.position or "--",
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamBlack,
		ZIndex = 203,
	}, positionBadge)

	-- Nation (top-right)
	make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 51),
		Size = UDim2.fromOffset(92, 16),
		Text = card.nation or "Unknown",
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 202,
	}, cardPanel)

	-- Divider
	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 78),
		Size = UDim2.new(0.84, 0, 0, 1.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 202,
	}, cardPanel)

	-- Monogram circle
	local monogram = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 86),
		Size = UDim2.fromOffset(84, 84),
		BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(0, 0, 0), 0.55),
		BackgroundTransparency = 0.42,
		ZIndex = 201,
	}, cardPanel)
	addCorner(monogram, 42)
	addStroke(monogram, Color3.fromRGB(255, 255, 255), 1.2, 0.62)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = string.upper(string.sub(card.name, 1, 1)),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.30,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 202,
	}, monogram)

	-- Player name
	local nameLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 170),
		Size = UDim2.new(0.90, 0, 0, 46),
		Text = string.upper(card.name),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 202,
	}, cardPanel)
	make("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 22 }, nameLabel)
	addStroke(nameLabel, Color3.fromRGB(6, 3, 1), 1.2, 0.20)

	-- Destination + income pill (bottom of card)
	local destStr = toInventory
		and ("→ Inventory  ·  +" .. Utils.FormatNumber(income) .. "/s")
		or ("→ Slot " .. tostring(payload.slotIndex) .. "  ·  +" .. Utils.FormatNumber(income) .. "/s")
	local pillBg = toInventory and Color3.fromRGB(40, 50, 80) or Color3.fromRGB(22, 74, 38)
	local pillAccent = toInventory and Color3.fromRGB(110, 130, 210) or Color3.fromRGB(74, 185, 98)

	local pill = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(158, 26),
		BackgroundColor3 = pillBg,
		ZIndex = 202,
	}, cardPanel)
	addCorner(pill, 13)
	addStroke(pill, pillAccent, 1.2, 0.28)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = destStr,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		ZIndex = 203,
	}, pill)

	-- ── Pop-in animation ─────────────────────────────────────────────
	task.wait(0.04)
	TweenService:Create(cardScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	-- ── Fly-off after 1.4 s ──────────────────────────────────────────
	-- Card shrinks and slides toward the destination corner so it feels like
	-- it "drops into" the slot or inventory rather than just disappearing.
	task.delay(1.4, function()
		if not cardPanel.Parent then
			return
		end

		local flyTarget = toInventory
			and getGuiCenterTarget(inventoryButton, UDim2.new(0.16, 0, 0.72, 0))
			or getWorldScreenTarget(payload.slotWorldPosition, UDim2.new(0.5, 0, 0.72, 0))

		TweenService:Create(
			cardPanel,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = flyTarget }
		):Play()
		TweenService:Create(
			cardScale,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 0 }
		):Play()

		task.delay(0.35, function()
			if cardPanel.Parent then
				cardPanel:Destroy()
			end
		end)
	end)
end

PackOpenedEvent.OnClientEvent:Connect(function(payload)
	if not payload or not payload.success then
		return
	end

	setCoinsDisplay(payload.newCoins)

	if payload.card then
		local ok, err = pcall(showCardReveal, payload)
		if not ok then
			warn("[UnboxAFootballer] Card reveal failed:", err)
			local destination = payload.storedInInventory and "Inventory" or ("display slot " .. tostring(payload.slotIndex or "?"))
			showToast(payload.card.name .. " added to " .. destination .. ".", UI.Gold)
		end
	end
end)

PackOpenFailedEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end

	showToast(payload.error or "Pack could not be opened.", UI.Danger)
end)

PromptPackShopEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end

	if payload.coins ~= nil then
		setCoinsDisplay(payload.coins)
	end
end)

task.spawn(function()
	task.wait(1)
	refreshStatus()
end)

local function onCharacterAdded(character)
	task.delay(0.25, function()
		if player.Parent and character.Parent then
			snapCameraToOwnedBase(character)
		end
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
]])

makeLocal('RebirthUI', sps, [[return
]])

makeLocal('ShopUI', sps, [[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local ClaimFreePackFn = Remotes:WaitForChild("ClaimFreePack")
local ClaimDailyRewardFn = Remotes:WaitForChild("ClaimDailyReward")

local UI = Constants.UI

-- ── Helpers ────────────────────────────────────────────────────────────────────

local function make(className, props, parent)
	props = props or {}
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function addStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────

local existingGui = playerGui:FindFirstChild("ShopUI")
if existingGui then
	existingGui:Destroy()
end

local screenGui = make("ScreenGui", {
	Name = "ShopUI",
	ResetOnSpawn = false,
	Enabled = false,
	DisplayOrder = 12,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- BindableEvent so PackOpeningUI can toggle us via fireGuiToggle("ShopUI")
local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

-- ── State ─────────────────────────────────────────────────────────────────────

local isOpen = false
local freePackRemaining = Constants.FreePackCooldown
local dailyRemaining = Constants.DailyRewardCooldown
local canClaimFree = false
local canClaimDaily = false
local claimingFree = false
local claimingDaily = false

-- ── Dark overlay ───────────────────────────────────────────────────────────────

local overlay = make("Frame", {
	Name = "Overlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.42,
	ZIndex = 1,
}, screenGui)

-- Clicking outside the panel closes the Shop
local overlayBtn = make("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	ZIndex = 2,
}, overlay)

-- ── Main panel ────────────────────────────────────────────────────────────────

local PANEL_W, PANEL_H = 430, 380

local panel = make("Frame", {
	Name = "ShopPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(PANEL_W, PANEL_H),
	BackgroundColor3 = UI.Background,
	ZIndex = 10,
}, screenGui)
addCorner(panel, 18)
addStroke(panel, UI.Gold, 1.5, 0.52)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 20, 38)),
		ColorSequenceKeypoint.new(1, UI.Background),
	}),
	Rotation = 130,
}, panel)

-- ── Header ───────────────────────────────────────────────────────────────────

local header = make("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = Color3.fromRGB(10, 14, 27),
	ZIndex = 11,
}, panel)
addCorner(header, 18)

-- Solid rectangle covers only the bottom two rounded corners so the top stays curved
make("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundColor3 = Color3.fromRGB(10, 14, 27),
	BorderSizePixel = 0,
	ZIndex = 11,
}, header)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 0),
	Size = UDim2.new(1, -60, 1, 0),
	Text = "SHOP",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 22,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, header)

local closeBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = UI.Danger,
	Text = "✕",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 12,
}, header)
addCorner(closeBtn, 10)

-- ── Content area ─────────────────────────────────────────────────────────────

local content = make("Frame", {
	Name = "Content",
	Position = UDim2.new(0, 0, 0, 54),
	Size = UDim2.new(1, 0, 1, -54),
	BackgroundTransparency = 1,
	ZIndex = 10,
}, panel)

make("UIPadding", {
	PaddingTop = UDim.new(0, 14),
	PaddingBottom = UDim.new(0, 14),
	PaddingLeft = UDim.new(0, 14),
	PaddingRight = UDim.new(0, 14),
}, content)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

-- Section label
make("TextLabel", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	Text = "FREE REWARDS",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
}, content)

-- ── Reward card helper ────────────────────────────────────────────────────────

local function makeRewardCard(layoutOrder, iconText, iconColor, titleText, subtitleDefault)
	local card = make("Frame", {
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, 82),
		BackgroundColor3 = UI.Panel,
		ZIndex = 11,
	}, content)
	addCorner(card, 14)
	addStroke(card, iconColor, 1.5, 0.72)

	-- Left accent bar
	make("Frame", {
		Size = UDim2.new(0, 4, 1, -16),
		Position = UDim2.new(0, 0, 0, 8),
		BackgroundColor3 = iconColor,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, card)
	addCorner(card:FindFirstChildOfClass("Frame"), 4)

	-- Icon circle
	local iconCircle = make("Frame", {
		Position = UDim2.new(0, 14, 0.5, -22),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.70),
		ZIndex = 12,
	}, card)
	addCorner(iconCircle, 22)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = iconText,
		TextColor3 = iconColor,
		TextScaled = false,
		TextSize = 22,
		Font = Enum.Font.GothamBlack,
		ZIndex = 13,
	}, iconCircle)

	-- Title
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0, 15),
		Size = UDim2.new(1, -220, 0, 22),
		Text = titleText,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 16,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, card)

	-- Subtitle (mutable)
	local subLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0, 38),
		Size = UDim2.new(1, -220, 0, 17),
		Text = subtitleDefault,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, card)

	-- Action button (right side)
	local btn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(136, 38),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.32),
		Text = "CLAIM",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = true,
		ZIndex = 12,
	}, card)
	addCorner(btn, 10)

	return card, subLabel, btn
end

local _, freeSubLabel, freeClaimBtn =
	makeRewardCard(2, "F", Color3.fromRGB(74, 185, 98), "FREE PACK", "One Gold Pack pull  ·  4 h cooldown")

local _, dailySubLabel, dailyClaimBtn =
	makeRewardCard(3, "D", UI.Gold, "DAILY REWARD", "+1,000 Fans  ·  24 h cooldown")

-- Coming-soon footer
local comingSoon = make("TextLabel", {
	LayoutOrder = 4,
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = UI.PanelAlt,
	Text = "Premium packs · Cosmetics · More  —  coming soon",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	ZIndex = 11,
}, content)
addCorner(comingSoon, 10)
addStroke(comingSoon, UI.Muted, 1, 0.90)
_ = comingSoon

-- ── Button state helper ────────────────────────────────────────────────────────

local function updateFreePackBtn()
	if canClaimFree then
		freeClaimBtn.Text = "CLAIM FREE PACK"
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 65)
		freeClaimBtn.Active = true
		freeClaimBtn.AutoButtonColor = true
		freeSubLabel.Text = "One Gold Pack pull  ·  Ready now!"
		freeSubLabel.TextColor3 = Color3.fromRGB(74, 185, 98)
	else
		freeClaimBtn.Text = Utils.FormatCountdown(freePackRemaining)
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		freeClaimBtn.Active = false
		freeClaimBtn.AutoButtonColor = false
		freeSubLabel.Text = "Next free pack in " .. Utils.FormatCountdown(freePackRemaining)
		freeSubLabel.TextColor3 = UI.Muted
	end
end

local function updateDailyBtn()
	if canClaimDaily then
		dailyClaimBtn.Text = "CLAIM  +1,000"
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(140, 100, 10)
		dailyClaimBtn.Active = true
		dailyClaimBtn.AutoButtonColor = true
		dailySubLabel.Text = "+1,000 Fans  ·  Ready to collect!"
		dailySubLabel.TextColor3 = UI.Gold
	else
		dailyClaimBtn.Text = Utils.FormatCountdown(dailyRemaining)
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		dailyClaimBtn.Active = false
		dailyClaimBtn.AutoButtonColor = false
		dailySubLabel.Text = "Claimed on login · Next in " .. Utils.FormatCountdown(dailyRemaining)
		dailySubLabel.TextColor3 = UI.Muted
	end
end

-- ── Populate from server data ─────────────────────────────────────────────────

local function applyData(data)
	if not data then
		return
	end

	freePackRemaining = data.freePackRemaining or Constants.FreePackCooldown
	canClaimFree = data.canClaimFreePack == true

	dailyRemaining = data.dailyRewardRemaining or Constants.DailyRewardCooldown
	canClaimDaily = data.canClaimDailyReward == true

	updateFreePackBtn()
	updateDailyBtn()
end

-- ── Live countdown loop (runs while panel is open) ────────────────────────────

local function runCountdown()
	while isOpen and screenGui.Enabled do
		task.wait(1)
		if not isOpen then
			break
		end

		-- Decrement locally between server refreshes
		if not canClaimFree then
			freePackRemaining = math.max(0, freePackRemaining - 1)
			if freePackRemaining <= 0 then
				canClaimFree = true
			end
		end

		if not canClaimDaily then
			dailyRemaining = math.max(0, dailyRemaining - 1)
			if dailyRemaining <= 0 then
				canClaimDaily = true
			end
		end

		updateFreePackBtn()
		updateDailyBtn()
	end
end

-- ── Open / close ──────────────────────────────────────────────────────────────

local panelScale = make("UIScale", { Scale = 0.88 }, panel)

local function openShop()
	if isOpen then
		return
	end
	isOpen = true
	screenGui.Enabled = true

	-- Fetch fresh state from server
	task.spawn(function()
		local data = GetPlayerDataFn:InvokeServer()
		if isOpen then
			applyData(data)
		end
	end)

	-- Pop-in animation
	panelScale.Scale = 0.88
	TweenService:Create(panelScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	task.spawn(runCountdown)
end

local function closeShop()
	if not isOpen then
		return
	end
	isOpen = false

	TweenService:Create(panelScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.88,
	}):Play()
	task.delay(0.16, function()
		screenGui.Enabled = false
	end)
end

-- ── Wire buttons ──────────────────────────────────────────────────────────────

closeBtn.MouseButton1Click:Connect(closeShop)
overlayBtn.MouseButton1Click:Connect(closeShop)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape and isOpen then
		closeShop()
	end
end)

toggleEvent.Event:Connect(function()
	if isOpen then
		closeShop()
	else
		openShop()
	end
end)

-- ── Free Pack claim ───────────────────────────────────────────────────────────

freeClaimBtn.MouseButton1Click:Connect(function()
	if not canClaimFree or claimingFree then
		return
	end
	claimingFree = true
	freeClaimBtn.Text = "Opening..."
	freeClaimBtn.Active = false

	local result = ClaimFreePackFn:InvokeServer()
	claimingFree = false

	if result and result.success then
		-- PackOpenedEvent fires server-side → card reveal appears automatically.
		-- Reset our local timer so the button shows the new cooldown immediately.
		canClaimFree = false
		freePackRemaining = result.freePackRemaining or Constants.FreePackCooldown
		updateFreePackBtn()
		-- Close the shop so the card reveal is unobstructed
		closeShop()
	else
		-- Show error briefly on the button then restore
		freeClaimBtn.Text = result and result.error or "Error"
		task.delay(2, function()
			if not canClaimFree then
				updateFreePackBtn()
			end
		end)
	end
end)

-- ── Daily Reward claim ────────────────────────────────────────────────────────

dailyClaimBtn.MouseButton1Click:Connect(function()
	if not canClaimDaily or claimingDaily then
		return
	end
	claimingDaily = true
	dailyClaimBtn.Text = "Claiming..."
	dailyClaimBtn.Active = false

	local result = ClaimDailyRewardFn:InvokeServer()
	claimingDaily = false

	if result and result.success then
		canClaimDaily = false
		dailyRemaining = result.dailyRewardRemaining or Constants.DailyRewardCooldown
		updateDailyBtn()

		-- Brief green flash on the button to celebrate
		dailyClaimBtn.Text = "+1,000 Fans!"
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 65)
		task.delay(1.8, function()
			if not canClaimDaily then
				updateDailyBtn()
			end
		end)
	else
		dailyClaimBtn.Text = result and result.error or "Error"
		task.delay(2, function()
			if not canClaimDaily then
				updateDailyBtn()
			end
		end)
	end
end)

]])

makeLocal('ToolClient', sps, [[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local RequestPitchforkHit = Remotes:WaitForChild("RequestPitchforkHit")

local boundTools = {}
local localSwingLocked = false

local function bindPitchfork(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Pitchfork" or boundTools[tool] then
		return
	end

	boundTools[tool] = true
	tool.Activated:Connect(function()
		if localSwingLocked then
			return
		end

		localSwingLocked = true
		RequestPitchforkHit:FireServer()
		task.delay(0.1, function()
			localSwingLocked = false
		end)
	end)
end

local function watchContainer(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		bindPitchfork(child)
	end

	container.ChildAdded:Connect(function(child)
		bindPitchfork(child)
	end)
end

watchContainer(player:WaitForChild("Backpack"))

if player.Character then
	watchContainer(player.Character)
end

player.CharacterAdded:Connect(function(character)
	watchContainer(character)
end)
]])

makeLocal('TradeUI', sps, [[return
]])

makeLocal('UpgradesUI', sps, [[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetUpgradesFn = Remotes:WaitForChild("GetUpgrades")
local PurchaseUpgradeFn = Remotes:WaitForChild("PurchaseUpgrade")
local UpdateCoinsEvent = Remotes:WaitForChild("UpdateCoins")

local UI = Constants.UI

local function make(className, props, parent)
	props = props or {}
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local existingGui = playerGui:FindFirstChild("UpgradesUI")
if existingGui then
	existingGui:Destroy()
end

local screenGui = make("ScreenGui", {
	Name = "UpgradesUI",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

local panel = make("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.92, 0, 0.85, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = UI.Panel,
}, screenGui)
addCorner(panel, 18)
addStroke(panel, UI.Gold, 2, 0.35)

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(320, 360)
panelSize.MaxSize = Vector2.new(560, 460)
panelSize.Parent = panel

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 38),
	Position = UDim2.new(0, 16, 0, 12),
	Text = "Club Upgrades",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local coinsHeader = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 220, 0, 24),
	Position = UDim2.new(1, -236, 0, 18),
	Text = "0 Fans",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Right,
}, panel)

local closeButton = make("TextButton", {
	Size = UDim2.fromOffset(32, 32),
	Position = UDim2.new(1, -44, 0, 46),
	BackgroundColor3 = UI.PanelAlt,
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
}, panel)
addCorner(closeButton, 8)

local scrolling = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -24, 1, -92),
	Position = UDim2.new(0, 12, 0, 82),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, panel)

local layout = make("UIListLayout", {
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scrolling)

local function formatValue(entry)
	if entry.key == "PackSpawnRate" then
		return string.format("%.1f%s", entry.currentValue, entry.valueSuffix)
	elseif entry.key == "PadLuck" then
		return string.format("+%d%%%s", entry.currentValue, "")
	elseif entry.key == "MoveSpeed" then
		return string.format("%d studs/s", entry.currentValue)
	end
	return string.format("%s%s", tostring(entry.currentValue), entry.valueSuffix or "")
end

local function formatNextValue(entry)
	if entry.key == "PackSpawnRate" then
		return string.format("%.1fs", entry.nextValue)
	elseif entry.key == "PadLuck" then
		return string.format("+%d%%", entry.nextValue)
	elseif entry.key == "MoveSpeed" then
		return string.format("%d studs/s", entry.nextValue)
	end
	return tostring(entry.nextValue)
end

local rows = {}

local function clearRows()
	for _, row in ipairs(rows) do
		if row.frame.Parent then
			row.frame:Destroy()
		end
	end
	rows = {}
end

local function buildRow(entry, index)
	local row = make("Frame", {
		LayoutOrder = index,
		BackgroundColor3 = UI.PanelAlt,
		Size = UDim2.new(1, -12, 0, 96),
	}, scrolling)
	addCorner(row, 14)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(0.6, 0, 0, 22),
		Text = entry.displayName,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 32),
		Size = UDim2.new(0.6, 0, 0, 18),
		Text = entry.description,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, row)

	local levelText
	if entry.maxed then
		levelText = string.format("Lv %d / %d MAX", entry.level, entry.maxLevel)
	else
		levelText = string.format("Lv %d / %d  •  Now: %s  →  Next: %s", entry.level, entry.maxLevel, formatValue(entry), formatNextValue(entry))
	end

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 58),
		Size = UDim2.new(0.65, 0, 0, 30),
		Text = levelText,
		TextColor3 = UI.Gold,
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local buyButton = make("TextButton", {
		Size = UDim2.fromOffset(148, 56),
		Position = UDim2.new(1, -160, 0.5, -28),
		BackgroundColor3 = entry.maxed and UI.PanelAlt or UI.Gold,
		Text = entry.maxed and "MAX" or ("Buy  •  " .. Utils.FormatNumber(entry.nextCost)),
		TextColor3 = entry.maxed and UI.Muted or Color3.fromRGB(18, 12, 6),
		TextScaled = false,
		TextSize = 16,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = not entry.maxed,
		Active = not entry.maxed,
	}, row)
	addCorner(buyButton, 12)

	table.insert(rows, { frame = row, entry = entry, buyButton = buyButton })
	return row, buyButton
end

local refreshing = false
local pendingPayload

local function renderPayload(payload)
	if not payload then
		return
	end
	pendingPayload = payload
	coinsHeader.Text = Utils.FormatNumber(payload.coins or 0) .. " Fans"
	clearRows()

	for index, entry in ipairs(payload.upgrades or {}) do
		local _, buyButton = buildRow(entry, index)
		local key = entry.key
		local cost = entry.nextCost
		buyButton.MouseButton1Click:Connect(function()
			if entry.maxed or refreshing then
				return
			end
			if cost and (payload.coins or 0) < cost then
				buyButton.Text = "Not enough Fans"
				task.delay(0.8, function()
					if buyButton.Parent then
						buyButton.Text = "Buy  •  " .. Utils.FormatNumber(cost)
					end
				end)
				return
			end

			refreshing = true
			buyButton.Text = "..."
			local result = PurchaseUpgradeFn:InvokeServer(key)
			refreshing = false
			if result and result.success then
				renderPayload(result)
			else
				buyButton.Text = (result and result.error) or "Failed"
				task.delay(1.2, function()
					if buyButton.Parent then
						buyButton.Text = "Buy  •  " .. Utils.FormatNumber(cost)
					end
				end)
			end
		end)
	end

	task.defer(function()
		scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

local function refresh()
	local payload = GetUpgradesFn:InvokeServer()
	renderPayload(payload)
end

local function setVisible(visible)
	panel.Visible = visible
	if visible then
		refresh()
	end
end

closeButton.MouseButton1Click:Connect(function()
	setVisible(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		setVisible(false)
	end
end)

toggleEvent.Event:Connect(function()
	setVisible(not panel.Visible)
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins)
	if pendingPayload then
		pendingPayload.coins = coins
	end
	coinsHeader.Text = Utils.FormatNumber(coins or 0) .. " Fans"
end)
]])

print("[UnboxAFootballer] v16 Rojo-synced fallback setup complete")
