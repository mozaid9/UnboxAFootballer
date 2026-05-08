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

-- Count cards at or above rarity and collect up to maxExamples qualifying
-- cards so the UI can show one row per required slot.
--
-- Vault-kept cards (carried over from the previous rebirth cycle) are NOT
-- counted — the player must earn fresh qualifying cards in the current cycle
-- to progress.  vaultKeptInventory is a {[cardIdStr] = count} map set by
-- PerformRebirth; it drains naturally as the player earns new copies and
-- removes vault copies.
local function countCardsAtOrAboveRarity(data, rarity, maxExamples)
	local minRank  = RARITY_RANK[rarity] or 99
	local count    = 0
	local examples = {}
	maxExamples    = maxExamples or 1

	-- Cards that were carried over from the vault do not count toward the
	-- next rebirth requirement.
	local vaultKept = data.vaultKeptInventory or {}

	for _, card in ipairs(CardData.Pool) do
		local rank = RARITY_RANK[card.rarity] or 0
		if rank >= minRank then
			local key   = tostring(card.id)
			local ownedTotal = data.inventory and data.inventory[key] or 0
			-- Subtract any copies that came from the vault; they don't count.
			local ownedNew = math.max(0, ownedTotal - (vaultKept[key] or 0))
			if ownedNew > 0 then
				count += ownedNew
				-- Collect up to maxExamples copies (same card can fill multiple slots)
				for _ = 1, ownedNew do
					if #examples < maxExamples then
						table.insert(examples, { name = card.name, rarity = card.rarity, id = card.id })
					end
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
				-- A displayed card was placed from the current-cycle inventory.
				-- Check whether the underlying inventory copy is a new card.
				local key = tostring(card.id)
				local inv = data.inventory and data.inventory[key] or 0
				local kept = vaultKept[key] or 0
				if inv > kept then
					count += 1
					if #examples < maxExamples then
						table.insert(examples, { name = card.name, rarity = card.rarity, id = card.id })
					end
				end
			end
		end
	end

	return count, examples
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

function RebirthService.GetVaultSlots(rebirthTier)
	rebirthTier = math.max(0, rebirthTier or 0)
	local slots = 0
	for _, milestone in ipairs(rebirthConfig.VaultSlots or {}) do
		if rebirthTier >= (milestone.tier or math.huge) then
			slots = math.max(slots, milestone.slots or 0)
		end
	end
	return slots
end

function RebirthService.GetStartingFansAfterRebirth(targetTier)
	targetTier = math.max(1, math.floor(tonumber(targetTier) or 1))
	local byTier = rebirthConfig.StartingFansByTierAfterRebirth or {}
	if byTier[targetTier] then
		return byTier[targetTier]
	end

	local maxDefinedTier = 0
	for tier in pairs(byTier) do
		if tier > maxDefinedTier then
			maxDefinedTier = tier
		end
	end

	if maxDefinedTier <= 0 then
		return rebirthConfig.StartingFansAfterRebirth or Constants.StartingCoins
	end

	local growth = rebirthConfig.StartingFansGrowthAfterTier or 2
	return math.floor((byTier[maxDefinedTier] or Constants.StartingCoins) * (growth ^ (targetTier - maxDefinedTier)))
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
		local owned, examples = countCardsAtOrAboveRarity(data, group.rarity, group.count)
		local met = owned >= group.count
		if not met then cardsMet = false end
		table.insert(cardStatus, {
			rarity   = group.rarity,
			needed   = group.count,
			owned    = owned,
			met      = met,
			examples = examples,     -- up to group.count qualifying cards [{name,rarity,id}]
			example  = examples[1],  -- backward-compat: first example or nil
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
		vaultSlots        = RebirthService.GetVaultSlots(tier),
		nextVaultSlots    = RebirthService.GetVaultSlots(tier + 1),
		startingFansAfterRebirth = RebirthService.GetStartingFansAfterRebirth(tier + 1),
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
	local startingFans = RebirthService.GetStartingFansAfterRebirth(nextTier)
	local keepers = {}
	local maxVaultSlots = RebirthService.GetVaultSlots(data.rebirthTier or 0)
	local inventory = data.inventory or {}
	local seen = {}
	for _, value in ipairs(data.rebirthVault or {}) do
		local cardId = tonumber(value)
		if cardId and #keepers < maxVaultSlots then
			cardId = math.floor(cardId)
			local key = tostring(cardId)
			if not seen[cardId] and (inventory[key] or 0) > 0 then
				table.insert(keepers, cardId)
				seen[cardId] = true
			end
		end
	end

	DataService.ResetForRebirth(player, startingFans)
	data.rebirthTier   = nextTier
	data.rebirthTokens = nextTokens
	data.totalRebirths = nextTotal
	data.baseSlots     = nextSlots

	-- Re-add vault-kept cards and record which ones they are so that
	-- countCardsAtOrAboveRarity can exclude them from the next rebirth check.
	local vaultKeptInventory = {}
	for _, cardId in ipairs(keepers) do
		DataService.AddCard(player, cardId, 1)
		local key = tostring(cardId)
		vaultKeptInventory[key] = (vaultKeptInventory[key] or 0) + 1
	end
	data.vaultKeptInventory = vaultKeptInventory

	DataService.ClearRebirthVault(player)
	DataService.MarkDirty(player)

	return true, RebirthService.GetStatus(player)
end

return RebirthService
