local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardData   = require(ReplicatedStorage.Shared.CardData)
local Constants  = require(ReplicatedStorage.Shared.Constants)
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

-- ── Card selection ────────────────────────────────────────────

local function chooseRandomCard(pool)
	if #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

local function getCardsForRarity(rarity, minPowerScore)
	local results = {}
	for _, card in ipairs(CardData.Pool) do
		if card.rarity == rarity and ((tonumber(minPowerScore) or 0) <= 0 or Utils.GetPowerScore(card) >= minPowerScore) then
			table.insert(results, card)
		end
	end
	return results
end

local function getCardsAtOrAbovePower(minPowerScore)
	local results = {}
	for _, card in ipairs(CardData.Pool) do
		if Utils.GetPowerScore(card) >= minPowerScore then
			table.insert(results, card)
		end
	end
	return results
end

function PackService.ChooseCardVariant(rarity)
	local candidates = getCardsForRarity(rarity)
	if #candidates == 0 then
		candidates = getCardsForRarity("Gold")
	end
	return chooseRandomCard(candidates)
end

-- ── Serialise ─────────────────────────────────────────────────

local function serializeCard(card)
	return {
		id = card.id,
		name = card.name,
		nation = card.nation,
		position = card.position,
		rarity = card.rarity,
		club = card.club,
		fansPerSecond = Utils.CalculateFansPerSecond(card),
		sellValue = Utils.GetSellValue(card),
		marketFloor = Utils.GetMarketFloor(card),
	}
end

local function choosePlayerPickCard(packId, cardPullLuckLevel, minPowerScore)
	local rarity = PackService.ChooseCardRarity(packId, cardPullLuckLevel)
	local candidates = getCardsForRarity(rarity, minPowerScore)
	if #candidates == 0 then
		candidates = getCardsAtOrAbovePower(minPowerScore)
	end
	if #candidates == 0 then
		candidates = CardData.Pool
	end
	return chooseRandomCard(candidates)
end

function PackService.RollPlayerPickOptions(packId, cardPullLuckLevel)
	local packDef = PackConfig.ById[packId]
	local pickConfig = packDef and packDef.playerPick
	if type(pickConfig) ~= "table" then
		return {}
	end

	local optionCount = math.clamp(math.floor(tonumber(pickConfig.optionCount) or 3), 2, 5)
	local minPowerScore = math.max(0, math.floor(tonumber(pickConfig.minPowerScore) or 0))
	local options = {}
	local usedCardIds = {}
	local attempts = 0
	local maxAttempts = optionCount * 40

	while #options < optionCount and attempts < maxAttempts do
		attempts += 1
		local card = choosePlayerPickCard(packId, cardPullLuckLevel, minPowerScore)
		if card and not usedCardIds[card.id] then
			usedCardIds[card.id] = true
			table.insert(options, serializeCard(card))
		end
	end

	if #options == 0 then
		local fallback = chooseRandomCard(CardData.Pool)
		if fallback then
			table.insert(options, serializeCard(fallback))
		end
	end

	return options
end

local function getCardPullLuckLevel(data)
	local upgrades = data and data.upgrades or {}
	return upgrades.CardPullLuck or 1
end

local function getPityInfoForNextPack(data, options)
	local nextPackCount = (data.totalPacksOpened or data.totalCardsOpened or 0) + 1
	if options and options.milestoneGuarantee then
		return options.milestoneGuarantee, nextPackCount
	end
	return nil, nextPackCount
end

-- ── Public API ────────────────────────────────────────────────

function PackService.GetBaseRarityOdds(packType)
	return PackConfig.GetBaseRarityOdds(packType)
end

function PackService.ApplyCardPullLuck(baseOdds, cardPullLuckLevel, packType)
	return PackConfig.ApplyCardPullLuck(baseOdds, cardPullLuckLevel, packType)
end

