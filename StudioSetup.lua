-- ============================================================
-- UNBOX A FOOTBALLER v3 -- PACK SETUP
-- Paste this ENTIRE script into the Roblox Studio Command Bar
-- and press Enter to install the current pack-opening prototype.
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

wipe("Shared", RS)
wipe("Remotes", RS)
wipe("Services", SSS)
wipe("Main", SSS)
wipe("DataService", SSS)
wipe("EconomyService", SSS)
wipe("PackService", SSS)
wipe("BaseService", SSS)
wipe("MarketService", SSS)
wipe("RebirthService", SSS)
wipe("TradeService", SSS)
wipe("PackOpeningUI", sps)
wipe("InventoryUI", sps)
wipe("HUDClient", sps)
wipe("ToolClient", sps)
wipe("ShopUI", sps)
wipe("TradeUI", sps)
wipe("MarketUI", sps)
wipe("BaseUI", sps)
wipe("CollectionUI", sps)
wipe("RebirthUI", sps)
wipe("Bat", STP)
wipe("Crates", workspace)
wipe("PackStations", workspace)

local shared = makeFolder("Shared", RS)

makeModule("Constants", shared, [==[
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

Constants.UI = {
	Background = Color3.fromRGB(7, 11, 20),
	Panel = Color3.fromRGB(14, 18, 31),
	PanelAlt = Color3.fromRGB(18, 23, 39),
	Gold = Color3.fromRGB(255, 215, 0),
	RareGold = Color3.fromRGB(255, 170, 48),
	Text = Color3.fromRGB(245, 238, 220),
	Muted = Color3.fromRGB(170, 165, 150),
	Success = Color3.fromRGB(78, 181, 105),
	Danger = Color3.fromRGB(180, 78, 58),
}

return Constants

]==])

makeModule("CardData", shared, [==[
-- ============================================================
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

]==])

makeModule("PackConfig", shared, [==[
local PackConfig = {}

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
		description = "3 Gold cards. Balanced odds and easy entry.",
		cost = 5000,
		cardCount = 3,
		color = Color3.fromRGB(255, 215, 0),
		displayRating = 80,
		station = {
			position = Vector3.new(-10, 1.5, -16),
		},
	},
	{
		id = "RareGoldPack",
		displayName = "Rare Gold Pack",
		description = "5 cards with one guaranteed 85+ Rare Gold pull.",
		cost = 10000,
		cardCount = 5,
		color = Color3.fromRGB(255, 168, 42),
		displayRating = 85,
		guaranteed = {
			minRating = 85,
			slotIndex = 5,
		},
		station = {
			position = Vector3.new(10, 1.5, -16),
		},
	},
}

PackConfig.ById = {}
for _, pack in ipairs(PackConfig.ShopOrder) do
	PackConfig.ById[pack.id] = pack
end

return PackConfig

]==])

makeModule("Utils", shared, [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

function Utils.GetRarityColor(rarity)
	if rarity == "Rare Gold" then
		return Constants.UI.RareGold
	end
	return Constants.UI.Gold
end

return Utils

]==])

makeModule("DataService", SSS, [==[
local DataStoreService = game:GetService("DataStoreService")
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
	totalCardsOpened = 0,
	totalRebirths = 0,
	collectionRewards = {},
}

local cache = {}
local dirtyPlayers = {}

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
		return false, "Not enough coins."
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
	return data.inventory
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

]==])

makeModule("EconomyService", SSS, [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

]==])

