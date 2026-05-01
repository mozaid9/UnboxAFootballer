-- ============================================================
-- PackConfig.lua
-- Pack definitions plus clean spawn/pull luck helpers.
--
-- Every pack opens exactly ONE card. Odds are intentionally harsh:
-- low packs mostly produce Gold/Rare Gold, while high-tier cards stay
-- rare unless the player reaches better packs or pity milestones.
-- ============================================================

local PackConfig = {}

PackConfig.RarityOrder = {
	"Gold",
	"Rare Gold",
	"Premium Gold",
	"Talisman",
	"Maestro",
	"Immortal",
	"Player of the Year",
}

PackConfig.WeightTiers = {
	{ label = "Gold",               rarities = { "Gold" } },
	{ label = "Rare Gold",          rarities = { "Rare Gold" } },
	{ label = "Premium Gold",       rarities = { "Premium Gold" } },
	{ label = "Talisman",           rarities = { "Talisman" } },
	{ label = "Maestro",            rarities = { "Maestro" } },
	{ label = "Immortal",           rarities = { "Immortal" } },
	{ label = "Player of the Year", rarities = { "Player of the Year" } },
}

PackConfig.RarityRank = {}
for index, rarity in ipairs(PackConfig.RarityOrder) do
	PackConfig.RarityRank[rarity] = index
end
PackConfig.RarityRank.POTY = PackConfig.RarityRank["Player of the Year"]

local NATURAL_PACK_IDS = {
	"GoldPack",
	"RarePack",
	"PremiumPack",
	"JumboPack",
	"DeluxePack",
}

local function copyArray(values)
	local result = {}
	for index, value in ipairs(values or {}) do
		result[index] = value
	end
	return result
end

local function normalizeWeights(weights)
	local total = 0
	for _, weight in ipairs(weights) do
		total += weight
	end
	if total <= 0 then
		return weights
	end

	local normalized = {}
	for index, weight in ipairs(weights) do
		normalized[index] = (weight / total) * 100
	end
	return normalized
end

local function weightedIndex(weights)
	local total = 0
	for _, weight in ipairs(weights) do
		total += weight
	end
	if total <= 0 then
		return nil
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

