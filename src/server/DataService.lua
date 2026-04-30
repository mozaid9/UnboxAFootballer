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
	collection = {},
	collectionViewed = {},
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
		PackSpawnLuck = 1,
		CardPullLuck = 1,
		PackSpawnRate = 0,
		PadLuck = 0,
		MoveSpeed = 0,
	},
	totalCardsOpened = 0,
	totalPacksOpened = 0,
	totalRebirths = 0,
	collectionRewards = {},
	claimedMilestones = {},  -- keys are tostring(threshold), value true when claimed
}

local cache = {}
local dirtyPlayers = {}

local function normalizeUpgradeData(data)
	if not data then
		return false
	end

	if type(data.upgrades) ~= "table" then
		data.upgrades = Utils.DeepCopy(DEFAULT_DATA.upgrades)
		return true
	end

	local changed = false
	for key, defaultValue in pairs(DEFAULT_DATA.upgrades) do
		if data.upgrades[key] == nil then
			data.upgrades[key] = defaultValue
			changed = true
		end
	end

	for key, spec in pairs(Constants.Upgrades) do
		if spec.startLevel and (tonumber(data.upgrades[key]) or 0) < spec.startLevel then
			data.upgrades[key] = spec.startLevel
			changed = true
		end
	end

	-- One-time compatibility bridge from the old all-purpose PadLuck upgrade.
	local legacyPadLuck = tonumber(data.upgrades.PadLuck) or 0
	if (data.upgrades.PackSpawnLuck or 0) <= (Constants.Upgrades.PackSpawnLuck.startLevel or 1) and legacyPadLuck > 0 then
		data.upgrades.PackSpawnLuck = math.min(legacyPadLuck, Constants.Upgrades.PackSpawnLuck.maxLevel)
		changed = true
	end

	return changed
end

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

local function normalizeCollectionData(data)
	if not data then
		return false
	end

	if type(data.collection) ~= "table" then
		data.collection = {}
	end
	if type(data.collectionRewards) ~= "table" then
		data.collectionRewards = {}
	end
	if type(data.collectionViewed) ~= "table" then
		data.collectionViewed = {}
	end

	local normalized = {}
	local viewed = {}
	local changed = false

	for key, amount in pairs(data.collection) do
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

	if type(data.inventory) == "table" then
		for key, amount in pairs(data.inventory) do
			local cardId = tonumber(key)
			local count = tonumber(amount)
			if cardId and count and count > 0 then
				local normalizedKey = tostring(math.floor(cardId))
				if (normalized[normalizedKey] or 0) < math.floor(count) then
					normalized[normalizedKey] = math.floor(count)
					changed = true
				end
			end
		end
	end

	local displayedCards = data.baseLayoutData and data.baseLayoutData.displayedCards
	if type(displayedCards) == "table" then
		for _, cardId in pairs(displayedCards) do
			local numericId = tonumber(cardId)
			if numericId then
				local normalizedKey = tostring(math.floor(numericId))
				if (normalized[normalizedKey] or 0) < 1 then
					normalized[normalizedKey] = 1
					changed = true
				end
			end
		end
	end

	for key, amount in pairs(normalized) do
		if data.collection[key] ~= amount then
			changed = true
			break
		end
	end

	for key in pairs(data.collection) do
		if normalized[key] == nil then
			changed = true
			break
		end
	end

	if changed then
		data.collection = normalized
	end

	for key, value in pairs(data.collectionViewed) do
		local cardId = tonumber(key)
		if cardId and value == true then
			local normalizedKey = tostring(math.floor(cardId))
			if normalized[normalizedKey] then
				viewed[normalizedKey] = true
			end
		else
			changed = true
		end
	end

	for key, value in pairs(viewed) do
		if data.collectionViewed[key] ~= value then
			changed = true
			break
		end
	end

	for key in pairs(data.collectionViewed) do
		if viewed[key] == nil then
			changed = true
			break
		end
	end

	if changed then
		data.collectionViewed = viewed
	end

	return changed
end

local function deepMergeDefaults(source, defaults)
	local merged = {}

	-- If the defaults table is empty it's an open-ended map (e.g. inventory,
	-- displayedCards, collectionRewards). Preserve ALL keys from source as-is;
	-- don't wipe them by iterating an empty template.
	if next(defaults) == nil then
		if type(source) == "table" then
			for k, v in pairs(source) do
				merged[k] = v
			end
		end
		return merged
	end

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
	normalizeCollectionData(cache[player])
	normalizeUpgradeData(cache[player])
	DataService.MarkDirty(player)
	return cache[player]
end

function DataService.SavePlayer(player)
	local data = cache[player]
	if not data or not dirtyPlayers[player] then
		return true
	end

	-- Snapshot data at save time so in-flight mutations don't corrupt payload
	local payload = Utils.DeepCopy(data)
	local key = tostring(player.UserId)

	local ok = tryDataStore(function()
		PlayerStore:SetAsync(key, payload)
	end)

	if ok then
		dirtyPlayers[player] = nil
	else
		warn("[DataService] Failed to save data for", player.Name,
			"— data will persist in cache for retry.")
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

function DataService.RecordCardPacked(player, cardId, amount)
	local data = cache[player]
	if not data then
		return false
	end
	if normalizeCollectionData(data) then
		DataService.MarkDirty(player)
	end

	local key = tostring(cardId)
	local delta = math.max(1, math.floor(tonumber(amount) or 1))
	data.collection[key] = (data.collection[key] or 0) + delta
	DataService.MarkDirty(player)
	return true
end

function DataService.GetCollection(player)
	local data = cache[player]
	if not data then
		return {}
	end
	if normalizeCollectionData(data) then
		DataService.MarkDirty(player)
	end
	return data.collection
end

function DataService.GetCollectionViewed(player)
	local data = cache[player]
	if not data then
		return {}
	end
	if normalizeCollectionData(data) then
		DataService.MarkDirty(player)
	end
	return data.collectionViewed
end

function DataService.MarkCollectionCardViewed(player, cardId)
	local data = cache[player]
	if not data then
		return false
	end
	if normalizeCollectionData(data) then
		DataService.MarkDirty(player)
	end

	local key = tostring(cardId)
	if (data.collection[key] or 0) <= 0 then
		return false
	end

	data.collectionViewed[key] = true
	DataService.MarkDirty(player)
	return true
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
		PackSpawnLuck = Constants.Upgrades.PackSpawnLuck.startLevel or 1,
		CardPullLuck = Constants.Upgrades.CardPullLuck.startLevel or 1,
		PackSpawnRate = 0,
		PadLuck = 0,
		MoveSpeed = 0,
	}
	data.totalCardsOpened = 0
	data.totalPacksOpened = 0
	data.claimedMilestones = {}
	DataService.MarkDirty(player)
	return true
end

-- ── Dev-only full reset ───────────────────────────────────────
-- Wipes all progress back to DEFAULT_DATA and saves immediately.
-- Trigger via chat command "/resetdata" (remove before production).
function DataService.DevReset(player)
	local fresh = deepMergeDefaults({}, DEFAULT_DATA)
	cache[player] = fresh
	dirtyPlayers[player] = true
	DataService.SavePlayer(player)
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
