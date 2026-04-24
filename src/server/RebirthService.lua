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
		return false, "You need more Fans."
	end

	for _, card in ipairs(CardData.Pool) do
		if (data.inventory[tostring(card.id)] or 0) <= 0 then
			return false, "You need every launch card before rebirthing."
		end
	end

	return true
end

return RebirthService
