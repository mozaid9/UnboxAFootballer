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
		cardCount = 1,
		hitsRequired = 35,
		padWeight = 1,
		color = Color3.fromRGB(235, 56, 43),
		tierWeights = { 45, 30, 18, 6, 0.9, 0.1, 0 },
		station = { position = Vector3.new(-16, 1.5, 4) },
	},
	{
		id = "MythicPack",
		displayName = "Mythic Pack",
		description = "Future shop/event pack. Not a natural pad spawn.",
		cost = 0,
		futureCost = 200000,
		cardCount = 1,
		hitsRequired = 50,
		padWeight = 0,
		color = Color3.fromRGB(157, 80, 255),
		tierWeights = { 0, 30, 35, 20, 10, 3.5, 1.5 },
		station = { position = Vector3.new(0, 1.5, 4) },
	},
	{
		id = "GodPack",
		displayName = "God Pack",
		description = "Future shop/event pack. Not a natural pad spawn.",
		cost = 0,
		futureCost = 999999,
		cardCount = 1,
		hitsRequired = 80,
		padWeight = 0,
		color = Color3.fromRGB(226, 248, 255),
		tierWeights = { 0, 0, 25, 30, 20, 15, 10 },
		station = { position = Vector3.new(16, 1.5, 4) },
	},
}

PackConfig.ById = {}
for _, pack in ipairs(PackConfig.ShopOrder) do
	PackConfig.ById[pack.id] = pack
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
	MythicPack = { 0, 22, 34, 22, 13, 6, 3 },
	GodPack = { 0, 0, 18, 28, 23, 19, 12 },
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
		if threshold and threshold > 0 and packCount % threshold == 0 then
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
