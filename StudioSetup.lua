-- ============================================================
-- UNBOX A FOOTBALLER v5 -- PITCHFORK PAD SETUP
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
wipe("Pitchfork", STP)
wipe("Bat", STP)
wipe("Crates", workspace)
wipe("PackStations", workspace)
wipe("PlayerBases", workspace)

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

Constants.BaseLayout = {
	MaxPlots = 6,
	PlotsPerSide = 3,
	SideOffset = 88,
	StartZ = -96,
	PlotSpacing = 96,
	PlotSize = Vector3.new(56, 1, 44),
	FenceHeight = 6,
	PackPadSize = Vector3.new(16, 0.6, 16),
	DisplaySlotCount = 6,
	DisplaySlotSize = Vector3.new(7, 3.5, 7),
}

Constants.Pitchfork = {
	BaseDamage = 1,
	SwingCooldown = 0.42,
	HitRange = 24,
}

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
		cost = 0,
		futureCost = 5000,
		cardCount = 3,
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
		description = "5 cards with one guaranteed 85+ Rare Gold pull.",
		cost = 0,
		futureCost = 10000,
		cardCount = 5,
		hitsRequired = 4,
		padWeight = 20,
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
	{
		id = "PremiumGoldPack",
		displayName = "Premium Gold Pack",
		description = "5 cards with a guaranteed 88+ premium pull.",
		cost = 0,
		futureCost = 18000,
		cardCount = 5,
		hitsRequired = 5,
		padWeight = 6,
		color = Color3.fromRGB(255, 118, 58),
		displayRating = 88,
		guaranteed = {
			minRating = 88,
			slotIndex = 5,
		},
	},
}

PackConfig.ById = {}
for _, pack in ipairs(PackConfig.ShopOrder) do
	PackConfig.ById[pack.id] = pack
end

PackConfig.PadSpawnOrder = PackConfig.ShopOrder

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
	pitchforkPower = 1,
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
		isFree = options.ignoreCost == true or packDef.cost == 0,
		newCoins = DataService.GetCoins(player),
		cards = cards,
	}
end

return PackService
]==])

makeModule("BaseService", SSS, [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)

local BaseService = {}

local layout = Constants.BaseLayout
local basesFolder
local plots = {}
local assignedPlots = {}

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
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

local function updateOwnerSign(plot, ownerName, subtitle)
	plot.ownerNameLabel.Text = ownerName
	plot.ownerSubtitleLabel.Text = subtitle
end

local function updatePadLabel(plot, title, subtitle, color)
	plot.padTitleLabel.Text = title
	plot.padSubtitleLabel.Text = subtitle
	plot.padAccent.BackgroundColor3 = color
end

local function createFence(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(120, 84, 40),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createDisplaySlot(parent, index, cframe)
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
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(46, 205, 113),
		Size = Vector3.new(layout.DisplaySlotSize.X - 1.4, 0.18, layout.DisplaySlotSize.Z - 1.4),
		CFrame = base.CFrame + Vector3.new(0, layout.DisplaySlotSize.Y / 2 + 0.1, 0),
	}, model)

	model:SetAttribute("SlotIndex", index)
	model:SetAttribute("Occupied", false)

	return model
end

