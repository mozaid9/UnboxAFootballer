local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardData  = require(ReplicatedStorage.Shared.CardData)
local Constants = require(ReplicatedStorage.Shared.Constants)

local RebirthService = {}

local DataService

local rebirthConfig = Constants.Rebirth

-- ── Rarity hierarchy ─────────────────────────────────────────────────────────
-- Higher number = rarer.  Used to satisfy "at or above" card requirements.
local RARITY_RANK = {
	["Gold"]               = 1,
	["Rare Gold"]          = 2,
	["Premium Gold"]       = 3,
	["Talisman"]           = 4,
	["Maestro"]            = 5,
	["Immortal"]           = 6,
	["Player of the Year"] = 7,
	["POTY"]               = 7,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function getData(player)
	return DataService and DataService.GetData(player)
end

-- Returns the requirement table for going from tier (N-1) → N.
-- For tiers beyond the defined list the fans cost keeps doubling and the
-- hardest defined card requirement is reused.
local function getRequirementForTier(targetTier)
	local reqs = rebirthConfig.TierRequirements
	if reqs[targetTier] then
		return reqs[targetTier]
	end

	-- Find the highest defined tier
	local maxDefined = 0
	for t in pairs(reqs) do
		if t > maxDefined then maxDefined = t end
	end

	local base    = reqs[maxDefined] or { fans = 32000000, cards = { { count = 3, rarity = "Player of the Year" } } }
	local extra   = targetTier - maxDefined
	local fans    = math.floor(base.fans * (2 ^ extra))
	return { fans = fans, cards = base.cards }
end

-- Count cards at or above rarity, and return the first qualifying card as an example.
local function countCardsAtOrAboveRarity(data, rarity)
	local minRank = RARITY_RANK[rarity] or 99
	local count   = 0
	local example = nil

	for _, card in ipairs(CardData.Pool) do
		local rank = RARITY_RANK[card.rarity] or 0
		if rank >= minRank then
			local key = tostring(card.id)
			local owned = data.inventory and data.inventory[key] or 0
			if owned > 0 then
				count += owned
				if not example then
					example = { name = card.name, rarity = card.rarity, id = card.id }
				end
			end
		end
	end

	local displayedCards = data.baseLayoutData and data.baseLayoutData.displayedCards or {}
	for _, cardId in pairs(displayedCards) do
		local card = CardData.ById and CardData.ById[tonumber(cardId)]
		if card then
			local rank = RARITY_RANK[card.rarity] or 0
			if rank >= minRank then
				count += 1
				if not example then
					example = { name = card.name, rarity = card.rarity, id = card.id }
				end
			end
		end
	end

	return count, example
end

-- ── Public API ────────────────────────────────────────────────────────────────

function RebirthService.Init(dataService)
	DataService = dataService
end

function RebirthService.GetRequiredFans(rebirthTier)
	local req = getRequirementForTier((rebirthTier or 0) + 1)
	return req.fans
end

function RebirthService.GetFanMultiplier(rebirthTier)
	rebirthTier = math.max(0, rebirthTier or 0)

	local milestones = rebirthConfig.MultiplierMilestones or {}
	if #milestones == 0 then return 1 end

	local previous = milestones[1]
	for index = 2, #milestones do
		local current = milestones[index]
		if rebirthTier == current.tier then
			return current.multiplier
		end
		if rebirthTier < current.tier then
			local span  = math.max(1, current.tier - previous.tier)
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
		return { canRebirth = false, reason = "Your data is still loading." }
	end

	local tier       = data.rebirthTier or 0
	local req        = getRequirementForTier(tier + 1)
	local currentFans = data.coins or 0
	local enoughFans = currentFans >= req.fans

	-- Check every card group in the requirement
	local cardsMet   = true
	local cardStatus = {}
	for _, group in ipairs(req.cards) do
		local owned, example = countCardsAtOrAboveRarity(data, group.rarity)
		local met   = owned >= group.count
		if not met then cardsMet = false end
		table.insert(cardStatus, {
			rarity  = group.rarity,
			needed  = group.count,
			owned   = owned,
			met     = met,
			example = example,   -- { name, rarity, id } of first qualifying card owned, or nil
		})
	end

	local canRebirth = enoughFans and cardsMet
	local reason
	if not enoughFans then
		reason = string.format("You need %s fans (you have %s).",
			require(ReplicatedStorage.Shared.Utils).FormatNumber(req.fans),
			require(ReplicatedStorage.Shared.Utils).FormatNumber(currentFans))
	elseif not cardsMet then
		local g = req.cards[1]
		reason = string.format("You need %d %s+ player(s).", g.count, g.rarity)
	end

	return {
		canRebirth        = canRebirth,
		reason            = reason,
		rebirthTier       = tier,
		currentFans       = currentFans,
		requiredFans      = req.fans,
		cardStatus        = cardStatus,
		currentMultiplier = RebirthService.GetFanMultiplier(tier),
		nextMultiplier    = RebirthService.GetFanMultiplier(tier + 1),
		rebirthTokens     = data.rebirthTokens or 0,
		baseSlots         = data.baseSlots or rebirthConfig.BaseSlots,
		nextBaseSlots     = math.min(
			(data.baseSlots or rebirthConfig.BaseSlots) + rebirthConfig.SlotsPerRebirth,
			rebirthConfig.MaxSlots
		),
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

	local nextTier   = (data.rebirthTier   or 0) + 1
	local nextTokens = (data.rebirthTokens or 0) + 1
	local nextTotal  = (data.totalRebirths or 0) + 1
	local nextSlots  = math.min(
		(data.baseSlots or rebirthConfig.BaseSlots) + rebirthConfig.SlotsPerRebirth,
		rebirthConfig.MaxSlots
	)

	DataService.ResetForRebirth(player, rebirthConfig.StartingFansAfterRebirth)
	data.rebirthTier   = nextTier
	data.rebirthTokens = nextTokens
	data.totalRebirths = nextTotal
	data.baseSlots     = nextSlots
	DataService.MarkDirty(player)

	return true, RebirthService.GetStatus(player)
end

return RebirthService