makeModule("PackService", SSS, [==[
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

function PackService.OpenPack(player, packId)
	if not DataService or not EconomyService then
		return false, { error = "Pack service not ready." }
	end

	local packDef = PackConfig.ById[packId]
	if not packDef then
		return false, { error = "Unknown pack." }
	end

	local data = DataService.GetData(player)
	if not data then
		return false, { error = "Your data is still loading." }
	end

	if packDef.isFree then
		local ok, err = EconomyService.ClaimFreePack(player)
		if not ok then
			return false, { error = err or "Free pack is not ready yet." }
		end
	else
		local ok, err = EconomyService.SpendCoins(player, packDef.cost)
		if not ok then
			return false, { error = err or "Not enough coins." }
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

		DataService.AddCard(player, card.id)
		table.insert(cards, serializeCard(card))
	end

	data.totalCardsOpened = (data.totalCardsOpened or 0) + #cards
	DataService.MarkDirty(player)

	if Remotes and Remotes.UpdateCoins then
		Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
	end

	return true, {
		success = true,
		packId = packId,
		packName = packDef.displayName,
		newCoins = DataService.GetCoins(player),
		cards = cards,
	}
end

return PackService

]==])

makeModule("BaseService", SSS, [==[
local BaseService = {}

local assignedPlots = {}
local nextPlotIndex = 1

function BaseService.AssignPlot(player)
	if assignedPlots[player] then
		return assignedPlots[player]
	end

	assignedPlots[player] = {
		plotId = nextPlotIndex,
		displaySlots = 6,
	}
	nextPlotIndex += 1
	return assignedPlots[player]
end

function BaseService.ReleasePlot(player)
	assignedPlots[player] = nil
end

function BaseService.GetPlot(player)
	return assignedPlots[player]
end

return BaseService

]==])

makeModule("MarketService", SSS, [==[
local MarketService = {}

function MarketService.ListCard()
	return false, "Transfer market has not been wired yet."
end

function MarketService.BuyListing()
	return false, "Transfer market has not been wired yet."
end

return MarketService

]==])

makeModule("RebirthService", SSS, [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardData = require(ReplicatedStorage.Shared.CardData)
local Constants = require(ReplicatedStorage.Shared.Constants)

local RebirthService = {}

local DataService

function RebirthService.Init(dataService)
	DataService = dataService
end

function RebirthService.GetRequiredCoins(rebirthTier)
	return math.floor(Constants.BaseRebirthCoinCost * (Constants.RebirthCostMultiplier ^ rebirthTier))
end

function RebirthService.CanRebirth(player)
	local data = DataService and DataService.GetData(player)
	if not data then
		return false, "Your data is still loading."
	end

	local requiredCoins = RebirthService.GetRequiredCoins(data.rebirthTier or 0)
	if (data.coins or 0) < requiredCoins then
		return false, "You need more coins."
	end

	for _, card in ipairs(CardData.Pool) do
		if (data.inventory[tostring(card.id)] or 0) <= 0 then
			return false, "You need every launch card before rebirthing."
		end
	end

	return true
end

return RebirthService

]==])

makeModule("TradeService", SSS, [==[
local TradeService = {}

function TradeService.RequestTrade()
	return false, "Trading has not been wired yet."
end

function TradeService.ValidateTrade()
	return false, "Trading has not been wired yet."
end

return TradeService

]==])