-- ── Pack definitions ─────────────────────────────────────────
-- tierWeights are base rarity odds, ordered by RarityOrder.
PackConfig.ShopOrder = {
	{
		id = "GoldPack",
		displayName = "Gold Pack",
		description = "Starter pack: mostly Gold, with tiny upgrades possible.",
		cost = 0,
		futureCost = 3000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 8,
		padWeight = 55,
		color = Color3.fromRGB(255, 215, 0),
		tierWeights = { 97.5, 2.3, 0.19, 0.01, 0, 0, 0 },
		station = { position = Vector3.new(-24, 1.5, -16) },
	},
	{
		id = "RarePack",
		displayName = "Rare Pack",
		description = "Better odds, but still mostly Gold and Rare Gold.",
		cost = 0,
		futureCost = 7500,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 12,
		padWeight = 28,
		color = Color3.fromRGB(255, 168, 42),
		tierWeights = { 85, 13.5, 1.4, 0.1, 0, 0, 0 },
		station = { position = Vector3.new(-8, 1.5, -16) },
	},
	{
		id = "PremiumPack",
		displayName = "Premium Pack",
		description = "Mid-game pack with a real Premium Gold target.",
		cost = 0,
		futureCost = 15000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 18,
		padWeight = 12,
		color = Color3.fromRGB(255, 238, 172),
		tierWeights = { 65, 25, 8.5, 1.4, 0.1, 0, 0 },
		station = { position = Vector3.new(8, 1.5, -16) },
	},
	{
		id = "JumboPack",
		displayName = "Jumbo Pack",
		description = "Strong odds without letting legends leak too early.",
		cost = 0,
		futureCost = 30000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 25,
		padWeight = 4,
		color = Color3.fromRGB(255, 100, 50),
		tierWeights = { 55, 28, 13, 3.7, 0.3, 0, 0 },
		station = { position = Vector3.new(24, 1.5, -16) },
	},
	{
		id = "DeluxePack",
		displayName = "Deluxe Pack",
		description = "Late natural pack with tiny Immortal odds.",
		cost = 0,
		futureCost = 75000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 35,
		padWeight = 1,
		color = Color3.fromRGB(235, 56, 43),
		tierWeights = { 45, 30, 18, 6, 0.9, 0.1, 0 },
		station = { position = Vector3.new(-16, 1.5, 4) },
	},
	{
		id = "PlayerPickPack",
		displayName = "Player Pick",
		description = "Choose 1 of 3. Low floor, tiny chance at anyone.",
		cost = 0,
		futureCost = 120000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 34,
		padWeight = 0,
		color = Color3.fromRGB(93, 232, 178),
		tierWeights = { 82, 14, 3.3, 0.55, 0.13, 0.02, 0 },
		playerPick = {
			optionCount = 3,
			minPowerScore = 81,
		},
		station = { position = Vector3.new(-16, 1.5, 4) },
	},
	{
		id = "MegaPack",
		displayName = "Mega Pack",
		description = "Paid pack with better Talisman and Maestro chances.",
		cost = 0,
		futureCost = 250000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 42,
		padWeight = 0,
		color = Color3.fromRGB(65, 210, 140),
		tierWeights = { 35, 30, 22, 9, 3, 0.9, 0.1 },
		station = { position = Vector3.new(-8, 1.5, 4) },
	},
	{
		id = "ElitePack",
		displayName = "Elite Pack",
		description = "Cuts most weak pulls and starts chasing Maestro.",
		cost = 0,
		futureCost = 750000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 46,
		padWeight = 0,
		color = Color3.fromRGB(76, 170, 255),
		tierWeights = { 18, 26, 30, 16, 7, 2.5, 0.5 },
		station = { position = Vector3.new(0, 1.5, 4) },
	},
	{
		id = "ChampionPack",
		displayName = "Champion Pack",
		description = "High-tier hunt with real Immortal upside.",
		cost = 0,
		futureCost = 2000000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 50,
		padWeight = 0,
		color = Color3.fromRGB(62, 214, 232),
		tierWeights = { 5, 14, 26, 28, 18, 7, 2 },
		station = { position = Vector3.new(8, 1.5, 4) },
	},
	{
		id = "PrimePlayerPickPack",
		displayName = "Prime Player Pick",
		description = "Choose 1 of 3. Stronger floor with better specials.",
		cost = 0,
		futureCost = 3500000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 54,
		padWeight = 0,
		color = Color3.fromRGB(96, 206, 255),
		tierWeights = { 35, 25, 20, 12, 5.5, 2, 0.5 },
		playerPick = {
			optionCount = 3,
			minPowerScore = 85,
		},
		station = { position = Vector3.new(8, 1.5, 4) },
	},
	{
		id = "MythicPack",
		displayName = "Mythic Pack",
		description = "Shop-only pack with serious legend odds.",
		cost = 0,
		futureCost = 5000000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 50,
		padWeight = 0,
		color = Color3.fromRGB(157, 80, 255),
		tierWeights = { 0, 6, 20, 30, 26, 14, 4 },
		station = { position = Vector3.new(0, 1.5, 4) },
	},
	{
		id = "IconPack",
		displayName = "Icon Pack",
		description = "Expensive chase pack for Maestro and Immortal cards.",
		cost = 0,
		futureCost = 12500000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 60,
		padWeight = 0,
		color = Color3.fromRGB(255, 94, 169),
		tierWeights = { 0, 0, 10, 25, 34, 23, 8 },
		station = { position = Vector3.new(8, 1.5, 4) },
	},
	{
		id = "ElitePlayerPickPack",
		displayName = "Elite Player Pick",
		description = "Choose 1 of 4. High-floor pick with real legend odds.",
		cost = 0,
		futureCost = 25000000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 68,
		padWeight = 0,
		color = Color3.fromRGB(255, 178, 84),
		tierWeights = { 12, 22, 26, 18, 12, 7, 3 },
		playerPick = {
			optionCount = 4,
			minPowerScore = 87,
		},
		station = { position = Vector3.new(16, 1.5, 4) },
	},
	{
		id = "ImmortalPack",
		displayName = "Immortal Pack",
		description = "Luxury pack with big Immortal and POTY odds.",
		cost = 0,
		futureCost = 35000000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 70,
		padWeight = 0,
		color = Color3.fromRGB(255, 245, 171),
		tierWeights = { 0, 0, 3, 12, 30, 40, 15 },
		station = { position = Vector3.new(16, 1.5, 4) },
	},
	{
		id = "GodPack",
		displayName = "God Pack",
		description = "Top-tier paid pack with POTY dream odds.",
		cost = 0,
		futureCost = 85000000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 80,
		padWeight = 0,
		color = Color3.fromRGB(226, 248, 255),
		tierWeights = { 0, 0, 0, 6, 20, 48, 26 },
		station = { position = Vector3.new(16, 1.5, 4) },
	},
	{
		id = "GoatPack",
		displayName = "GOAT Pack",
		description = "End-game chase pack for massive Fans spenders.",
		cost = 0,
		futureCost = 115000000,
		shopBuyable = true,
		cardCount = 1,
		hitsRequired = 90,
		padWeight = 0,
		color = Color3.fromRGB(255, 208, 76),
		tierWeights = { 0, 0, 0, 2, 13, 48, 37 },
		station = { position = Vector3.new(24, 1.5, 4) },
	},
	{
		id = "TotyVaultPack",
		displayName = "TOTY Vault Pack",
		description = "Once every 2 days. Guaranteed Player of the Year.",
		cost = 0,
		futureCost = 250000000,
		shopBuyable = true,
		purchaseCooldownSeconds = 2 * 24 * 60 * 60,
		cardCount = 1,
		hitsRequired = 100,
		padWeight = 0,
		color = Color3.fromRGB(255, 232, 96),
		tierWeights = { 0, 0, 0, 0, 0, 0, 100 },
		station = { position = Vector3.new(24, 1.5, 4) },
	},
}

