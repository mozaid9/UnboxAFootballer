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

function EconomyService.GetDailyRewardRemaining(player)
	local data = getData(player)
	if not data then
		return Constants.DailyRewardCooldown
	end
	return math.max(0, Constants.DailyRewardCooldown - (os.time() - (data.lastDailyReward or 0)))
end

local function getDailyStreakReward(streak)
	local rewards = Constants.DailyStreakRewards or {}
	if #rewards == 0 then
		return nil, 0
	end

	local index = ((math.max(0, tonumber(streak) or 0) - 1) % #rewards) + 1
	return rewards[index], index
end

function EconomyService.TryGrantDailyReward(player)
	local data = getData(player)
	if not data then
		return false, "Your data is still loading."
	end
	if not EconomyService.CanClaimDailyReward(player) then
		return false, "Daily reward ready in " .. math.ceil(EconomyService.GetDailyRewardRemaining(player) / 60) .. "m."
	end

	local now = os.time()
	local lastClaim = data.lastDailyReward or 0
	local currentStreak = tonumber(data.dailyRewardStreak) or 0
	if lastClaim > 0 and (now - lastClaim) <= (Constants.DailyRewardCooldown * 2) then
		currentStreak += 1
	else
		currentStreak = 1
	end

	data.dailyRewardStreak = currentStreak
	data.lastDailyReward = now
	DataService.MarkDirty(player)

	local reward = getDailyStreakReward(currentStreak)
	return true, reward, currentStreak
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
