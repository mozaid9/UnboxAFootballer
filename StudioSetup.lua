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
	FloodlightAssetId = 16893178499,
	ModelAssets = {
		SoccerPitchLines = 76319198813958,
		StadiumSeats = 76307049854808,
		GoalPost = 71337096414715,
		Scoreboard = 132186518014609,
		EntranceGate = 130179320229653,
		CrowdBarrier = 9103648774,
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

function Utils.GetRarityColor(rarity)
	if rarity == "Premium Gold" then
		return Constants.UI.PremiumGold
	elseif rarity == "Rare Gold" then
		return Constants.UI.RareGold
	end
	return Constants.UI.Gold
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

	local bestMilestone
	for _, milestone in ipairs(packMilestones or {}) do
		local interval = milestone.interval
		if type(interval) == "number" and interval > 0 then
			local nextAt = (math.floor(totalPacks / interval) + 1) * interval
			local previousAt = nextAt - interval
			local progress = math.clamp((totalPacks - previousAt) / interval, 0, 1)
			if not bestMilestone or nextAt < bestMilestone.nextAt or (nextAt == bestMilestone.nextAt and interval > bestMilestone.interval) then
				bestMilestone = {
					interval = interval,
					nextAt = nextAt,
					progress = progress,
					reward = milestone.reward or "Reward",
				}
			end
		end
	end

	return bestMilestone or {
		interval = 50,
		nextAt = 50,
		progress = 0,
		reward = "Rare Pack",
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
	plot.padSubtitleLabel.Text = string.format("%d / %d HP", currentValue, maxValue)
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = true
	plot.padBarFill.BackgroundColor3 = color
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

local function createGoalPost(parent, name, baseCFrame, localX, y)
	local model = make("Model", {
		Name = name,
	}, parent)

	local goalWidth = 10.5
	local goalHeight = 4.6
	local goalDepth = 3.4
	local thickness = 0.32
	local outward = localX >= 0 and 1 or -1
	local postColor = Color3.fromRGB(245, 247, 240)

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
			CFrame = baseCFrame * CFrame.new(localOffset),
		}, model)
	end

	goalPart("LeftPost", Vector3.new(thickness, goalHeight, thickness), Vector3.new(localX, y + goalHeight / 2, -goalWidth / 2))
	goalPart("RightPost", Vector3.new(thickness, goalHeight, thickness), Vector3.new(localX, y + goalHeight / 2, goalWidth / 2))
	goalPart("Crossbar", Vector3.new(thickness, thickness, goalWidth + thickness), Vector3.new(localX, y + goalHeight, 0))
	goalPart("BackLeftPost", Vector3.new(thickness, goalHeight * 0.82, thickness), Vector3.new(localX + outward * goalDepth, y + (goalHeight * 0.82) / 2, -goalWidth / 2))
	goalPart("BackRightPost", Vector3.new(thickness, goalHeight * 0.82, thickness), Vector3.new(localX + outward * goalDepth, y + (goalHeight * 0.82) / 2, goalWidth / 2))
	goalPart("BackCrossbar", Vector3.new(thickness, thickness, goalWidth + thickness), Vector3.new(localX + outward * goalDepth, y + goalHeight * 0.82, 0))
	goalPart("NorthTopDepth", Vector3.new(goalDepth, thickness, thickness), Vector3.new(localX + outward * (goalDepth / 2), y + goalHeight, -goalWidth / 2))
	goalPart("SouthTopDepth", Vector3.new(goalDepth, thickness, thickness), Vector3.new(localX + outward * (goalDepth / 2), y + goalHeight, goalWidth / 2))

	return model
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

	createGoalPost(pitchFolder, "FrontGoalPost", baseCFrame, halfLength + 0.75, 0.82)
	createGoalPost(pitchFolder, "BackGoalPost", baseCFrame, -halfLength - 0.75, 0.82)

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

	make("Part", {
		Name = "Post",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(0.55, 10, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, 5, 0)),
	}, model)

	local banner = make("Part", {
		Name = "Banner",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(4.8, 8.5, 0.35),
		CFrame = CFrame.lookAt(position + Vector3.new(0, 6.2, 0), lookTarget),
	}, model)
	createSurfaceText(banner, title, "FOOTBALLER")

	return model
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

