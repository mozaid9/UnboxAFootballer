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
