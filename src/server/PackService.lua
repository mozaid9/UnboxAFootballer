local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