makeScript("Main", SSS, [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

if ServerScriptService:GetAttribute("UnboxMainBooted") then
	warn("[UnboxAFootballer] Duplicate Main detected, skipping older copy")
	return
end
ServerScriptService:SetAttribute("UnboxMainBooted", true)

for _, child in ipairs(ServerScriptService:GetChildren()) do
	if child:IsA("Script") and child ~= script and child.Name == script.Name then
		child.Disabled = true
	end
end

local Shared = ReplicatedStorage:WaitForChild("Shared")

local DataService = require(ServerScriptService:WaitForChild("DataService"))
local EconomyService = require(ServerScriptService:WaitForChild("EconomyService"))
local PackService = require(ServerScriptService:WaitForChild("PackService"))
local BaseService = require(ServerScriptService:WaitForChild("BaseService"))
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

local GetPlayerDataFn = makeFunction("GetPlayerData")
local OpenPackFn = makeFunction("OpenPack")
local SellCardFn = makeFunction("SellCard")
local SellAllCardsFn = makeFunction("SellAllCards")
local GetInventoryFn = makeFunction("GetInventory")

PackService.Init(DataService, EconomyService, {
	UpdateCoins = UpdateCoinsEvent,
	PackOpened = PackOpenedEvent,
	PackOpenFailed = PackOpenFailedEvent,
})
EconomyService.Init(DataService)
RebirthService.Init(DataService)

local stationsFolder = workspace:FindFirstChild("PackStations")
if stationsFolder then
	stationsFolder:Destroy()
end

stationsFolder = Instance.new("Folder")
stationsFolder.Name = "PackStations"
stationsFolder.Parent = workspace

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

local function buildPackModel(packDef)
	local model = Instance.new("Model")
	model.Name = packDef.id
	model.Parent = stationsFolder

	local base = Instance.new("Part")
	base.Name = "Pedestal"
	base.Anchored = true
	base.Size = Vector3.new(10, 1.5, 10)
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(16, 20, 32)
	base.CFrame = CFrame.new(packDef.station.position)
	base.Parent = model

	local baseAccent = Instance.new("Part")
	baseAccent.Name = "Accent"
	baseAccent.Anchored = true
	baseAccent.Size = Vector3.new(8, 0.25, 8)
	baseAccent.Material = Enum.Material.Neon
	baseAccent.Color = packDef.color
	baseAccent.CFrame = base.CFrame + Vector3.new(0, 0.9, 0)
	baseAccent.Parent = model

	local cardBody = Instance.new("Part")
	cardBody.Name = "PackBody"
	cardBody.Anchored = true
	cardBody.Material = Enum.Material.SmoothPlastic
	cardBody.Color = Color3.fromRGB(28, 22, 8)
	cardBody.Size = Vector3.new(0.3, 8, 5.4)
	cardBody.CFrame = base.CFrame * CFrame.new(0, 5.5, 0) * CFrame.Angles(0, math.rad(180), 0)
	cardBody.Parent = model

	local topCap = Instance.new("WedgePart")
	topCap.Name = "TopCap"
	topCap.Anchored = true
	topCap.Material = Enum.Material.SmoothPlastic
	topCap.Color = Color3.fromRGB(28, 22, 8)
	topCap.Size = Vector3.new(0.3, 1.4, 5.4)
	topCap.CFrame = cardBody.CFrame * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
	topCap.Parent = model

	local bottomCap = Instance.new("WedgePart")
	bottomCap.Name = "BottomCap"
	bottomCap.Anchored = true
	bottomCap.Material = Enum.Material.SmoothPlastic
	bottomCap.Color = Color3.fromRGB(20, 16, 6)
	bottomCap.Size = Vector3.new(0.3, 1.6, 5.4)
	bottomCap.CFrame = cardBody.CFrame * CFrame.new(0, -4.8, 0)
	bottomCap.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = packDef.color
	glow.Range = 14
	glow.Brightness = 2.5
	glow.Parent = cardBody

	createSurfaceLabel(Enum.NormalId.Front, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)
	createSurfaceLabel(Enum.NormalId.Back, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)

	local promptAttachment = Instance.new("Attachment")
	promptAttachment.Name = "PromptAttachment"
	promptAttachment.Position = Vector3.new(0, 4.6, 0)
	promptAttachment.Parent = base

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenPrompt"
	prompt.ActionText = "Open " .. packDef.displayName
	prompt.ObjectText = Utils.FormatNumber(packDef.cost) .. " Coins"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptAttachment

	local titleGui = Instance.new("BillboardGui")
	titleGui.Name = "TitleGui"
	titleGui.Size = UDim2.fromOffset(240, 84)
	titleGui.StudsOffset = Vector3.new(0, 8.7, 0)
	titleGui.AlwaysOnTop = true
	titleGui.Parent = base

	local titleFrame = Instance.new("Frame")
	titleFrame.Size = UDim2.fromScale(1, 1)
	titleFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	titleFrame.BackgroundTransparency = 0.15
	titleFrame.BorderSizePixel = 0
	titleFrame.Parent = titleGui

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 14)
	titleCorner.Parent = titleFrame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = packDef.color
	titleStroke.Thickness = 2
	titleStroke.Parent = titleFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -20, 0.56, 0)
	titleLabel.Position = UDim2.new(0, 10, 0.08, 0)
	titleLabel.Text = packDef.displayName
	titleLabel.TextColor3 = Color3.fromRGB(245, 238, 220)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Parent = titleFrame

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.new(1, -20, 0.26, 0)
	subtitle.Position = UDim2.new(0, 10, 0.62, 0)
	subtitle.Text = packDef.description
	subtitle.TextColor3 = Color3.fromRGB(191, 183, 160)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = titleFrame

	local tweenInfo = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(cardBody, tweenInfo, {
		CFrame = cardBody.CFrame * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, math.rad(4), 0),
	}):Play()

	prompt.Triggered:Connect(function(player)
		local ok, result = PackService.OpenPack(player, packDef.id)
		if ok then
			PackOpenedEvent:FireClient(player, result)
		else
			PackOpenFailedEvent:FireClient(player, result)
		end
	end)