local function createPlot(plotId, side, laneIndex, position)
	local model = make("Model", {
		Name = "Base" .. plotId,
	}, basesFolder)

	local facingDirection = side == "Left" and 1 or -1
	local baseCFrame = CFrame.new(position)
	local centerDirection = Vector3.new(facingDirection, 0, 0)
	local padOffset = 16
	local signOffset = 20

	local floor = make("Part", {
		Name = "Floor",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(67, 163, 79),
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	local borderTop = createFence(model, Vector3.new(layout.PlotSize.X, 0.7, 1.2), baseCFrame * CFrame.new(0, 0.8, -layout.PlotSize.Z / 2))
	local borderBottom = createFence(model, Vector3.new(layout.PlotSize.X, 0.7, 1.2), baseCFrame * CFrame.new(0, 0.8, layout.PlotSize.Z / 2))
	local borderLeft = createFence(model, Vector3.new(1.2, 0.7, layout.PlotSize.Z), baseCFrame * CFrame.new(-layout.PlotSize.X / 2, 0.8, 0))
	local borderRight = createFence(model, Vector3.new(1.2, 0.7, layout.PlotSize.Z), baseCFrame * CFrame.new(layout.PlotSize.X / 2, 0.8, 0))
	_ = borderTop
	_ = borderBottom
	_ = borderLeft
	_ = borderRight

	local centerStrip = make("Part", {
		Name = "CenterStrip",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(242, 241, 235),
		Size = Vector3.new(layout.PlotSize.X - 8, 0.12, 8),
		CFrame = baseCFrame * CFrame.new(0, 0.56, 0),
	}, model)

	local packPad = make("Part", {
		Name = "PackPad",
		Anchored = true,
		Material = Enum.Material.Neon,
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
		Color = Color3.fromRGB(242, 241, 235),
		Size = Vector3.new(10, 0.45, 10),
		CFrame = baseCFrame * CFrame.new(facingDirection * padOffset, 0.45, 0),
	}, model)

	local ownerSignPosition = position + Vector3.new(facingDirection * signOffset, 4.3, -14)
	local ownerSign = make("Part", {
		Name = "OwnerSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(7, 5, 0.5),
		CFrame = CFrame.lookAt(ownerSignPosition, ownerSignPosition + centerDirection),
	}, model)

	local ownerGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, ownerSign)

	local ownerFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 14, 24),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, ownerGui)

	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 3,
	}, ownerFrame)

	local ownerNameLabel = createSignLabel("UNCLAIMED BASE", UDim2.new(1, -14, 0.44, 0), UDim2.new(0, 7, 0.1, 0), Color3.fromRGB(245, 238, 220), ownerFrame)
	local ownerSubtitleLabel = createSignLabel("Waiting for player", UDim2.new(1, -14, 0.24, 0), UDim2.new(0, 7, 0.58, 0), Color3.fromRGB(180, 176, 164), ownerFrame)
	ownerSubtitleLabel.Font = Enum.Font.GothamBold

	local padGui = make("BillboardGui", {
		Name = "PadGui",
		Size = UDim2.fromOffset(168, 48),
		StudsOffset = Vector3.new(0, 3.7, 0),
		AlwaysOnTop = true,
		MaxDistance = 120,
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
	local padSubtitleLabel = createSignLabel("Waiting for owner", UDim2.new(1, -24, 0, 14), UDim2.new(0, 22, 0, 24), Color3.fromRGB(180, 176, 164), padFrame)
	padTitleLabel.TextScaled = false
	padTitleLabel.TextSize = 18
	padTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.TextScaled = false
	padSubtitleLabel.TextSize = 11
	padSubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.Font = Enum.Font.GothamBold

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
		displaySlots[slotIndex] = createDisplaySlot(displayFolder, slotIndex, baseCFrame * CFrame.new(worldOffset))
	end

	local plot = {
		id = plotId,
		side = side,
		laneIndex = laneIndex,
		model = model,
		facingDirection = facingDirection,
		floor = floor,
		packPad = packPad,
		spawnPad = spawnPad,
		ownerSign = ownerSign,
		ownerNameLabel = ownerNameLabel,
		ownerSubtitleLabel = ownerSubtitleLabel,
		padTitleLabel = padTitleLabel,
		padSubtitleLabel = padSubtitleLabel,
		padAccent = padAccent,
		displaySlots = displaySlots,
		spawnCFrame = CFrame.lookAt(
			spawnPad.Position + Vector3.new(0, 3, 0),
			spawnPad.Position + Vector3.new(0, 3, 0) + centerDirection
		),
	}

	updateOwnerSign(plot, "UNCLAIMED BASE", "Waiting for player")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))

	return plot
end

function BaseService.BuildBaseMap()
	plots = {}
	assignedPlots = {}

	if basesFolder then
		basesFolder:Destroy()
	end

	basesFolder = make("Folder", {
		Name = "PlayerBases",
	}, Workspace)

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
			updateOwnerSign(plot, player.DisplayName, "Your club base")
			updatePadLabel(plot, "Rolling Pack", "Preparing your next spawn", Color3.fromRGB(255, 170, 48))
			assignedPlots[player] = plot
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
	updateOwnerSign(plot, "UNCLAIMED BASE", "Waiting for player")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	assignedPlots[player] = nil
end

function BaseService.GetPlot(player)
	return assignedPlots[player]
end

function BaseService.SetPlotPadStatus(plot, title, subtitle, color)
	if plot then
		updatePadLabel(plot, title, subtitle, color or Color3.fromRGB(255, 85, 85))
	end
end

function BaseService.PlaceCharacterAtPlot(player, character)
	local plot = assignedPlots[player]
	local targetCharacter = character or player.Character
	if not plot or not targetCharacter then
		return
	end

	targetCharacter:PivotTo(plot.spawnCFrame)
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