local function createFanZone(mapWidth, mapLength)
	local plaza = make("Model", {
		Name = "FanZone",
	}, basesFolder)

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
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(188, 154, 54),
		Transparency = 0.18,
		Size = Vector3.new(0.28, 0.08, mapLength - 78),
		CFrame = CFrame.new(-27, 0.38, 0),
	}, plaza)
	make("Part", {
		Name = "MainWalkwayRightEdge",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(188, 154, 54),
		Transparency = 0.18,
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
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(188, 154, 54),
			Transparency = 0.22,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.22),
			CFrame = CFrame.new(0, 0.4, laneZ - 6.8),
		}, plaza)
		make("Part", {
			Name = "StadiumPathGuideB" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(188, 154, 54),
			Transparency = 0.22,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.22),
			CFrame = CFrame.new(0, 0.4, laneZ + 6.8),
		}, plaza)
	end

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

	-- Gold football sitting on the top plinth (centre at Y=12.0, radius=3.5 → bottom Y=8.5)
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

	-- Slow spin + tilt so the ball looks like it's rolling in the air
	task.spawn(function()
		local ballAngle = 0
		local ballBaseY = 12.0
		while ball.Parent do
			ballAngle = ballAngle + math.rad(20) / 30 -- ≈ 20°/s
			local floatOffset = math.sin(os.clock() * 0.85) * 0.38
			ball.CFrame = CFrame.new(0, ballBaseY + floatOffset, 0)
				* CFrame.Angles(math.rad(22), ballAngle, 0)
			task.wait(1 / 30)
		end
	end)

	local plazaSign = make("Part", {
		Name = "FanZoneSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(18, 3.2, 0.5),
		CFrame = CFrame.lookAt(Vector3.new(0, 3.2, -13), Vector3.new(0, 3.2, -40)),
	}, plaza)
	createSurfaceText(plazaSign, "FAN ZONE", "")

	createFanGate(plaza, "NorthFanGate", northZ, -1)
	createFanGate(plaza, "SouthFanGate", southZ, 1)

	-- ── Food & drinks kiosks ──────────────────────────────────────────
	-- Four stalls form a square around the central podium.  NPCs detour
	-- here as they pass through the plaza, then carry on to their exit.
	-- Y=0.35 sits the booth base flush on the plaza surface (top ≈ Y=0.33)
	local center0 = Vector3.new(0, 0.35, 0)  -- all stalls face the podium

	createFoodKiosk(plaza, "KioskNW",
		Vector3.new(-24, 0.35, -10), 1, center0)  -- POPCORN

	createFoodKiosk(plaza, "KioskNE",
		Vector3.new(24, 0.35, -10),  2, center0)  -- HOT DOGS

	createFoodKiosk(plaza, "KioskSW",
		Vector3.new(-24, 0.35, 10),  3, center0)  -- BURGERS

	createFoodKiosk(plaza, "KioskSE",
		Vector3.new(24, 0.35, 10),   4, center0)  -- DRINKS

	local bannerConfigs = {
		{ position = Vector3.new(-24, 0, -20), title = "FANS" },
		{ position = Vector3.new(24, 0, -20), title = "PACKS" },
		{ position = Vector3.new(-24, 0, 20), title = "CLUB" },
		{ position = Vector3.new(24, 0, 20), title = "STARS" },
	}
	for index, config in ipairs(bannerConfigs) do
		createVerticalBanner(plaza, "PlazaBanner" .. index, config.position, Vector3.new(0, 6, 0), config.title)
	end

	local planterPositions = {
		Vector3.new(-34, 0, -28),
		Vector3.new(34, 0, -28),
		Vector3.new(-34, 0, 28),
		Vector3.new(34, 0, 28),
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
		createLightPost(plaza, "LaneWestLightA" .. laneIndex, Vector3.new(-36, 0, laneZ - 12), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneWestLightB" .. laneIndex, Vector3.new(-36, 0, laneZ + 12), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightA" .. laneIndex, Vector3.new(36, 0, laneZ - 12), Vector3.new(layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightB" .. laneIndex, Vector3.new(36, 0, laneZ + 12), Vector3.new(layout.SideOffset, 1, laneZ))
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
	-- Food stand stops: NPCs step off the central walkway toward the
	-- kiosk on their lane side, look at it, pause, then return to route.
	createWaypoint(waypointFolder, "FoodCenterWest", Vector3.new(-16, 3.1, -5))
	createWaypoint(waypointFolder, "FoodCenterEast", Vector3.new(16, 3.1, 5))

	startTurnstileAnimations()
	return plaza
end

local function createDisplayCardFace(face, card, incomePerSecond, parent)
	local rarityColor = Utils.GetRarityColor(card.rarity)
	local isPremium = card.rarity == "Premium Gold"
	local trimColor = isPremium and Color3.fromRGB(252, 240, 200) or Color3.fromRGB(218, 170, 52)

	local gui = make("SurfaceGui", {
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, parent)

	-- Outer card frame
	local frame = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(38, 26, 10),
		BorderSizePixel = 0,
	}, gui)

	-- Vertical rarity gradient — bright at top, deep brown at bottom
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor),
			ColorSequenceKeypoint.new(0.48, rarityColor:Lerp(Color3.fromRGB(86, 60, 18), 0.45)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 22, 8)),
		}),
		Rotation = 90,
	}, frame)

	-- Outer gold trim
	make("UIStroke", {
		Color = trimColor,
		Thickness = 4,
	}, frame)

	-- Inner inset border detail
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

	-- Rating (dominant, top-left)
	local ratingLabel = createSignLabel(tostring(card.rating), UDim2.new(0.34, 0, 0.24, 0), UDim2.new(0.1, 0, 0.06, 0), Color3.fromRGB(22, 12, 2), frame)
	ratingLabel.TextXAlignment = Enum.TextXAlignment.Left
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.6,
		Transparency = 0.15,
	}, ratingLabel)

	-- Position (under rating)
	local positionLabel = createSignLabel(card.position, UDim2.new(0.28, 0, 0.1, 0), UDim2.new(0.11, 0, 0.3, 0), Color3.fromRGB(34, 22, 6), frame)
	positionLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Divider band between top cluster and name
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 14, 4),
		BorderSizePixel = 0,
		Size = UDim2.new(0.74, 0, 0, 2),
		Position = UDim2.new(0.13, 0, 0.44, 0),
	}, frame)

	-- Player name (big, centered)
	local nameLabel = createSignLabel(card.name, UDim2.new(0.84, 0, 0.16, 0), UDim2.new(0.08, 0, 0.48, 0), Color3.fromRGB(22, 12, 4), frame)
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.2,
		Transparency = 0.3,
	}, nameLabel)

	-- Nation (below name)
	createSignLabel(card.nation, UDim2.new(0.78, 0, 0.08, 0), UDim2.new(0.11, 0, 0.67, 0), Color3.fromRGB(46, 32, 10), frame)

	-- Income pill at bottom
	local incomePill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(26, 58, 32),
		Size = UDim2.new(0.72, 0, 0.11, 0),
		Position = UDim2.new(0.14, 0, 0.82, 0),
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

	createSignLabel("+" .. tostring(incomePerSecond) .. " /s", UDim2.fromScale(0.9, 0.72), UDim2.fromScale(0.05, 0.14), Color3.fromRGB(228, 255, 220), incomePill)
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

	local base = make("Part", {
		Name = "Base",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(20, 26, 38),
		Size = layout.DisplaySlotSize,
		CFrame = cframe,
	}, model)

	local top = make("Part", {
		Name = "Top",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(34, 128, 76),
		Transparency = 0.08,
		Size = Vector3.new(layout.DisplaySlotSize.X - 1.4, 0.18, layout.DisplaySlotSize.Z - 1.4),
		CFrame = base.CFrame + Vector3.new(0, layout.DisplaySlotSize.Y / 2 + 0.1, 0),
	}, model)

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
	local padInfoMaxDistance = layout.PadInfoMaxDistance or 38
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

	local borderTop = createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY, -layout.PlotSize.Z / 2))
	local borderBottom = createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY, layout.PlotSize.Z / 2))
	local backWall = createFence(model, Vector3.new(wallThickness, wallHeight, layout.PlotSize.Z + wallThickness), baseCFrame * CFrame.new(backEdgeX, wallY, 0))
	local frontWallSegmentLength = math.max(8, (layout.PlotSize.Z - entranceWidth) / 2)
	local frontWallZOffset = (entranceWidth / 2) + (frontWallSegmentLength / 2)
	local frontWallNorth = createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY, -frontWallZOffset))
	local frontWallSouth = createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY, frontWallZOffset))
	local entrancePillarHeight = wallHeight + 5.6
	local entrancePillarX = frontEdgeX + (facingDirection * ((entrancePillarWidth - wallThickness) / 2))
	local entrancePillarNorth = createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2, -(entranceWidth / 2)))
	local entrancePillarSouth = createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2, entranceWidth / 2))
	_ = borderTop
	_ = borderBottom
	_ = backWall
	_ = frontWallNorth
	_ = frontWallSouth
	_ = entrancePillarNorth
	_ = entrancePillarSouth

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

	local centerStrip = make("Part", {
		Name = "CenterStrip",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(140, 144, 148),
		Size = Vector3.new(layout.PlotSize.X - 8, 0.12, 8),
		CFrame = baseCFrame * CFrame.new(0, 0.56, 0),
	}, model)
	_ = centerStrip

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
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(110, 116, 122),
		Size = Vector3.new(10, 0.45, 10),
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
	local ownerSignPosition = position + (centerDirection * (layout.PlotSize.X / 2 + 2.1)) + Vector3.new(0, entranceBeamY + 3.1, 0)
	local entranceBeam = createFence(
		model,
		Vector3.new(entrancePillarWidth + 1, 1.4, entranceWidth + 1.2),
		baseCFrame * CFrame.new(frontEdgeX + (facingDirection * 0.9), entranceBeamY, 0)
	)
	_ = entranceBeam
	local ownerSign = make("Part", {
		Name = "OwnerSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(16, 4.4, 0.6),
		CFrame = CFrame.lookAt(ownerSignPosition, ownerSignPosition + centerDirection),
	}, model)


	local ownerGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 160,
		LightInfluence = 0,
	}, ownerSign)

	local ownerFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 14, 24),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, ownerGui)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 14, 24)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 20, 34)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 12, 20)),
		}),
		Rotation = 90,
	}, ownerFrame)

	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 3,
	}, ownerFrame)

	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 0),
	}, ownerFrame)

	local ownerTopLabel = createOwnerSignText("AVAILABLE PLOT", UDim2.fromScale(0.7, 0.12), UDim2.fromScale(0.15, 0.08), Color3.fromRGB(255, 223, 120), {
		textScaled = true,
		minTextSize = 24,
		maxTextSize = 58,
		textStrokeTransparency = 0.9,
		font = Enum.Font.GothamBlack,
	}, ownerFrame)

	local ownerNameLabel = createOwnerSignText("OPEN", UDim2.fromScale(0.86, 0.3), UDim2.fromScale(0.07, 0.25), Color3.fromRGB(245, 238, 220), {
		textScaled = true,
		minTextSize = 64,
		maxTextSize = 240,
		textStrokeTransparency = 0.72,
		font = Enum.Font.GothamBlack,
	}, ownerFrame)

	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.58, 0.014),
		Position = UDim2.fromScale(0.21, 0.58),
	}, ownerFrame)

	local ownerSubtitleLabel = createOwnerSignText("STADIUM", UDim2.fromScale(0.76, 0.2), UDim2.fromScale(0.12, 0.64), Color3.fromRGB(214, 206, 184), {
		textScaled = true,
		minTextSize = 44,
		maxTextSize = 160,
		textStrokeTransparency = 0.84,
		font = Enum.Font.GothamBlack,
	}, ownerFrame)

	local milestoneSignPosition = position
		+ Vector3.new(backEdgeX - (facingDirection * 7.2), 5.5, 0)
	local milestoneSign = make("Part", {
		Name = "PackMilestoneBillboard",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(6, 9, 16),
		Size = Vector3.new(15.5, 7.0, 0.5),
		CFrame = CFrame.lookAt(milestoneSignPosition, milestoneSignPosition + centerDirection),
	}, model)

	-- Neon glow light so the board is visible across the plaza
	make("PointLight", {
		Color = Color3.fromRGB(255, 215, 0),
		Range = 18,
		Brightness = 0.55,
		Shadows = false,
	}, milestoneSign)

	local milestoneGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 80,
		LightInfluence = 0,
	}, milestoneSign)

	local milestoneFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, milestoneGui)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, milestoneFrame)

	-- Gold border
	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 3,
		Transparency = 0.0,
	}, milestoneFrame)

	-- Bright gold accent strip across the top
	local topStrip = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromScale(0, 0),
		ZIndex = 2,
	}, milestoneFrame)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, topStrip)
	_ = topStrip

	-- "PACK MILESTONES" header
	local milestoneTitleLabel = createOwnerSignText("\u{2605} PACK MILESTONES", UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0.05, 0.06), Color3.fromRGB(255, 215, 0), {
		textScaled = true,
		minTextSize = 14,
		maxTextSize = 38,
		textStrokeTransparency = 0.65,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)
	_ = milestoneTitleLabel

	-- Large packs-opened counter — most prominent element
	local milestonePacksLabel = createOwnerSignText("0 PACKS OPENED", UDim2.fromScale(0.92, 0.28), UDim2.fromScale(0.04, 0.22), Color3.fromRGB(255, 245, 220), {
		textScaled = true,
		minTextSize = 22,
		maxTextSize = 72,
		textStrokeTransparency = 0.60,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)

	-- Thin divider line between counter and next-milestone row
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(0.82, 0, 0, 2),
		Position = UDim2.fromScale(0.09, 0.535),
	}, milestoneFrame)

	-- "NEXT:" label — smaller, muted
	createOwnerSignText("NEXT REWARD", UDim2.fromScale(0.88, 0.10), UDim2.fromScale(0.06, 0.56), Color3.fromRGB(170, 165, 148), {
		textScaled = true,
		minTextSize = 10,
		maxTextSize = 24,
		textStrokeTransparency = 0.88,
		font = Enum.Font.GothamBold,
	}, milestoneFrame)

	-- Reward name — prominent gold text
	local milestoneNextLabel = createOwnerSignText("50 PACKS \u{2192} RARE PACK", UDim2.fromScale(0.88, 0.14), UDim2.fromScale(0.06, 0.64), Color3.fromRGB(255, 210, 80), {
		textScaled = true,
		minTextSize = 12,
		maxTextSize = 36,
		textStrokeTransparency = 0.68,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)

	-- Progress bar — taller, more visible
	local milestoneBarBack = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(28, 34, 50),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.84, 0.095),
		Position = UDim2.fromScale(0.08, 0.83),
	}, milestoneFrame)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarBack)
	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 2,
		Transparency = 0.55,
	}, milestoneBarBack)

	local milestoneBarFill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	}, milestoneBarBack)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarFill)

	-- Inner shimmer layer on the fill to give it depth
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 200),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0.4, 0),
		Position = UDim2.fromScale(0, 0),
	}, milestoneBarFill)

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

	local slotOffsets = {
		Vector3.new(-12, 1.75, -14),
		Vector3.new(0, 1.75, -14),
		Vector3.new(12, 1.75, -14),
		Vector3.new(-12, 1.75, 14),
		Vector3.new(0, 1.75, 14),
		Vector3.new(12, 1.75, 14),
	}

	local displaySlots = {}
	for slotIndex = 1, layout.DisplaySlotCount do
		local localOffset = slotOffsets[slotIndex]
		local worldOffset = Vector3.new(localOffset.X * facingDirection, localOffset.Y, localOffset.Z)
		local slotLookDirection = localOffset.Z < 0 and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1)
		displaySlots[slotIndex] = createDisplaySlot(displayFolder, slotIndex, baseCFrame * CFrame.new(worldOffset), slotLookDirection)
	end

	local entranceLightX = frontEdgeX + (facingDirection * 8)
	createLightPost(model, "EntranceLightNorth", position + Vector3.new(entranceLightX, 0, -(entranceWidth / 2 + 6)), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "EntranceLightSouth", position + Vector3.new(entranceLightX, 0, entranceWidth / 2 + 6), packPad.Position + Vector3.new(0, 2, 0))
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

	local plot = {
		id = plotId,
		side = side,
		laneIndex = laneIndex,
		model = model,
		facingDirection = facingDirection,
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
		padTitleLabel = padTitleLabel,
		padSubtitleLabel = padSubtitleLabel,
		padAccent = padAccent,
		padGui = padGui,
		padBarBack = padBarBack,
		padBarFill = padBarFill,
		displaySlots = displaySlots,
		spawnCFrame = spawnCFrame,
	}

	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))

	return plot
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