end

for _, packDef in ipairs(PackConfig.ShopOrder) do
	buildPackModel(packDef)
end

Players.PlayerAdded:Connect(function(player)
	local data = DataService.LoadPlayer(player)
	BaseService.AssignPlot(player)
	EconomyService.EnsureStarterCoins(player)
	EconomyService.TryGrantDailyReward(player)
	task.defer(function()
		if player.Parent then
			UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			PromptPackShopEvent:FireClient(player, {
				message = "Walk to a pack stand and press E to open it.",
			})
		end
	end)
	return data
end)

Players.PlayerRemoving:Connect(function(player)
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

GetPlayerDataFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return nil
	end

	return {
		coins = data.coins,
		gems = data.gems or 0,
		rebirthTier = data.rebirthTier or 0,
		totalCardsOpened = data.totalCardsOpened or 0,
		canClaimFreePack = EconomyService.CanClaimFreePack(player),
		freePackRemaining = EconomyService.GetFreePackRemaining(player),
		inventoryCounts = data.inventory,
	}
end

GetInventoryFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return {}
	end

	local inventory = {}
	for key, amount in pairs(data.inventory) do
		local cardId = tonumber(key)
		local card = cardId and CardData.ById[cardId]
		if card and amount > 0 then
			table.insert(inventory, {
				id = card.id,
				name = card.name,
				nation = card.nation,
				position = card.position,
				rating = card.rating,
				rarity = card.rarity,
				quantity = amount,
				sellValue = Utils.GetSellValue(card.rating),
			})
		end
	end

	table.sort(inventory, function(a, b)
		if a.rating == b.rating then
			return a.name < b.name
		end
		return a.rating > b.rating
	end)

	return inventory
end

OpenPackFn.OnServerInvoke = function(player, packId)
	local ok, result = PackService.OpenPack(player, packId)
	if ok then
		return result
	end

	return {
		success = false,
		error = result and result.error or "Could not open pack.",
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
	end

	return {
		success = true,
		coinsEarned = total,
		newCoins = DataService.GetCoins(player),
	}
end

print("[UnboxAFootballer] Pack systems ready")

]==])

makeLocal("PackOpeningUI", sps, [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
local PackConfig = require(Shared:WaitForChild("PackConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local OpenPackFn = Remotes:WaitForChild("OpenPack")
local SellCardFn = Remotes:WaitForChild("SellCard")
local SellAllCardsFn = Remotes:WaitForChild("SellAllCards")
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
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local topBar = make("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 96),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
}, screenGui)

local topRightDock = make("Frame", {
	Name = "TopRightDock",
	Size = UDim2.fromOffset(386, 48),
	Position = UDim2.new(1, -18, 0, 16),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
}, topBar)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 12),
}, topRightDock)