PackConfig.ById = {}
for _, pack in ipairs(PackConfig.ShopOrder) do
	PackConfig.ById[pack.id] = pack
end

function PackConfig.GetShopCost(packOrId)
	local pack = type(packOrId) == "table" and packOrId or PackConfig.ById[packOrId]
	return math.max(0, math.floor(tonumber(pack and (pack.shopCost or pack.futureCost)) or 0))
end

function PackConfig.IsShopBuyable(packId)
	local pack = PackConfig.ById[packId]
	return pack ~= nil and pack.shopBuyable == true and PackConfig.GetShopCost(pack) > 0
end

PackConfig.PadSpawnOrder = {}
for _, packId in ipairs(NATURAL_PACK_IDS) do
	local pack = PackConfig.ById[packId]
	if pack then
		table.insert(PackConfig.PadSpawnOrder, pack)
	end
end

-- ── Pack Spawn Luck ──────────────────────────────────────────
PackConfig.PackSpawnLuckKeyframes = {
	{
		level = 1,
		weights = {
			GoldPack = 92,
			RarePack = 7,
			PremiumPack = 1,
			JumboPack = 0,
			DeluxePack = 0,
			MythicPack = 0,
			GodPack = 0,
		},
	},
	{
		level = 10,
		weights = {
			GoldPack = 78,
			RarePack = 17,
			PremiumPack = 4,
			JumboPack = 1,
			DeluxePack = 0,
			MythicPack = 0,
			GodPack = 0,
		},
	},
	{
		level = 20,
		weights = {
			GoldPack = 55,
			RarePack = 25,
			PremiumPack = 13,
			JumboPack = 5,
			DeluxePack = 2,
			MythicPack = 0,
			GodPack = 0,
		},
	},
	{
		level = 35,
		weights = {
			GoldPack = 35,
			RarePack = 28,
			PremiumPack = 22,
			JumboPack = 10,
			DeluxePack = 5,
			MythicPack = 0,
			GodPack = 0,
		},
	},
	{
		level = 50,
		weights = {
			GoldPack = 20,
			RarePack = 25,
			PremiumPack = 28,
			JumboPack = 17,
			DeluxePack = 10,
			MythicPack = 0,
			GodPack = 0,
		},
	},
}

