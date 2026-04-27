local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardData   = require(ReplicatedStorage.Shared.CardData)
local PackConfig = require(ReplicatedStorage.Shared.PackConfig)
local Utils      = require(ReplicatedStorage.Shared.Utils)

local PackService = {}

local DataService
local EconomyService
local Remotes

function PackService.Init(dataService, economyService, remotes)
	DataService    = dataService
	EconomyService = economyService
	Remotes        = remotes
end

-- ── Rarity tier helpers ──────────────────────────────────────

-- Maps a rarity string to its tier index in PackConfig.WeightTiers.
local rarityToTierIndex = {}
for i, tier in ipairs(PackConfig.WeightTiers) do
	for _, rarityName in ipairs(tier.rarities) do
		rarityToTierIndex[rarityName] = i
	end
end

-- Returns the pool of cards that belong to a given WeightTier.
local function getCardsForTier(tier)
	local raritySet = {}
	for _, r in ipairs(tier.rarities) do
		raritySet[r] = true
	end

	local results = {}
	for _, card in ipairs(CardData.Pool) do
		if raritySet[card.rarity] then
			table.insert(results, card)
		end
	end
	return results
end

-- Returns all cards whose rarity is >= minRarity (by tier index).
local function getCardsAboveMinRarity(minRarity)
	local minIndex = rarityToTierIndex[minRarity] or 1
	local results  = {}
	for _, card in ipairs(CardData.Pool) do
		local cardIndex = rarityToTierIndex[card.rarity] or 1
		if cardIndex >= minIndex then
			table.insert(results, card)
		end
	end
	return results
end

-- ── Weight adjustment (rebirth luck) ─────────────────────────
-- Shifts weight from lower tiers toward higher tiers based on
-- how many rebirth levels the player has.
local function buildAdjustedWeights(baseWeights, rebirthTier)
	local weights = {}
	for i, w in ipairs(baseWeights) do
		weights[i] = w
	end

	local upwardShift = math.min(rebirthTier or 0, PackConfig.MaxLuckShift)
	while upwardShift > 0 do
		for tierIndex = 1, #weights - 1 do
			if upwardShift <= 0 then
				break
			end
			local floor        = PackConfig.WeightFloorPerTier[tierIndex] or 0
			local transferable = math.min(weights[tierIndex] - floor, 1)
			if transferable > 0 then
				weights[tierIndex]     = weights[tierIndex] - transferable
				weights[tierIndex + 1] = weights[tierIndex + 1] + transferable
				upwardShift            = upwardShift - transferable
			end
		end
		-- Break if we can't shift anything further
		local canShift = false
		for tierIndex = 1, #weights - 1 do
			local floor = PackConfig.WeightFloorPerTier[tierIndex] or 0
			if weights[tierIndex] - floor >= 1 then
				canShift = true
				break
			end
		end
		if not canShift then
			break
		end
	end

	return weights
end

-- ── Card selection ────────────────────────────────────────────

local function chooseRandomCard(pool)
	if #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

-- Roll one card using the weighted tier table.
local function rollCard(weights)
	local tierIndex = Utils.WeightedRandom(weights)
	local tier      = PackConfig.WeightTiers[tierIndex]
	local candidates = getCardsForTier(tier)
	if #candidates == 0 then
		-- Fallback: anything from the pool
		candidates = CardData.Pool
	end
	return chooseRandomCard(candidates)
end

-- Roll a guaranteed card that is at least minRarity.
local function rollGuaranteed(minRarity)
	local candidates = getCardsAboveMinRarity(minRarity)
	if #candidates == 0 then
		candidates = CardData.Pool
	end
	return chooseRandomCard(candidates)
end

-- ── Serialise ─────────────────────────────────────────────────

local function serializeCard(card)
	return {
		id         = card.id,
		name       = card.name,
		nation     = card.nation,
		position   = card.position,
		rating     = card.rating,
		rarity     = card.rarity,
		club       = card.club,
		sellValue  = Utils.GetSellValue(card.rating),
		marketFloor = Utils.GetMarketFloor(card.rating),
	}
end

-- ── Public API ────────────────────────────────────────────────

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

	-- Cost handling
	if options.ignoreCost then
		-- Base pad spawns are free during early access.
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

	-- Build the per-pack weight table, then apply rebirth luck shift.
	local baseWeights = packDef.tierWeights
	if not baseWeights then
		-- Fallback: equal weight across all tiers
		baseWeights = {}
		for i = 1, #PackConfig.WeightTiers do
			baseWeights[i] = PackConfig.WeightTiers[i].weight or 0
		end
	end
	local weights = buildAdjustedWeights(baseWeights, data.rebirthTier or 0)

	-- Roll cards
	local cards = {}
	for slot = 1, packDef.cardCount do
		local card
		if packDef.guaranteed and slot == 1 then
			-- First slot is always the guaranteed roll.
			card = rollGuaranteed(packDef.guaranteed.minRarity)
		else
			card = rollCard(weights)
		end

		if not card then
			return false, { error = "Pack roll failed. Please try again." }
		end

		table.insert(cards, serializeCard(card))
	end

	-- Update stats
	data.totalCardsOpened = (data.totalCardsOpened or 0) + #cards
	data.totalPacksOpened = (data.totalPacksOpened or 0) + 1
	DataService.MarkDirty(player)

	if Remotes and Remotes.UpdateCoins then
		Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
	end

	return true, {
		success   = true,
		packId    = packId,
		packName  = packDef.displayName,
		isFree    = options.ignoreCost == true or packDef.cost == 0,
		newCoins  = DataService.GetCoins(player),
		card      = cards[1],
		cards     = cards,
	}
end

return PackService