local coinPill = make("Frame", {
	LayoutOrder = 2,
	Size = UDim2.fromOffset(184, 48),
	BackgroundColor3 = UI.Panel,
}, topRightDock)
addCorner(coinPill, 14)
addStroke(coinPill, UI.Gold, 2, 0.15)

local coinGradient = make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 24, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
	}),
	Rotation = 90,
}, coinPill)

local coinIcon = make("TextLabel", {
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.new(0, 10, 0.5, -14),
	BackgroundColor3 = Color3.fromRGB(35, 30, 10),
	Text = "C",
	TextColor3 = UI.Gold,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, coinPill)
addCorner(coinIcon, 9)

local coinTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 48, 0, 4),
	Size = UDim2.new(1, -56, 0, 12),
	Text = "Coins",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local coinsLabel = make("TextLabel", {
	Name = "CoinsLabel",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 48, 0, 15),
	Size = UDim2.new(1, -56, 0, 22),
	Text = "0",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local openShopButton = make("TextButton", {
	LayoutOrder = 1,
	Size = UDim2.fromOffset(190, 48),
	BackgroundColor3 = UI.Gold,
	Text = "Pack Shop",
	TextColor3 = Color3.fromRGB(20, 14, 8),
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, topRightDock)
addCorner(openShopButton, 14)

local hintLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0.4, 0, 0, 20),
	Position = UDim2.new(0.5, 0, 0, 70),
	AnchorPoint = Vector2.new(0.5, 0),
	Text = "Walk to a pack stand and press E to open packs.",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
}, topBar)

local shopScreen = make("Frame", {
	Name = "ShopScreen",
	Visible = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = UI.Background,
	BackgroundTransparency = 0.08,
}, screenGui)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(7, 10, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 12, 28)),
	}),
	Rotation = 140,
}, shopScreen)

local shopPanel = make("Frame", {
	Size = UDim2.new(0.86, 0, 0.68, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = UI.Panel,
}, shopScreen)
addCorner(shopPanel, 24)
addStroke(shopPanel, UI.Gold, 2, 0.6)

local shopTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 0, 18),
	Size = UDim2.new(0.5, 0, 0, 34),
	Text = "Choose A Pack",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, shopPanel)

local shopSubTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 0, 54),
	Size = UDim2.new(0.55, 0, 0, 18),
	Text = "Server-rolled odds. Higher rebirth tiers boost luck.",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, shopPanel)

local closeShopButton = make("TextButton", {
	Size = UDim2.fromOffset(46, 46),
	Position = UDim2.new(1, -24, 0, 24),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = Color3.fromRGB(42, 28, 28),
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, shopPanel)
addCorner(closeShopButton, 14)

local shopStatus = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 1, -40),
	Size = UDim2.new(1, -56, 0, 20),
	Text = "",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, shopPanel)

local packRow = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.04, 0, 0.18, 0),
	Size = UDim2.new(0.92, 0, 0.62, 0),
}, shopPanel)

local packLayout = make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 26),
}, packRow)

local revealScreen = make("Frame", {
	Name = "RevealScreen",
	Visible = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = UI.Background,
}, screenGui)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 12, 22)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 17, 28)),
	}),
	Rotation = 120,
}, revealScreen)

local revealTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0, 26),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.6, 0, 0, 42),
	Text = "Pack Reveal",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, revealScreen)

local revealSubTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0, 66),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.7, 0, 0, 18),
	Text = "Cards flip one by one. Rare Gold pulls hit brighter.",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
}, revealScreen)

local cardContainer = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0.48, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.94, 0, 0.48, 0),
}, revealScreen)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 18),
}, cardContainer)

local actionRow = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 1, -86),
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(420, 54),
}, revealScreen)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 18),
}, actionRow)

