local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardData = require(ReplicatedStorage.Shared.CardData)
local Constants = require(ReplicatedStorage.Shared.Constants)

local RebirthService = {}

local DataService

local rebirthConfig = Constants.Rebirth

local function getData(player)
	return DataService and DataService.GetData(player)
end

local function getOwnedSpecialCount(data)
	local count = 0
	local inventory = data.inventory or {}
	local displayedCards = data.baseLayoutData and data.baseLayoutData.displayedCards or {}

	for _, card in ipairs(CardData.Pool) do
		if card.rarity == rebirthConfig.SpecialRarity then
			count += inventory[tostring(card.id)] or 0
		end
	end

	for _, cardId in pairs(displayedCards) do
		local card = CardData.ById[tonumber(cardId)]
		if card and card.rarity == rebirthConfig.SpecialRarity then
			count += 1
		end
	end

	return count
end

function RebirthService.Init(dataService)
	DataService = dataService
end

function RebirthService.GetRequiredFans(rebirthTier)
	return math.floor(rebirthConfig.BaseFanRequirement * (rebirthConfig.FanRequirementMultiplier ^ (rebirthTier or 0)))
end

function RebirthService.GetFanMultiplier(rebirthTier)
	rebirthTier = math.max(0, rebirthTier or 0)

	local milestones = rebirthConfig.MultiplierMilestones or {}
	if #milestones == 0 then
		return 1
	end

	local previous = milestones[1]
	for index = 2, #milestones do
		local current = milestones[index]
		if rebirthTier == current.tier then
			return current.multiplier
		end

		if rebirthTier < current.tier then
			local span = math.max(1, current.tier - previous.tier)
			local alpha = (rebirthTier - previous.tier) / span
			return previous.multiplier + ((current.multiplier - previous.multiplier) * alpha)
		end

		previous = current
	end

	return previous.multiplier + ((rebirthTier - previous.tier) * 0.5)
end

function RebirthService.GetStatus(player)
	local data = getData(player)
	if not data then
		return {
			canRebirth = false,
			reason = "Your data is still loading.",
		}
	end

	local tier = data.rebirthTier or 0
	local requiredFans = RebirthService.GetRequiredFans(tier)
	local currentFans = data.coins or 0
	local specialCount = getOwnedSpecialCount(data)
	local requiredSpecialCards = rebirthConfig.RequiredSpecialCards

	local canRebirth = currentFans >= requiredFans and specialCount >= requiredSpecialCards
	local reason
	if currentFans < requiredFans then
		reason = "You need more Fans."
	elseif specialCount < requiredSpecialCards then
		reason = string.format("You need %d %s players.", requiredSpecialCards, rebirthConfig.SpecialRarity)
	end

	return {
		canRebirth = canRebirth,
		reason = reason,
		rebirthTier = tier,
		currentFans = currentFans,
		requiredFans = requiredFans,
		specialCount = specialCount,
		requiredSpecialCards = requiredSpecialCards,
		specialRarity = rebirthConfig.SpecialRarity,
		currentMultiplier = RebirthService.GetFanMultiplier(tier),
		nextMultiplier = RebirthService.GetFanMultiplier(tier + 1),
		rebirthTokens = data.rebirthTokens or 0,
	}
end

function RebirthService.CanRebirth(player)
	local status = RebirthService.GetStatus(player)
	return status.canRebirth, status.reason, status
end

function RebirthService.PerformRebirth(player)
	local canRebirth, reason, status = RebirthService.CanRebirth(player)
	if not canRebirth then
		return false, status or { reason = reason or "You cannot rebirth yet." }
	end

	local data = getData(player)
	if not data then
		return false, { reason = "Your data is still loading." }
	end

	local nextTier = (data.rebirthTier or 0) + 1
	local nextTokens = (data.rebirthTokens or 0) + 1
	local nextTotal = (data.totalRebirths or 0) + 1

	DataService.ResetForRebirth(player, rebirthConfig.StartingFansAfterRebirth)
	data.rebirthTier = nextTier
	data.rebirthTokens = nextTokens
	data.totalRebirths = nextTotal
	DataService.MarkDirty(player)

	return true, RebirthService.GetStatus(player)
end

return RebirthService