function PackConfig.GetPackSpawnWeights(packSpawnLuckLevel)
	local level = math.clamp(packSpawnLuckLevel or 1, 1, 50)
	local keyframes = PackConfig.PackSpawnLuckKeyframes
	local lower = keyframes[1]
	local upper = keyframes[#keyframes]

	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextFrame = keyframes[index + 1]
		if level >= current.level and level <= nextFrame.level then
			lower = current
			upper = nextFrame
			break
		end
	end

	if level <= keyframes[1].level then
		lower = keyframes[1]
		upper = keyframes[1]
	elseif level >= keyframes[#keyframes].level then
		lower = keyframes[#keyframes]
		upper = keyframes[#keyframes]
	end

	local span = math.max(1, upper.level - lower.level)
	local alpha = lower == upper and 0 or ((level - lower.level) / span)
	local weights = {}
	for _, pack in ipairs(PackConfig.ShopOrder) do
		local from = lower.weights[pack.id] or 0
		local to = upper.weights[pack.id] or from
		weights[pack.id] = from + ((to - from) * alpha)
	end

	weights.MythicPack = 0
	weights.GodPack = 0
	return weights
end

function PackConfig.ChooseSpawnPack(packSpawnLuckLevel)
	local weightsById = PackConfig.GetPackSpawnWeights(packSpawnLuckLevel)
	local packs = {}
	local weights = {}

	for _, pack in ipairs(PackConfig.PadSpawnOrder) do
		local weight = weightsById[pack.id] or 0
		if weight > 0 then
			table.insert(packs, pack)
			table.insert(weights, weight)
		end
	end

	local index = weightedIndex(weights)
	return index and packs[index] or PackConfig.ById.GoldPack
end

-- ── Card Pull Luck ───────────────────────────────────────────
-- Max-luck targets are deliberately conservative and preserve each pack's caps.
PackConfig.CardPullLuckTargets = {
	GoldPack = { 94.1, 5.2, 0.65, 0.05, 0, 0, 0 },
	RarePack = { 75, 20, 4.4, 0.6, 0, 0, 0 },
	PremiumPack = { 53, 29, 14.2, 3.4, 0.4, 0, 0 },
	JumboPack = { 42, 30, 18.5, 8.4, 1.1, 0, 0 },
	DeluxePack = { 32, 30, 23, 11, 3.4, 0.6, 0 },
	PlayerPickPack = { 76, 17, 5.5, 1.1, 0.32, 0.08, 0 },
	MegaPack = { 25, 28, 25, 13, 6, 2.4, 0.6 },
	ElitePack = { 10, 20, 32, 20, 11, 5.8, 1.2 },
	ChampionPack = { 2, 10, 24, 30, 21, 10, 3 },
	PrimePlayerPickPack = { 25, 22, 22, 15, 9, 5, 2 },
	MythicPack = { 0, 4, 17, 29, 28, 16, 6 },
	IconPack = { 0, 0, 7, 22, 34, 26, 11 },
	ElitePlayerPickPack = { 6, 16, 24, 20, 16, 11, 7 },
	ImmortalPack = { 0, 0, 2, 9, 27, 43, 19 },
	GodPack = { 0, 0, 0, 5, 18, 48, 29 },
	GoatPack = { 0, 0, 0, 1, 11, 48, 40 },
	TotyVaultPack = { 0, 0, 0, 0, 0, 0, 100 },
}

function PackConfig.GetBaseRarityOdds(packType)
	local pack = PackConfig.ById[packType]
	return copyArray(pack and pack.tierWeights or PackConfig.ById.GoldPack.tierWeights)
end

function PackConfig.ApplyCardPullLuck(baseOdds, cardPullLuckLevel, packType)
	local base = normalizeWeights(copyArray(baseOdds))
	local target = PackConfig.CardPullLuckTargets[packType]
	if not target then
		return base
	end

	local level = math.clamp(cardPullLuckLevel or 1, 1, 50)
	local alpha = ((level - 1) / 49) ^ 1.15
	local adjusted = {}
	for index = 1, #PackConfig.RarityOrder do
		local from = base[index] or 0
		local to = target[index] or from
		adjusted[index] = from + ((to - from) * alpha)
	end

	return normalizeWeights(adjusted)
end

local function getHighestAllowedRarityIndex(odds)
	local highest = 1
	for index, weight in ipairs(odds or {}) do
		if weight > 0 then
			highest = math.max(highest, index)
		end
	end
	return highest
end

local function chooseMinimumAllowedRarity(minRarity, odds, allowBeyondPackCap)
	local minIndex = PackConfig.RarityRank[minRarity] or 1
	if allowBeyondPackCap then
		return PackConfig.RarityOrder[minIndex] or "Gold"
	end

	local highestAllowed = getHighestAllowedRarityIndex(odds)
	local targetIndex = math.min(minIndex, highestAllowed)
	for index = targetIndex, highestAllowed do
		if odds[index] and odds[index] > 0 then
			return PackConfig.RarityOrder[index]
		end
	end
	return PackConfig.RarityOrder[highestAllowed] or "Gold"
end

function PackConfig.GetMilestoneGuarantee(packCount, milestones)
	local best
	for _, milestone in ipairs(milestones or {}) do
		local threshold = tonumber(milestone.threshold)
		if threshold and threshold > 0 and milestone.minRarity and packCount % threshold == 0 then
			local rank = PackConfig.RarityRank[milestone.minRarity] or 0
			local bestRank = best and (PackConfig.RarityRank[best.minRarity] or 0) or -1
			if rank > bestRank or (rank == bestRank and threshold > (best.threshold or 0)) then
				best = milestone
			end
		end
	end
	return best
end

function PackConfig.ChooseCardRarity(packType, cardPullLuckLevel, pityInfo)
	local baseOdds = PackConfig.GetBaseRarityOdds(packType)
	local odds = PackConfig.ApplyCardPullLuck(baseOdds, cardPullLuckLevel, packType)
	local index = weightedIndex(odds) or 1
	local rarity = PackConfig.RarityOrder[index] or "Gold"

	if pityInfo and pityInfo.minRarity then
		local currentRank = PackConfig.RarityRank[rarity] or 1
		local pityRank = PackConfig.RarityRank[pityInfo.minRarity] or currentRank
		if currentRank < pityRank then
			rarity = chooseMinimumAllowedRarity(pityInfo.minRarity, odds, pityInfo.allowBeyondPackCap)
		end
	end

	return rarity, odds
end

return PackConfig