local storeAllButton = make("TextButton", {
	Visible = false,
	Size = UDim2.fromOffset(190, 52),
	BackgroundColor3 = UI.Success,
	Text = "Store All",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, actionRow)
addCorner(storeAllButton, 16)

local sellAllButton = make("TextButton", {
	Visible = false,
	Size = UDim2.fromOffset(190, 52),
	BackgroundColor3 = UI.Danger,
	Text = "Quick Sell All",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, actionRow)
addCorner(sellAllButton, 16)

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

local currentCards = {}
local soldIndexes = {}
local isRevealing = false
local packButtons = {}

local function setCoinsDisplay(coins)
	coinsLabel.Text = Utils.FormatNumber(coins)
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

local function clearCards()
	for _, child in ipairs(cardContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	table.clear(currentCards)
	table.clear(soldIndexes)
end

local function buildPackButton(packDef)
	local frame = make("Frame", {
		BackgroundColor3 = UI.PanelAlt,
		Size = UDim2.fromOffset(250, 330),
	}, packRow)
	addCorner(frame, 22)
	addStroke(frame, packDef.color, 2, 0.4)

	local shine = make("Frame", {
		BackgroundColor3 = packDef.color,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Position = UDim2.new(0.57, 0, 0.06, 0),
		Rotation = -18,
		Size = UDim2.new(0.28, 0, 0.52, 0),
	}, frame)

	local packArt = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(196, 156, 40),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.39, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(104, 168),
	}, frame)
	addCorner(packArt, 8)
	addStroke(packArt, Color3.fromRGB(35, 28, 8), 3, 0)

	local packHighlight = make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 246, 188)),
			ColorSequenceKeypoint.new(0.4, packDef.color),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 90, 16)),
		}),
		Rotation = 20,
	}, packArt)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.06, 0),
		Size = UDim2.new(0.36, 0, 0.18, 0),
		Text = tostring(packDef.displayRating),
		TextColor3 = Color3.fromRGB(24, 20, 8),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, packArt)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.68, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.86, 0, 0.18, 0),
		Text = packDef.displayName,
		TextColor3 = Color3.fromRGB(50, 38, 12),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, packArt)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.08, 0),
		Size = UDim2.new(0.84, 0, 0.12, 0),
		Text = packDef.displayName,
		TextColor3 = UI.Text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, frame)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.74, 0),
		Size = UDim2.new(0.84, 0, 0.1, 0),
		Text = packDef.description,
		TextWrapped = true,
		TextColor3 = UI.Muted,
		TextScaled = true,
		Font = Enum.Font.GothamMedium,
	}, frame)

	local button = make("TextButton", {
		BackgroundColor3 = packDef.color,
		Size = UDim2.new(0.84, 0, 0, 44),
		Position = UDim2.new(0.08, 0, 1, -58),
		Text = Utils.FormatNumber(packDef.cost) .. " Coins",
		TextColor3 = Color3.fromRGB(20, 14, 8),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, frame)
	addCorner(button, 14)

	packButtons[packDef.id] = button
	return button
end

for _, packDef in ipairs(PackConfig.ShopOrder) do
	buildPackButton(packDef)
end

local function buildCard(cardData, cardIndex)
	local outer = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(15, 19, 30),
		Size = UDim2.fromOffset(156, 244),
		ClipsDescendants = true,
	}, cardContainer)
	addCorner(outer, 18)

	local border = addStroke(outer, UI.Gold, 2, 0.45)
	local accent = Utils.GetRarityColor(cardData.rarity)

	local back = make("Frame", {
		Name = "Back",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(22, 28, 42),
	}, outer)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 32, 48)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
		}),
		Rotation = 90,
	}, back)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "?",
		TextColor3 = UI.Gold,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, back)

	local front = make("Frame", {
		Name = "Front",
		Visible = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(70, 54, 14),
	}, outer)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 244, 186)),
			ColorSequenceKeypoint.new(0.4, accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(111, 83, 15)),
		}),
		Rotation = 22,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.05, 0),
		Size = UDim2.new(0.28, 0, 0.16, 0),
		Text = tostring(cardData.rating),
		TextColor3 = Color3.fromRGB(20, 15, 7),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.18, 0),
		Size = UDim2.new(0.24, 0, 0.08, 0),
		Text = cardData.position,
		TextColor3 = Color3.fromRGB(46, 36, 12),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.12, 0, 0.54, 0),
		Size = UDim2.new(0.76, 0, 0.14, 0),
		Text = cardData.name,
		TextColor3 = Color3.fromRGB(28, 21, 9),
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.12, 0, 0.72, 0),
		Size = UDim2.new(0.76, 0, 0.08, 0),
		Text = cardData.nation,
		TextColor3 = Color3.fromRGB(52, 42, 14),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.83, 0),
		Size = UDim2.new(0.84, 0, 0.08, 0),
		Text = cardData.rarity,
		TextColor3 = Color3.fromRGB(56, 43, 12),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, front)

	local sellButton = make("TextButton", {
		Visible = false,
		BackgroundColor3 = UI.Danger,
		Size = UDim2.new(0.82, 0, 0, 34),
		Position = UDim2.new(0.09, 0, 1, -44),
		Text = "Sell " .. Utils.FormatNumber(cardData.sellValue),
		TextColor3 = UI.Text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, outer)
	addCorner(sellButton, 12)

	local function flip()
		local collapse = TweenService:Create(outer, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(12, 244),
		})
		collapse:Play()
		collapse.Completed:Wait()
		back.Visible = false
		front.Visible = true
		local expand = TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(156, 244),
		})
		expand:Play()
		TweenService:Create(border, TweenInfo.new(0.25), {
			Color = accent,
			Transparency = 0,
			Thickness = cardData.rarity == "Rare Gold" and 3 or 2,
		}):Play()
		sellButton.Visible = true
		if cardData.rarity == "Rare Gold" then
			showToast("Rare pull: " .. cardData.name .. " (" .. cardData.rating .. ")", accent)
		end
	end

	sellButton.MouseButton1Click:Connect(function()
		if soldIndexes[cardIndex] then
			return
		end
		local response = SellCardFn:InvokeServer(cardData.id)
		if response and response.success then
			soldIndexes[cardIndex] = true
			sellButton.Visible = false
			outer.BackgroundTransparency = 0.35
			setCoinsDisplay(response.newCoins)
		end
	end)

	return flip