local Constants = require(Shared:WaitForChild("Constants"))
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
local RequestPitchforkHitEvent = makeEvent("RequestPitchforkHit")

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

BaseService.BuildBaseMap()

local swingCooldowns = {}

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
	local character = player.Character

	local hasEquipped = character and character:FindFirstChild("Pitchfork")
	if backpack and not hasEquipped and not backpack:FindFirstChild("Pitchfork") then
		createPitchforkTool().Parent = backpack
	end
end

local function sendHint(player, message)
	if player and player.Parent then
		PromptPackShopEvent:FireClient(player, {
			message = message,
		})
	end
end

local function getPitchforkDamage(player)
	local data = DataService.GetData(player)
	return math.max(Constants.Pitchfork.BaseDamage, data and data.pitchforkPower or Constants.Pitchfork.BaseDamage)
end

local function getHitsLabel(remaining)
	if remaining == 1 then
		return "1 hit to crack"
	end

	return string.format("%d hits to crack", remaining)
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

local function rollPadPackForPlayer(_player)
	local weights = {}
	for _, packDef in ipairs(PackConfig.PadSpawnOrder) do
		table.insert(weights, packDef.padWeight or 1)
	end

	local chosenIndex = Utils.WeightedRandom(weights)
	return PackConfig.PadSpawnOrder[chosenIndex]
end

local function clearPlotPack(plot)
	if plot.activePackModel and plot.activePackModel.Parent then
		plot.activePackModel:Destroy()
	end
	plot.activePackModel = nil
	plot.activePackDef = nil
	plot.activePackBody = nil
	plot.activePackLight = nil
	plot.activePackHitsRemaining = nil
	plot.activePackMaxHits = nil
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
	cardBody.Size = Vector3.new(0.3, 8, 5.4)
	cardBody.CFrame = rootCFrame
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
	glow.Range = 18
	glow.Brightness = 2.8
	glow.Parent = cardBody

	createSurfaceLabel(Enum.NormalId.Front, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)
	createSurfaceLabel(Enum.NormalId.Back, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)

	local floatTween = TweenService:Create(cardBody, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		CFrame = cardBody.CFrame * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, math.rad(4), 0),
	})
	floatTween:Play()

	plot.activePackModel = model
	plot.activePackDef = packDef
	plot.activePackBody = cardBody
	plot.activePackLight = glow
	plot.activePackMaxHits = packDef.hitsRequired or 3
	plot.activePackHitsRemaining = plot.activePackMaxHits

	BaseService.SetPlotPadStatus(plot, packDef.displayName, getHitsLabel(plot.activePackHitsRemaining), packDef.color)
	sendHint(plot.ownerPlayer, string.format("%s spawned on your red pad. Equip your pitchfork and swing %d time%s.", packDef.displayName, plot.activePackHitsRemaining, plot.activePackHitsRemaining == 1 and "" or "s"))
end

for _, plot in ipairs(BaseService.GetPlots()) do
	BaseService.SetPlotPadStatus(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
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
	if not plot or not plot.activePackDef or not plot.activePackBody or plot.isOpeningPack then
		PackOpenFailedEvent:FireClient(player, {
			error = "Your next pack is still spawning.",
		})
		return
	end

	if (rootPart.Position - plot.activePackBody.Position).Magnitude > Constants.Pitchfork.HitRange then
		PackOpenFailedEvent:FireClient(player, {
			error = "Move closer to the pack on your red pad.",
		})
		return
	end

	local damage = getPitchforkDamage(player)
	plot.activePackHitsRemaining = math.max(0, (plot.activePackHitsRemaining or plot.activePackMaxHits or 1) - damage)

	if plot.activePackLight then
		plot.activePackLight.Brightness = 2.4 + ((plot.activePackMaxHits - plot.activePackHitsRemaining) * 0.65)
	end

	if plot.activePackHitsRemaining > 0 then
		BaseService.SetPlotPadStatus(plot, plot.activePackDef.displayName, getHitsLabel(plot.activePackHitsRemaining), plot.activePackDef.color)
		sendHint(player, string.format("%s: %d hit%s left.", plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackHitsRemaining == 1 and "" or "s"))
		return
	end

	plot.isOpeningPack = true
	BaseService.SetPlotPadStatus(plot, "Pack Cracked", "Revealing your cards", plot.activePackDef.color)
	sendHint(player, plot.activePackDef.displayName .. " cracked open.")

	local openedPackId = plot.activePackDef.id
	local openedPackColor = plot.activePackDef.color
	humanoid:UnequipTools()

	local ok, result = PackService.OpenPack(player, openedPackId, {
		ignoreCost = true,
		source = "pitchfork",
	})

	if ok then
		PackOpenedEvent:FireClient(player, result)
		clearPlotPack(plot)
		BaseService.SetPlotPadStatus(plot, "Rolling Next Pack", "Another free pack is spawning", openedPackColor)
		task.delay(1.1, function()
			if plot.ownerPlayer == player then
				spawnPackForPlot(plot)
			end
		end)
	else
		plot.isOpeningPack = nil
		plot.activePackHitsRemaining = math.max(1, plot.activePackHitsRemaining or 1)
		BaseService.SetPlotPadStatus(plot, plot.activePackDef.displayName, getHitsLabel(plot.activePackHitsRemaining), plot.activePackDef.color)
		PackOpenFailedEvent:FireClient(player, result)
	end
end)

