local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Utils = {}

function Utils.WeightedRandom(weights)
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

function Utils.GetPowerScore(cardOrScore)
	if type(cardOrScore) == "table" then
		return cardOrScore.powerScore
			or cardOrScore.internalRating
			or cardOrScore.rating
			or Constants.PassiveIncome.BaseRating
	end

	return cardOrScore or Constants.PassiveIncome.BaseRating
end

function Utils.GetSellValue(cardOrScore)
	local powerScore = Utils.GetPowerScore(cardOrScore)
	local baseValue = Constants.SellValues[powerScore] or 0
	if type(cardOrScore) == "table" then
		local multipliers = Constants.RaritySellMultipliers or {}
		local rarityMultiplier = multipliers[cardOrScore.rarity] or 1
		return math.floor(baseValue * rarityMultiplier)
	end
	return baseValue
end

function Utils.GetMarketFloor(cardOrScore)
	local powerScore = Utils.GetPowerScore(cardOrScore)
	return Constants.MarketFloors[powerScore] or 0
end

function Utils.CalculateFansPerSecond(cardOrScore)
	local config = Constants.PassiveIncome
	local powerScore = Utils.GetPowerScore(cardOrScore)
	local ratingSteps = math.max(0, powerScore - config.BaseRating)
	-- Exponential curve: base * growthRate^steps
	-- This makes high-rarity cards dramatically more valuable (Immortals = 1000+/s)
	return math.floor(config.BasePerSecond * (config.GrowthRate ^ ratingSteps))
end

function Utils.GetPassiveIncome(cardOrScore)
	return Utils.CalculateFansPerSecond(cardOrScore)
end

function Utils.GetCardIncomeRating(cardOrRating)
	return Utils.GetPowerScore(cardOrRating)
end

function Utils.GetRarityStyle(rarity)
	local styles = Constants.RarityStyles or {}
	return styles[rarity] or styles.Gold or {
		label = rarity or "GOLD",
		primary = Constants.UI.Gold,
		secondary = Constants.UI.RareGold,
		dark = Constants.UI.PanelAlt,
		trim = Constants.UI.Gold,
		text = Constants.UI.Text,
		glow = Constants.UI.Gold,
	}
end

function Utils.GetRarityColor(rarity)
	return Utils.GetRarityStyle(rarity).primary
end

return Utils