end

local function refreshStatus()
	local data = GetPlayerDataFn:InvokeServer()
	if not data then
		return
	end

	setCoinsDisplay(data.coins)
	if data.canClaimFreePack then
		shopStatus.Text = "Free pack is ready."
		shopStatus.TextColor3 = UI.Success
	else
		shopStatus.Text = "Free pack cooldown: " .. Utils.FormatCountdown(data.freePackRemaining or 0)
		shopStatus.TextColor3 = UI.Muted
	end
end

local function runReveal(payload)
	isRevealing = true
	clearCards()
	revealTitle.Text = payload.packName
	revealSubTitle.Text = "Sound hooks: FlipSFX on each card, RarePullSFX for Rare Gold cards."
	revealScreen.Visible = true
	storeAllButton.Visible = false
	sellAllButton.Visible = false

	for _, card in ipairs(payload.cards) do
		table.insert(currentCards, card)
	end

	local flips = {}
	for index, card in ipairs(currentCards) do
		flips[index] = buildCard(card, index)
	end

	task.spawn(function()
		for index, flip in ipairs(flips) do
			task.wait(0.45)
			flip()
		end
		task.wait(0.35)
		storeAllButton.Visible = true
		sellAllButton.Visible = true
		isRevealing = false
	end)
end

local function openPack(packId)
	if isRevealing then
		return
	end

	local response = OpenPackFn:InvokeServer(packId)
	if response and response.success then
		shopScreen.Visible = false
		setCoinsDisplay(response.newCoins)
		runReveal(response)
	else
		shopStatus.Text = response and response.error or "Could not open pack."
		shopStatus.TextColor3 = UI.Danger
	end