Players.PlayerAdded:Connect(function(player)
	local data = DataService.LoadPlayer(player)
	local plot = BaseService.AssignPlot(player)
	EconomyService.EnsureStarterCoins(player)
	EconomyService.TryGrantDailyReward(player)
	ensurePitchfork(player)

	if player.Character then
		task.defer(function()
			if player.Parent then
				BaseService.PlaceCharacterAtPlot(player, player.Character)
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		task.delay(0.15, function()
			if player.Parent and character.Parent then
				BaseService.PlaceCharacterAtPlot(player, character)
				ensurePitchfork(player)
			end
		end)
	end)

	if plot then
		spawnPackForPlot(plot)
	end

	task.defer(function()
		if player.Parent then
			UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			sendHint(player, plot and "Equip your pitchfork and crack the random pack on your red pad." or "This server's bases are full right now.")
		end
	end)

	return data
end)

Players.PlayerRemoving:Connect(function(player)
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
	Size = UDim2.new(0, 340, 0, 220),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
}, screenGui)

local topRightDock = make("Frame", {
	Name = "TopRightDock",
	Size = UDim2.fromOffset(176, 86),
	Position = UDim2.new(0, 24, 0, 118),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundTransparency = 1,
}, topBar)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 10),
}, topRightDock)

local openShopButton = make("TextButton", {
	LayoutOrder = 1,
	Size = UDim2.fromOffset(166, 36),
	BackgroundColor3 = UI.Gold,
	Text = "Upgrades",
	TextColor3 = Color3.fromRGB(20, 14, 8),
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
}, topRightDock)
addCorner(openShopButton, 12)

local coinPill = make("Frame", {
	LayoutOrder = 2,
	Size = UDim2.fromOffset(166, 36),
	BackgroundColor3 = UI.Panel,
}, topRightDock)
addCorner(coinPill, 12)
addStroke(coinPill, UI.Gold, 2, 0.15)

local coinGradient = make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 24, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
	}),
	Rotation = 90,
}, coinPill)

local coinIcon = make("TextLabel", {
	Size = UDim2.fromOffset(22, 22),
	Position = UDim2.new(0, 8, 0.5, -11),
	BackgroundColor3 = Color3.fromRGB(35, 30, 10),
	Text = "C",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 17,
	Font = Enum.Font.GothamBlack,
}, coinPill)
addCorner(coinIcon, 8)

local coinTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 38, 0, 3),
	Size = UDim2.new(1, -44, 0, 10),
	Text = "Coins",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 10,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local coinsLabel = make("TextLabel", {
	Name = "CoinsLabel",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 38, 0, 12),
	Size = UDim2.new(1, -44, 0, 18),
	Text = "0",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 19,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local hintLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(210, 36),
	Position = UDim2.new(0, 24, 0, 212),
	Text = "Equip your pitchfork and crack the pack on your red pad.",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 12,
	TextWrapped = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
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
	Position = UDim2.new(0.5, 0, 0, 18),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.58, 0, 0, 34),
	Text = "Pack Reveal",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 34,
	Font = Enum.Font.GothamBlack,
}, revealScreen)

local revealSubTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0, 58),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.72, 0, 0, 18),
	Text = "Keep or sell each player. Rare Gold pulls flash brighter.",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
}, revealScreen)

local cardContainer = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0.43, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.94, 0, 0.4, 0),
}, revealScreen)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 14),
}, cardContainer)

local actionRow = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 1, -24),
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(350, 42),
}, revealScreen)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 14),
}, actionRow)

local storeAllButton = make("TextButton", {
	Visible = false,
	Size = UDim2.fromOffset(168, 40),
	BackgroundColor3 = UI.Success,
	Text = "Keep Rest",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
}, actionRow)
addCorner(storeAllButton, 14)

