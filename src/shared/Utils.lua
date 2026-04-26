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

function Utils.GetPassiveIncome(rating)
	local config = Constants.PassiveIncome
	local ratingSteps = math.max(0, (rating or config.BaseRating) - config.BaseRating)
	return config.BasePerSecond + (ratingSteps * config.PerRatingStep)
end

function Utils.GetCardIncomeRating(cardOrRating)
	if type(cardOrRating) == "table" then
		return cardOrRating.internalRating or cardOrRating.rating or Constants.PassiveIncome.BaseRating
	end

	return cardOrRating or Constants.PassiveIncome.BaseRating
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