function BaseService.AssignPlot(player)
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

function BaseService.UpdatePackMilestone(plot, totalPacks)
	if not plot or not plot.milestonePacksLabel or not plot.milestoneNextLabel or not plot.milestoneBarFill then
		return
	end

	totalPacks = math.max(0, totalPacks or 0)
	local milestone = getNextPackMilestone(totalPacks)
	plot.milestonePacksLabel.Text = Utils.FormatNumber(totalPacks) .. " PACKS OPENED"
	plot.milestoneNextLabel.Text = string.format("%d PACKS \u{2192} %s", milestone.nextAt, string.upper(milestone.reward))
	plot.milestoneBarFill.Size = UDim2.fromScale(milestone.progress, 1)
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

-- Colours for the small food/drink prop NPCs carry after a kiosk stop
local FOOD_COLORS = {
	Color3.fromRGB(255, 200, 70),   -- yellow (hot dog / chips)
	Color3.fromRGB(200, 55, 30),    -- red (drink cup)
	Color3.fromRGB(255, 140, 40),   -- orange (fanta)
	Color3.fromRGB(235, 235, 235),  -- white (popcorn)
}
local STAND_TIERS = {
	{ zOffset = 24.2, surfaceY = 1.9 },
	{ zOffset = 27.1, surfaceY = 2.8 },
	{ zOffset = 30.0, surfaceY = 3.7 },
}

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
local function setFoodProp(model, enabled)
	local existing = model:FindFirstChild("FoodProp")
	if existing then
		existing:Destroy()
	end
	if not enabled or not model.Parent then
		return
	end
	local pivot = model:GetPivot()
	local propModel = make("Model", {
		Name = "FoodProp",
	}, model)
	-- Front is local -Z for CFrame.lookAt. Keep the prop high, bright, and
	-- slightly in front of the right hand so it reads clearly from gameplay view.
	local propCFrame = pivot * CFrame.new(1.72, -0.05, -0.95)
	local propColor = FOOD_COLORS[math.random(1, #FOOD_COLORS)]

	local cup = make("Part", {
		Name = "Cup",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = propColor,
		Size = Vector3.new(0.72, 0.92, 0.72),
		CFrame = propCFrame,
	}, propModel)

	make("PointLight", {
		Name = "CupGlow",
		Color = propColor,
		Range = 5,
		Brightness = 0.35,
		Shadows = false,
	}, cup)

	make("Part", {
		Name = "Lid",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 235, 160),
		Size = Vector3.new(0.80, 0.10, 0.80),
		CFrame = propCFrame * CFrame.new(0, 0.51, 0),
	}, propModel)

	make("Part", {
		Name = "Straw",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(245, 245, 245),
		Size = Vector3.new(0.10, 0.82, 0.10),
		CFrame = propCFrame * CFrame.new(0.20, 0.86, -0.06) * CFrame.Angles(0, 0, math.rad(12)),
	}, propModel)
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
	local foodCenterWest = getPoint("FoodCenterWest")
	local foodCenterEast = getPoint("FoodCenterEast")
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

	-- Configured chance: detour to the food kiosk cluster at the centre.
	-- NPCs step toward the kiosk on their lane side, hold a prop, pause,
	-- then continue toward their loop waypoint.
	-- isFood = true tells runFan to hand a prop to the NPC before the pause.
	if math.random() < (plazaConfig.FoodStopChance or 0.30) then
		local westSide = laneOffset < 0
		local rawFood = westSide and foodCenterWest or foodCenterEast
		rawFood = rawFood or foodCenterWest or foodCenterEast  -- fallback

		if rawFood then
			local kioskSideX = westSide and -24 or 24
			local kioskZ = westSide and -10 or 10
			-- Insert between "center" and "loop" steps so NPC passes the
			-- kiosk area naturally in the middle of their plaza walk.
			table.insert(route, 3, {
				position = rawFood,
				pause = math.random(8, 18),
				isFood = true,
				lookAt = Vector3.new(kioskSideX, rawFood.Y, kioskZ),
			})
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

				for index = 2, #route do
					local step = route[index]
					local targetPosition = getStepPosition(step)

					if typeof(step) ~= "table" or step.pose ~= "seated" then
						setFanPose(model, "standing")
					end

					if not moveModelTo(model, targetPosition) then
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

					-- Hand the NPC a prop BEFORE the pause so they hold it while
					-- waiting at the kiosk (looks like they received their order)
					if typeof(step) == "table" and step.isFood and not hasFood then
						setFoodProp(model, true)
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

					task.wait(math.random(8, 22) / 100)
				end

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
		statusLabel.Text = #inventory > 0 and "Stored players earn money when placed on green display slots." or "Stored players will appear here when your displays are full."
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
		local tile = make("Frame", {
			LayoutOrder = index,
			BackgroundColor3 = Constants.UI.PanelAlt,
		}, scrolling)
		addCorner(tile, 14)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 8),
			Size = UDim2.new(0, 30, 0, 22),
			Text = tostring(card.rating),
			TextColor3 = Utils.GetRarityColor(card.rarity),
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.44, 0),
			Size = UDim2.new(0.84, 0, 0.18, 0),
			Text = card.name,
			TextColor3 = Constants.UI.Text,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.68, 0),
			Size = UDim2.new(0.84, 0, 0.12, 0),
			Text = card.position .. " • " .. card.nation,
			TextColor3 = Constants.UI.Muted,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.73, 0),
			Size = UDim2.new(0.84, 0, 0.07, 0),
			Text = "Stored x" .. tostring(card.quantity) .. " • +" .. tostring(Utils.GetPassiveIncome(card.rating)) .. "/s",
			TextColor3 = Utils.GetRarityColor(card.rarity),
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
	Size = UDim2.fromOffset(168, 188),
	Position = UDim2.new(0, 20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.12,
}, screenGui)
addCorner(sidebar, 16)
addStroke(sidebar, UI.Gold, 1.25, 0.72)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 22, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 18)),
	}),
	Rotation = 90,
}, sidebar)