function PackService.ChooseCardRarity(packType, cardPullLuckLevel, pityInfo)
	return PackConfig.ChooseCardRarity(packType, cardPullLuckLevel, pityInfo)
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

	-- Cost handling
	if options.ignoreCost then
		-- Base pad spawns and scripted rewards are free.
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

	local pityInfo, nextPackCount = getPityInfoForNextPack(data, options)
	local cardPullLuckLevel = math.clamp(getCardPullLuckLevel(data) + math.floor(tonumber(options.cardPullLuckBonus) or 0), 1, 50)
	if type(packDef.playerPick) == "table" then
		local pickOptions = PackService.RollPlayerPickOptions(packId, cardPullLuckLevel)
		if #pickOptions == 0 then
			return false, { error = "Player pick failed. Please try again." }
		end

		data.totalPacksOpened = (data.totalPacksOpened or 0) + 1
		DataService.MarkDirty(player)

		if Remotes and Remotes.UpdateCoins then
			Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
		end

		return true, {
			success = true,
			playerPick = true,
			packId = packId,
			packName = packDef.displayName,
			isFree = options.ignoreCost == true or packDef.cost == 0,
			newCoins = DataService.GetCoins(player),
			pickOptions = pickOptions,
			cardPullLuckLevel = cardPullLuckLevel,
			pityInfo = pityInfo,
			packCount = nextPackCount,
		}
	end

	local rarity = PackService.ChooseCardRarity(packId, cardPullLuckLevel, pityInfo)
	local card = PackService.ChooseCardVariant(rarity)
	if not card then
		return false, { error = "Pack roll failed. Please try again." }
	end

	local serializedCard = serializeCard(card)

	-- Update stats
	data.totalCardsOpened = (data.totalCardsOpened or 0) + 1
	data.totalPacksOpened = (data.totalPacksOpened or 0) + 1
	if type(DataService.RecordCardPacked) == "function" then
		DataService.RecordCardPacked(player, card.id)
	end
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
		card = serializedCard,
		cards = { serializedCard },
		cardPullLuckLevel = cardPullLuckLevel,
		pityInfo = pityInfo,
		packCount = nextPackCount,
	}
end

-- ── Debug simulations ─────────────────────────────────────────

function PackService.SimulatePackOpens(packType, cardPullLuckLevel, amount)
	amount = math.max(1, math.floor(amount or 1000))
	packType = packType or "GoldPack"
	cardPullLuckLevel = cardPullLuckLevel or 1

	local result = {
		packType = packType,
		cardPullLuckLevel = cardPullLuckLevel,
		amount = amount,
		countsByRarity = {},
		exampleCards = {},
	}

	for _ = 1, amount do
		local rarity = PackService.ChooseCardRarity(packType, cardPullLuckLevel)
		local card = PackService.ChooseCardVariant(rarity)
		result.countsByRarity[rarity] = (result.countsByRarity[rarity] or 0) + 1
		if card and not result.exampleCards[rarity] then
			result.exampleCards[rarity] = card.name .. " (" .. card.position .. ", " .. card.nation .. ")"
		end
	end

	print("[PackService] Pull simulation:", packType, "CardPullLuck", cardPullLuckLevel, "opens", amount)
	for _, rarity in ipairs(PackConfig.RarityOrder) do
		print(rarity, result.countsByRarity[rarity] or 0, result.exampleCards[rarity] or "-")
	end

	return result
end

function PackService.SimulatePackSpawns(packSpawnLuckLevel, amount)
	amount = math.max(1, math.floor(amount or 1000))
	packSpawnLuckLevel = packSpawnLuckLevel or 1

	local result = {
		packSpawnLuckLevel = packSpawnLuckLevel,
		amount = amount,
		countsByPackType = {},
		weights = PackConfig.GetPackSpawnWeights(packSpawnLuckLevel),
	}

	for _ = 1, amount do
		local pack = PackConfig.ChooseSpawnPack(packSpawnLuckLevel)
		local packName = pack and pack.displayName or "Unknown"
		result.countsByPackType[packName] = (result.countsByPackType[packName] or 0) + 1
	end

	print("[PackService] Spawn simulation:", "PackSpawnLuck", packSpawnLuckLevel, "spawns", amount)
	for _, pack in ipairs(PackConfig.ShopOrder) do
		print(pack.displayName, result.countsByPackType[pack.displayName] or 0, "weight", result.weights[pack.id] or 0)
	end

	return result
end

return PackService