local sellAllButton = make("TextButton", {
	Visible = false,
	Size = UDim2.fromOffset(168, 40),
	BackgroundColor3 = UI.Danger,
	Text = "Sell Rest",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
}, actionRow)
addCorner(sellAllButton, 14)

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
local keptIndexes = {}
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
	table.clear(keptIndexes)
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
		Text = packDef.cost == 0 and "Free During Alpha" or Utils.FormatNumber(packDef.cost) .. " Coins",
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
		Size = UDim2.fromOffset(146, 224),
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

	local cardActionRow = make("Frame", {
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.84, 0, 0, 28),
		Position = UDim2.new(0.08, 0, 1, -36),
	}, outer)

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
	}, cardActionRow)

	local keepButton = make("TextButton", {
		Visible = true,
		BackgroundColor3 = UI.Success,
		Size = UDim2.fromOffset(62, 28),
		Text = "Keep",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 13,
		Font = Enum.Font.GothamBlack,
	}, cardActionRow)
	addCorner(keepButton, 10)

	local sellButton = make("TextButton", {
		Visible = false,
		BackgroundColor3 = UI.Danger,
		Size = UDim2.fromOffset(62, 28),
		Text = "Sell",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 13,
		Font = Enum.Font.GothamBlack,
	}, cardActionRow)
	addCorner(sellButton, 10)

	local function flip()
		local collapse = TweenService:Create(outer, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(12, 224),
		})
		collapse:Play()
		collapse.Completed:Wait()
		back.Visible = false
		front.Visible = true
		local expand = TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(146, 224),
		})
		expand:Play()
		TweenService:Create(border, TweenInfo.new(0.25), {
			Color = accent,
			Transparency = 0,
			Thickness = cardData.rarity == "Rare Gold" and 3 or 2,
		}):Play()
		cardActionRow.Visible = true
		sellButton.Visible = true
		if cardData.rarity == "Rare Gold" then
			showToast("Rare pull: " .. cardData.name .. " (" .. cardData.rating .. ")", accent)
		end
	end

	keepButton.MouseButton1Click:Connect(function()
		if soldIndexes[cardIndex] or keptIndexes[cardIndex] then
			return
		end
		keptIndexes[cardIndex] = true
		cardActionRow.Visible = false
		TweenService:Create(border, TweenInfo.new(0.2), {
			Color = UI.Success,
			Transparency = 0,
			Thickness = 2,
		}):Play()
		showToast("Kept " .. cardData.name .. " for your club.", UI.Success)
	end)

	sellButton.MouseButton1Click:Connect(function()
		if soldIndexes[cardIndex] or keptIndexes[cardIndex] then
			return
		end
		local response = SellCardFn:InvokeServer(cardData.id)
		if response and response.success then
			soldIndexes[cardIndex] = true
			cardActionRow.Visible = false
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
	shopStatus.Text = "Pad packs are free right now. Upgrades come next."
	shopStatus.TextColor3 = UI.Muted
end

local function runReveal(payload)
	isRevealing = true
	clearCards()
	revealTitle.Text = payload.packName
	revealSubTitle.Text = "Keep or sell each player. Rare Gold pulls flash brighter."
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
	showToast("Upgrades are coming next: pad luck, pack quality, and pitchfork power.", UI.Gold)
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
		if not soldIndexes[index] and not keptIndexes[index] then
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
	Size = UDim2.fromOffset(118, 34),
	Position = UDim2.new(0, 24, 0, 76),
	BackgroundColor3 = Constants.UI.Panel,
	Text = "Inventory",
	TextColor3 = Constants.UI.Text,
	TextScaled = false,
	TextSize = 15,
	Font = Enum.Font.GothamBlack,
}, screenGui)
addCorner(toggle, 12)

local panel = make("Frame", {
	Visible = false,
	Size = UDim2.new(0, 560, 0, 440),
	Position = UDim2.new(0, 24, 0, 124),
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

makeLocal("HUDClient", sps, [==[
return
]==])

makeLocal("ToolClient", sps, [==[
local Players = game:GetService("Players")
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
]==])

makeLocal("ShopUI", sps, [==[
return
]==])

makeLocal("TradeUI", sps, [==[
return
]==])

makeLocal("MarketUI", sps, [==[
return
]==])

makeLocal("BaseUI", sps, [==[
return
]==])

makeLocal("CollectionUI", sps, [==[
return
]==])

makeLocal("RebirthUI", sps, [==[
return
]==])


print("[UnboxAFootballer] v5 pitchfork setup complete")