local sidebarPadding = make("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, sidebar)
_ = sidebarPadding

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local walletDock = make("Frame", {
	Name = "WalletDock",
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(218, 98),
	Position = UDim2.new(1, -20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.1,
}, screenGui)
addCorner(walletDock, 16)
addStroke(walletDock, UI.Gold, 1.25, 0.72)

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

local function createWalletRow(parent, order, labelText, iconText, iconColor)
	local row = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = UI.Panel,
	}, parent)
	addCorner(row, 10)
	addStroke(row, iconColor, 1.5, 0.7)

	local icon = make("TextLabel", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 8, 0.5, -13),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.72),
		Text = iconText,
		TextColor3 = iconColor,
		TextScaled = false,
		TextSize = 17,
		Font = Enum.Font.GothamBlack,
	}, row)
	addCorner(icon, 9)

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
local gemsLabel, addGemsButton = createWalletRow(walletDock, 2, "Gems", "D", Color3.fromRGB(69, 207, 255))

local function createMenuButton(order, text, accentColor)
	local button = make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = accentColor,
		Text = text,
		TextColor3 = accentColor == UI.Gold and Color3.fromRGB(20, 14, 8) or UI.Text,
		TextScaled = false,
		TextSize = 15,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = true,
	}, sidebar)
	addCorner(button, 9)
	return button