end

for packId, button in pairs(packButtons) do
	button.MouseButton1Click:Connect(function()
		openPack(packId)
	end)
end

openShopButton.MouseButton1Click:Connect(function()
	refreshStatus()
	shopScreen.Visible = true
end)

closeShopButton.MouseButton1Click:Connect(function()
	shopScreen.Visible = false
end)

storeAllButton.MouseButton1Click:Connect(function()
	if isRevealing then
		return
	end
	revealScreen.Visible = false
	clearCards()
end)

sellAllButton.MouseButton1Click:Connect(function()
	if isRevealing then
		return
	end

	local toSell = {}
	for index, card in ipairs(currentCards) do
		if not soldIndexes[index] then
			table.insert(toSell, card.id)
		end
	end

	local response = SellAllCardsFn:InvokeServer(toSell)
	if response and response.success then
		setCoinsDisplay(response.newCoins)
	end

	revealScreen.Visible = false
	clearCards()
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins)
	setCoinsDisplay(coins)
end)

PackOpenedEvent.OnClientEvent:Connect(function(payload)
	if payload and payload.success then
		setCoinsDisplay(payload.newCoins)
		runReveal(payload)
	end
end)

PackOpenFailedEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end
	showToast(payload.error or "Pack could not be opened.", UI.Danger)
	shopStatus.Text = payload.error or "Pack could not be opened."
	shopStatus.TextColor3 = UI.Danger
end)

PromptPackShopEvent.OnClientEvent:Connect(function(payload)
	if payload and payload.message then
		hintLabel.Text = payload.message
	end
end)

openShopButton.MouseEnter:Connect(function()
	TweenService:Create(openShopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(255, 229, 70),
	}):Play()
end)

openShopButton.MouseLeave:Connect(function()
	TweenService:Create(openShopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = UI.Gold,
	}):Play()
end)

task.spawn(function()
	task.wait(1)
	refreshStatus()
end)

]==])

makeLocal("InventoryUI", sps, [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetInventoryFn = Remotes:WaitForChild("GetInventory")

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
}, playerGui)

local toggle = make("TextButton", {
	Size = UDim2.fromOffset(132, 40),
	Position = UDim2.new(0, 18, 0, 76),
	BackgroundColor3 = Constants.UI.Panel,
	Text = "Inventory",
	TextColor3 = Constants.UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBold,
}, screenGui)
addCorner(toggle, 14)

local panel = make("Frame", {
	Visible = false,
	Size = UDim2.new(0, 560, 0, 440),
	Position = UDim2.new(0, 18, 0, 124),
	BackgroundColor3 = Constants.UI.Panel,
}, screenGui)
addCorner(panel, 18)

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 36),
	Position = UDim2.new(0, 12, 0, 10),
	Text = "Club Inventory",
	TextColor3 = Constants.UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local scrolling = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -24, 1, -64),
	Position = UDim2.new(0, 12, 0, 52),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, panel)

local layout = make("UIGridLayout", {
	CellSize = UDim2.fromOffset(120, 148),
	CellPadding = UDim2.fromOffset(12, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scrolling)

local function clearEntries()
	for _, child in ipairs(scrolling:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function refreshInventory()
	clearEntries()
	local inventory = GetInventoryFn:InvokeServer() or {}

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
			Position = UDim2.new(0.08, 0, 0.8, 0),
			Size = UDim2.new(0.84, 0, 0.12, 0),
			Text = "x" .. tostring(card.quantity) .. " • Sell " .. Utils.FormatNumber(card.sellValue),
			TextColor3 = Utils.GetRarityColor(card.rarity),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, tile)
	end

	task.defer(function()
		scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

toggle.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refreshInventory()
	end
end)

]==])

print("[UnboxAFootballer] v3 pack setup complete")
print("Press Play, walk to a pack stand, and press E to open packs.")