end

local inventoryButton = createMenuButton(1, "Inventory", UI.PanelAlt)
local upgradesButton = createMenuButton(2, "Upgrades", UI.Gold)
local questsButton = createMenuButton(3, "Quests", Color3.fromRGB(42, 54, 126))
local shopButton = createMenuButton(4, "Shop", Color3.fromRGB(25, 118, 55))

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

-- ── Compact card reveal ───────────────────────────────────────────────────────
-- Appears near the pack, shows player info briefly, then flies toward the
-- destination slot (or inventory corner).  No full-screen overlay — keeps the
-- world visible while the card pops.  Auto-destroys in ~2 s.
local function showCardReveal(payload)
	local card = payload.card
	if not card then
		return
	end

	local rarityColor = Utils.GetRarityColor(card.rarity)
	local isPremium = card.rarity == "Premium Gold"
	local trimColor = isPremium and Color3.fromRGB(210, 228, 255) or Color3.fromRGB(218, 168, 48)
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
		BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(10, 5, 2), 0.68),
		ZIndex = 200,
	}, screenGui)
	addCorner(cardPanel, 16)
	addStroke(cardPanel, trimColor, 3)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.14)),
			ColorSequenceKeypoint.new(0.44, rarityColor),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 3, 1)),
		}),
		Rotation = 158,
	}, cardPanel)

	-- UIScale at 0.05 → 1 for the bounce pop-in
	local cardScale = make("UIScale", { Scale = 0.05 }, cardPanel)

	-- Rating (top-left)
	local ratingLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(50, 42),
		Text = tostring(card.rating),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 202,
	}, cardPanel)
	addStroke(ratingLabel, Color3.fromRGB(6, 3, 1), 2, 0.22)

	-- Position (below rating)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(13, 52),
		Size = UDim2.fromOffset(44, 14),
		Text = card.position,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBlack,
		ZIndex = 202,
	}, cardPanel)

	-- Nation (top-right)
	make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 13),
		Size = UDim2.fromOffset(84, 14),
		Text = card.nation,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 202,
	}, cardPanel)

	-- Divider
	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.new(0.84, 0, 0, 1.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 202,
	}, cardPanel)

	-- Monogram circle
	local monogram = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 78),
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
