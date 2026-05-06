local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

if ServerScriptService:GetAttribute("UnboxMainBooted") then
	warn("[UnboxAFootballer] Duplicate Main detected, skipping older copy")
	return
end
ServerScriptService:SetAttribute("UnboxMainBooted", true)
Players.CharacterAutoLoads = false

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
local CrowdService = require(ServerScriptService:WaitForChild("CrowdService"))
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
local PackHitFeedbackEvent = makeEvent("PackHitFeedback")
local MilestoneRewardEvent = makeEvent("MilestoneReward")
local OpenSlotPickerEvent = makeEvent("OpenSlotPicker")
local QuestUpdatedEvent = makeEvent("QuestUpdated")

local GetPlayerDataFn = makeFunction("GetPlayerData")
local OpenPackFn = makeFunction("OpenPack")
local SellCardFn = makeFunction("SellCard")
local SellAllCardsFn = makeFunction("SellAllCards")
local GetInventoryFn = makeFunction("GetInventory")
local GetCollectionFn = makeFunction("GetCollection")
local ClaimCollectionRewardFn = makeFunction("ClaimCollectionReward")
local MarkCollectionCardViewedFn = makeFunction("MarkCollectionCardViewed")
local GetUpgradesFn = makeFunction("GetUpgrades")
local PurchaseUpgradeFn = makeFunction("PurchaseUpgrade")
local PlaceInventoryCardInSlotFn = makeFunction("PlaceInventoryCardInSlot")
local ClaimFreePackFn = makeFunction("ClaimFreePack")
local ClaimDailyRewardFn = makeFunction("ClaimDailyReward")
local PurchasePackFn = makeFunction("PurchasePack")
local ChoosePlayerPickFn = makeFunction("ChoosePlayerPick")
local GetQuestsFn = makeFunction("GetQuests")
local ClaimQuestFn = makeFunction("ClaimQuest")
local GetRebirthStatusFn = makeFunction("GetRebirthStatus")
local RequestRebirthFn = makeFunction("RequestRebirth")
local OpenRebirthUIEvent = makeEvent("OpenRebirthUI")
local GetRebirthVaultFn = makeFunction("GetRebirthVault")
local SetRebirthVaultFn = makeFunction("SetRebirthVault")
local OpenRebirthVaultUIEvent = makeEvent("OpenRebirthVaultUI")

PackService.Init(DataService, EconomyService, {
	UpdateCoins = UpdateCoinsEvent,
	PackOpened = PackOpenedEvent,
	PackOpenFailed = PackOpenFailedEvent,
})
EconomyService.Init(DataService)
RebirthService.Init(DataService)

local buildRebirthVaultPayload

BaseService.BuildBaseMap()
CrowdService.Init(BaseService, DataService)

-- Wire every plot's rebirth-machine ProximityPrompt.
-- Fires immediately from server, fires OpenRebirthUI to that player's client.
for _, plot in ipairs(BaseService.GetPlots()) do
	if plot.rebirthPrompt then
		plot.rebirthPrompt.Triggered:Connect(function(player)
			-- Only the owner can use their own machine
			if plot.ownerPlayer ~= player then return end
			local status = RebirthService.GetStatus(player)
			OpenRebirthUIEvent:FireClient(player, status)
		end)
	end
	if plot.rebirthVaultPrompt then
		plot.rebirthVaultPrompt.Triggered:Connect(function(player)
			if plot.ownerPlayer ~= player then return end
			OpenRebirthVaultUIEvent:FireClient(player, buildRebirthVaultPayload and buildRebirthVaultPayload(player) or nil)
		end)
	end
end

local swingCooldowns = {}
local initializedPlayers = {}
local packPurchaseLocks = {}
local pendingPlayerPicks = {}
local playerPickLocks = {}
local questClaimLocks = {}
local serverPackState = nil

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
	local starterGear = player:FindFirstChild("StarterGear") or player:WaitForChild("StarterGear", 5)
	local character = player.Character

	local hasEquipped = character and character:FindFirstChild("Pitchfork")
	if starterGear and not starterGear:FindFirstChild("Pitchfork") then
		createPitchforkTool().Parent = starterGear
	end

	if backpack and not hasEquipped and not backpack:FindFirstChild("Pitchfork") then
		createPitchforkTool().Parent = backpack
	end
end

local function placeCharacterAtOwnedPlot(player, character)
	if not player or not player.Parent or not character or not character.Parent then
		return false
	end

	local placed = BaseService.PlaceCharacterAtPlot(player, character)
	ensurePitchfork(player)

	task.delay(0.75, function()
		if player.Parent and character.Parent then
			BaseService.PlaceCharacterAtPlot(player, character)
			ensurePitchfork(player)
		end
	end)

	return placed
end

local function sendHint(player, message, extraPayload)
	if player and player.Parent then
		local payload = {
			message = message,
			coins = DataService.GetCoins(player),
		}
		for key, value in pairs(extraPayload or {}) do
			payload[key] = value
		end
		PromptPackShopEvent:FireClient(player, payload)
	end
end

local function getUpgradeLevel(player, key)
	local data = DataService.GetData(player)
	if not data or not data.upgrades then
		return 0
	end
	return data.upgrades[key] or 0
end

local function getUpgradeCost(key, level)
	local spec = Constants.Upgrades[key]
	if not spec or level >= spec.maxLevel then
		return nil
	end
	-- Prefer explicit per-level cost table when present
	if spec.levelCosts then
		return spec.levelCosts[level + 1]  -- level 0 → index 1
	end
	if spec.costExponent then
		local formulaLevel = spec.startLevel and math.max(spec.startLevel, level) or (level + 1)
		return math.floor(spec.baseCost * (formulaLevel ^ spec.costExponent))
	end
	return math.floor(spec.baseCost * (spec.costMultiplier ^ level))
end

local function computePitchforkDamage(level)
	local spec = Constants.Upgrades.PitchforkDamage
	local mults = spec.multipliers
	local idx = math.clamp(level + 1, 1, #mults)
	return mults[idx]
end

local function computeSpawnDelay(level)
	local spec = Constants.Upgrades.PackSpawnRate
	return math.max(spec.minDelay, spec.baseDelay - level * spec.delayReductionPerLevel)
end

local function computePackSpawnLuckValue(level)
	-- Returns the % chance of landing Rare or better pack at this luck level.
	-- Used only for upgrade UI display.
	local spec = Constants.Upgrades.PackSpawnLuck
	local clampedLevel = math.clamp(level, 0, spec.maxLevel)
	local weights = PackConfig.GetPackSpawnWeights(math.max(1, clampedLevel))
	return math.floor(100 - (weights.GoldPack or 100))  -- 100 − Gold% = better-pack chance
end

local function computeCardPullLuckValue(level)
	local spec = Constants.Upgrades.CardPullLuck
	local clampedLevel = math.clamp(level or spec.startLevel or 1, spec.startLevel or 1, spec.maxLevel)
	return math.floor(((clampedLevel - (spec.startLevel or 1)) / math.max(1, spec.maxLevel - (spec.startLevel or 1))) * 100)
end

local function computeWalkSpeed(level)
	local spec = Constants.Upgrades.MoveSpeed
	return math.min(spec.baseWalkSpeed + level * spec.speedPerLevel, spec.maxWalkSpeed)
end

local function getPitchforkDamage(player)
	return computePitchforkDamage(getUpgradeLevel(player, "PitchforkDamage"))
end

local function getFanEarningsMultiplier(player)
	local data = DataService.GetData(player)
	local rebirthMultiplier = type(RebirthService.GetFanMultiplier) == "function"
		and RebirthService.GetFanMultiplier(data and data.rebirthTier or 0)
		or 1
	return rebirthMultiplier
end

local function applyMovementUpgrade(player, character)
	local targetCharacter = character or player.Character
	local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = computeWalkSpeed(getUpgradeLevel(player, "MoveSpeed"))
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
	frame.BackgroundColor3 = color:Lerp(Color3.fromRGB(8, 10, 18), 0.30)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color:Lerp(Color3.fromRGB(255, 255, 255), 0.26)),
		ColorSequenceKeypoint.new(0.45, color),
		ColorSequenceKeypoint.new(1, color:Lerp(Color3.fromRGB(0, 0, 0), 0.62)),
	})
	gradient.Rotation = 25
	gradient.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.46)
	stroke.Thickness = 3
	stroke.Parent = frame

	local top = Instance.new("TextLabel")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(0.42, 0, 0.28, 0)
	top.Position = UDim2.new(0.06, 0, 0.06, 0)
	top.Text = title
	top.TextColor3 = Color3.fromRGB(255, 255, 255)
	top.TextScaled = true
	top.Font = Enum.Font.GothamBlack
	top.TextXAlignment = Enum.TextXAlignment.Left
	top.TextStrokeColor3 = Color3.fromRGB(4, 5, 10)
	top.TextStrokeTransparency = 0.18
	top.Parent = frame

	local nameBand = Instance.new("Frame")
	nameBand.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
	nameBand.BackgroundTransparency = 0.08
	nameBand.BorderSizePixel = 0
	nameBand.Position = UDim2.new(0.08, 0, 0.58, 0)
	nameBand.Size = UDim2.new(0.84, 0, 0.26, 0)
	nameBand.Parent = frame

	local bandCorner = Instance.new("UICorner")
	bandCorner.CornerRadius = UDim.new(0.18, 0)
	bandCorner.Parent = nameBand

	local bandStroke = Instance.new("UIStroke")
	bandStroke.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.20)
	bandStroke.Thickness = 2
	bandStroke.Transparency = 0.18
	bandStroke.Parent = nameBand

	local middle = Instance.new("TextLabel")
	middle.BackgroundTransparency = 1
	middle.Size = UDim2.fromScale(1, 1)
	middle.Position = UDim2.fromScale(0, 0)
	middle.Text = subtitle
	middle.TextColor3 = Color3.fromRGB(255, 248, 220)
	middle.TextScaled = true
	middle.Font = Enum.Font.GothamBlack
	middle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	middle.TextStrokeTransparency = 0.38
	middle.Parent = nameBand

	local stripes = Instance.new("Frame")
	stripes.BackgroundTransparency = 0.58
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

local CRACK_LAYOUTS = {
	{ pos = UDim2.fromScale(0.38, 0.22), size = UDim2.fromScale(0.018, 0.30), rotation = -32 },
	{ pos = UDim2.fromScale(0.52, 0.31), size = UDim2.fromScale(0.016, 0.24), rotation = 38 },
	{ pos = UDim2.fromScale(0.30, 0.50), size = UDim2.fromScale(0.016, 0.26), rotation = 24 },
	{ pos = UDim2.fromScale(0.62, 0.50), size = UDim2.fromScale(0.018, 0.32), rotation = -25 },
	{ pos = UDim2.fromScale(0.46, 0.63), size = UDim2.fromScale(0.016, 0.28), rotation = 67 },
	{ pos = UDim2.fromScale(0.70, 0.34), size = UDim2.fromScale(0.014, 0.21), rotation = 18 },
}

local function createPackCrackOverlay(parent, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 0
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui

	local cracks = {}
	for index, spec in ipairs(CRACK_LAYOUTS) do
		local crack = Instance.new("Frame")
		crack.AnchorPoint = Vector2.new(0.5, 0.5)
		crack.BackgroundColor3 = color:Lerp(Color3.fromRGB(255, 255, 255), 0.72)
		crack.BackgroundTransparency = 0.15
		crack.BorderSizePixel = 0
		crack.Position = spec.pos
		crack.Rotation = spec.rotation
		crack.Size = spec.size
		crack.Visible = false
		crack.ZIndex = 5 + index
		crack.Parent = frame

		local branch = Instance.new("Frame")
		branch.AnchorPoint = Vector2.new(0.5, 0.5)
		branch.BackgroundColor3 = crack.BackgroundColor3
		branch.BackgroundTransparency = 0.22
		branch.BorderSizePixel = 0
		branch.Position = UDim2.fromScale(0.5, 0.28)
		branch.Rotation = index % 2 == 0 and -58 or 52
		branch.Size = UDim2.fromScale(0.78, 0.18)
		branch.Parent = crack

		table.insert(cracks, crack)
	end

	return cracks
end

local function updatePackDamageVisuals(plot, integrityRatio)
	if not plot then
		return
	end

	local integrity = math.clamp(integrityRatio or 1, 0, 1)
	plot.activePackIntegrity = integrity

	local cracks = plot.activePackCracks
	if cracks then
		local visibleCount = 0
		if integrity <= 0.70 then
			visibleCount = 2
		end
		if integrity <= 0.40 then
			visibleCount = 4
		end
		if integrity <= 0.10 then
			visibleCount = #cracks
		end

		for index, crack in ipairs(cracks) do
			if crack and crack.Parent then
				crack.Visible = index <= visibleCount
				crack.BackgroundTransparency = integrity <= 0.10 and 0.02 or 0.15
			end
		end
	end

	if plot.activePackLight then
		plot.activePackLight.Range = 12 + ((1 - integrity) * 14)
	end

	if plot.activePackLeakEmitter then
		plot.activePackLeakEmitter.Enabled = integrity <= 0.30 and integrity > 0
		plot.activePackLeakEmitter.Rate = integrity <= 0.10 and 28 or 10
	end
end

local function pulseLight(light, baseBrightness, peakBrightness, duration)
	if not light or not light.Parent then
		return
	end

	light.Brightness = peakBrightness
	task.delay(duration or 0.12, function()
		if light and light.Parent then
			light.Brightness = baseBrightness
		end
	end)
end

local function playPackHitEffect(plot, settleBrightness)
	if not plot or not plot.activePackBody then
		return
	end

	local integrity = plot.activePackIntegrity or 1
	plot.activePackShakeUntil = os.clock() + (integrity <= 0.30 and 0.26 or 0.16)

	if plot.activePackHitEmitter then
		local burstCount = integrity <= 0.30 and 24 or (integrity <= 0.60 and 18 or 14)
		plot.activePackHitEmitter:Emit(burstCount)
	end

	if plot.activePackLeakEmitter and integrity <= 0.40 then
		plot.activePackLeakEmitter:Emit(6)
	end

	if plot.activePackHighlight then
		plot.activePackHighlight.FillTransparency = 0.2
		plot.activePackHighlight.OutlineTransparency = 0.05
		task.delay(0.08, function()
			if plot.activePackHighlight and plot.activePackHighlight.Parent then
				plot.activePackHighlight.FillTransparency = 1
				plot.activePackHighlight.OutlineTransparency = 0.82
			end
		end)
	end

	local baseBrightness = settleBrightness or plot.activePackBaseBrightness or 1.15
	pulseLight(plot.activePackLight, baseBrightness, baseBrightness + 1.25, 0.1)

	for _, part in ipairs(plot.activePackImpactParts or {}) do
		if part and part.Parent then
			local originalSize = part.Size
			local growSize = Vector3.new(originalSize.X + 0.08, originalSize.Y + 0.08, originalSize.Z + 0.08)
			TweenService:Create(part, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = growSize,
			}):Play()
			task.delay(0.07, function()
				if part and part.Parent then
					TweenService:Create(part, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = originalSize,
					}):Play()
				end
			end)
		end
	end
end

local function rollPadPackForPlayer(player)
	local luckLevel = player and getUpgradeLevel(player, "PackSpawnLuck") or 1
	return PackConfig.ChooseSpawnPack(luckLevel)
end

local function getMilestoneId(milestone)
	if not milestone then
		return nil
	end
	return milestone.id or tostring(milestone.threshold)
end

local function getMilestoneById(milestoneId)
	for _, milestone in ipairs(Constants.PackMilestones or {}) do
		if getMilestoneId(milestone) == milestoneId then
			return milestone
		end
	end
	return nil
end

local function buildMilestoneRewardEntry(milestone, repeatCount, totalPacks)
	if not milestone then
		return nil
	end

	local rewardKind = milestone.rewardKind or (milestone.rewardPackId and "pack" or "guarantee")
	local entry = {
		milestoneId = getMilestoneId(milestone),
		kind = rewardKind,
		reward = milestone.reward,
		label = milestone.label,
		threshold = milestone.threshold,
		repeatCount = repeatCount,
		earnedAt = totalPacks,
	}

	if rewardKind == "pack" then
		entry.packId = milestone.rewardPackId
	elseif rewardKind == "guarantee" then
		entry.minRarity = milestone.minRarity
		entry.allowBeyondPackCap = milestone.allowBeyondPackCap == true
	end

	return entry
end

local function serializeMilestoneReward(reward)
	if type(reward) ~= "table" then
		return nil
	end

	local milestone = getMilestoneById(reward.milestoneId) or {}
	local packDef = reward.packId and PackConfig.ById[reward.packId] or nil
	local rewardText = reward.reward or milestone.reward
	if not rewardText and packDef then
		rewardText = packDef.displayName .. " Queued"
	end

	return {
		kind = reward.kind or milestone.rewardKind,
		packId = reward.packId,
		packName = packDef and packDef.displayName or nil,
		minRarity = reward.minRarity or milestone.minRarity,
		reward = rewardText or "Milestone Reward Queued",
		label = reward.label or milestone.label or "REWARD",
		threshold = reward.threshold or milestone.threshold,
		repeatCount = reward.repeatCount,
		earnedAt = reward.earnedAt,
		color = milestone.color or (packDef and packDef.color) or Color3.fromRGB(255, 215, 0),
	}
end

local function getQueuedMilestoneCount(player)
	if type(DataService.GetMilestoneRewardQueueLength) == "function" then
		return DataService.GetMilestoneRewardQueueLength(player)
	end
	return 0
end

local function getPackPurchaseCooldownRemaining(data, packDef)
	local cooldown = math.max(0, math.floor(tonumber(packDef and packDef.purchaseCooldownSeconds) or 0))
	if cooldown <= 0 then
		return 0, 0
	end

	local purchaseHistory = type(data and data.limitedPackPurchases) == "table" and data.limitedPackPurchases or {}
	local lastPurchase = tonumber(purchaseHistory[packDef.id]) or 0
	return math.max(0, cooldown - (os.time() - lastPurchase)), cooldown
end

local function buildPackPurchaseCooldownPayload(player)
	local data = DataService.GetData(player)
	local cooldowns = {}
	if not data then
		return cooldowns
	end

	for _, packDef in ipairs(PackConfig.ShopOrder or {}) do
		local remaining, cooldown = getPackPurchaseCooldownRemaining(data, packDef)
		if cooldown > 0 then
			cooldowns[packDef.id] = {
				remaining = remaining,
				cooldown = cooldown,
			}
		end
	end

	return cooldowns
end

local function fireMilestoneRewards(player, rewards)
	if not player or type(rewards) ~= "table" or #rewards == 0 then
		return
	end

	local serializedRewards = {}
	for _, reward in ipairs(rewards) do
		local serialized = serializeMilestoneReward(reward)
		if serialized then
			table.insert(serializedRewards, serialized)
		end
	end

	if #serializedRewards == 0 then
		return
	end

	MilestoneRewardEvent:FireClient(player, {
		reward = serializedRewards[1],
		rewards = serializedRewards,
		queueLength = getQueuedMilestoneCount(player),
	})
end

local function refreshPackQueueBoard(player)
	local plot = BaseService.GetPlot(player)
	if not plot then
		return
	end

	local totalPacks = DataService.GetTotalPacksOpened(player)
	local data = DataService.GetData(player)
	BaseService.UpdatePackMilestone(plot, totalPacks, data and data.claimedMilestones or {}, getQueuedMilestoneCount(player))
end

local function queuePackRewardForPad(player, packId, label, rewardText)
	local packDef = PackConfig.ById[packId]
	if not player or not packDef then
		return nil
	end

	local queuedReward = {
		milestoneId = string.lower(label or "shop") .. "_" .. tostring(packId) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
		kind = "pack",
		packId = packId,
		reward = rewardText or (packDef.displayName .. " Queued"),
		label = label or "SHOP",
		threshold = 0,
		repeatCount = 1,
		earnedAt = DataService.GetTotalPacksOpened(player),
	}

	if not DataService.EnqueueMilestoneReward(player, queuedReward) then
		return nil
	end

	fireMilestoneRewards(player, { queuedReward })
	refreshPackQueueBoard(player)
	return queuedReward
end

local function getQuestDayKey()
	local resetSeconds = Constants.QuestResetSeconds or (24 * 60 * 60)
	return math.floor(os.time() / resetSeconds)
end

local function getQuestResetRemaining()
	local resetSeconds = Constants.QuestResetSeconds or (24 * 60 * 60)
	return resetSeconds - (os.time() % resetSeconds)
end

local function getQuestDefinition(questId)
	for _, quest in ipairs(Constants.Quests or {}) do
		if quest.id == questId then
			return quest
		end
	end
	return nil
end

local function getQuestData(player)
	local data = DataService.GetData(player)
	if not data then
		return nil
	end

	local dayKey = getQuestDayKey()
	if type(data.questData) ~= "table" or data.questData.dayKey ~= dayKey then
		data.questData = {
			dayKey = dayKey,
			progress = {},
			claimed = {},
		}
		DataService.MarkDirty(player)
	end

	if type(data.questData.progress) ~= "table" then
		data.questData.progress = {}
		DataService.MarkDirty(player)
	end
	if type(data.questData.claimed) ~= "table" then
		data.questData.claimed = {}
		DataService.MarkDirty(player)
	end

	return data.questData
end

local function formatQuestReward(quest)
	local rewardText = {}

	local function addAmountReward(amount, singular, plural)
		local value = math.max(0, math.floor(tonumber(amount) or 0))
		if value <= 0 then
			return
		end

		local prefix = #rewardText == 0 and "+" or ""
		table.insert(rewardText, prefix .. Utils.FormatNumber(value) .. " " .. (value == 1 and singular or plural))
	end

	addAmountReward(quest.rewardFans, "Fan", "Fans")
	addAmountReward(quest.rewardGems, "Gem", "Gems")
	if quest.rewardPackId then
		local packDef = PackConfig.ById[quest.rewardPackId]
		table.insert(rewardText, (packDef and packDef.displayName or "Reward Pack") .. " queued")
	end
	return #rewardText > 0 and table.concat(rewardText, " + ") or "Reward"
end

local function serializeQuest(quest, questData)
	local target = math.max(1, math.floor(tonumber(quest.target) or 1))
	local progress = math.clamp(math.floor(tonumber(questData.progress[quest.id]) or 0), 0, target)
	local claimed = questData.claimed[quest.id] == true
	local rewardPackDef = quest.rewardPackId and PackConfig.ById[quest.rewardPackId] or nil

	return {
		id = quest.id,
		title = quest.title,
		description = quest.description,
		progress = progress,
		target = target,
		claimed = claimed,
		claimable = progress >= target and not claimed,
		rewardFans = quest.rewardFans or 0,
		rewardGems = quest.rewardGems or 0,
		rewardPackId = quest.rewardPackId,
		rewardPackName = rewardPackDef and rewardPackDef.displayName or nil,
		rewardText = formatQuestReward(quest),
	}
end

local function buildQuestPayload(player)
	local questData = getQuestData(player)
	local payload = {
		resetRemaining = getQuestResetRemaining(),
		quests = {},
		completedCount = 0,
		claimableCount = 0,
	}
	if not questData then
		return payload
	end

	for _, quest in ipairs(Constants.Quests or {}) do
		local serialized = serializeQuest(quest, questData)
		if serialized.claimed then
			payload.completedCount += 1
		elseif serialized.claimable then
			payload.claimableCount += 1
		end
		table.insert(payload.quests, serialized)
	end

	return payload
end

local function pushQuestPayload(player)
	QuestUpdatedEvent:FireClient(player, buildQuestPayload(player))
end

local function addQuestProgress(player, action, amount)
	local questData = getQuestData(player)
	if not questData or not action then
		return false
	end

	local delta = math.max(1, math.floor(tonumber(amount) or 1))
	local changed = false
	for _, quest in ipairs(Constants.Quests or {}) do
		if quest.action == action and questData.claimed[quest.id] ~= true then
			local target = math.max(1, math.floor(tonumber(quest.target) or 1))
			local current = math.floor(tonumber(questData.progress[quest.id]) or 0)
			local nextValue = math.min(target, current + delta)
			if nextValue ~= current then
				questData.progress[quest.id] = nextValue
				changed = true
			end
		end
	end

	if changed then
		DataService.MarkDirty(player)
		pushQuestPayload(player)
	end
	return changed
end

local function claimQuestReward(player, questId)
	local quest = getQuestDefinition(questId)
	local questData = getQuestData(player)
	if not quest or not questData then
		return { success = false, error = "Quest is not available." }
	end

	if questData.claimed[quest.id] == true then
		return { success = false, error = "Quest already claimed.", quests = buildQuestPayload(player) }
	end

	local target = math.max(1, math.floor(tonumber(quest.target) or 1))
	local progress = math.floor(tonumber(questData.progress[quest.id]) or 0)
	if progress < target then
		return { success = false, error = "Quest is not complete yet.", quests = buildQuestPayload(player) }
	end

	local rewardPackQueued = nil
	if quest.rewardPackId then
		local packDef = PackConfig.ById[quest.rewardPackId]
		if not packDef then
			return { success = false, error = "Quest reward is not ready." }
		end
		rewardPackQueued = queuePackRewardForPad(player, quest.rewardPackId, "QUEST", packDef.displayName .. " Queued")
		if not rewardPackQueued then
			return { success = false, error = "Quest reward could not be queued." }
		end
	end

	local rewardFans = math.max(0, math.floor(tonumber(quest.rewardFans) or 0))
	if rewardFans > 0 then
		EconomyService.AddCoins(player, rewardFans)
	end

	local rewardGems = math.max(0, math.floor(tonumber(quest.rewardGems) or 0))
	if rewardGems > 0 then
		DataService.AddGems(player, rewardGems)
	end

	if rewardFans > 0 or rewardGems > 0 then
		UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player), DataService.GetGems(player))
	end

	questData.claimed[quest.id] = true
	DataService.MarkDirty(player)
	pushQuestPayload(player)
	sendHint(player, "Quest complete: " .. tostring(quest.title or "Reward") .. ".")

	return {
		success = true,
		questId = quest.id,
		rewardFans = rewardFans,
		rewardGems = rewardGems,
		rewardPackQueued = rewardPackQueued ~= nil,
		newCoins = DataService.GetCoins(player),
		newGems = DataService.GetGems(player),
		queuedRewardCount = getQueuedMilestoneCount(player),
		quests = buildQuestPayload(player),
	}
end

local function getCardById(cardId)
	return cardId and CardData.ById[tonumber(cardId)] or nil
end

local function serializeCardForClient(card)
	if not card then
		return nil
	end
	return {
		id = card.id,
		name = card.name,
		nation = card.nation,
		position = card.position,
		rarity = card.rarity,
		club = card.club,
		fansPerSecond = Utils.CalculateFansPerSecond(card),
		sellValue = Utils.GetSellValue(card),
	}
end

-- ── Milestone reward queue tracking ───────────────────────────────────────────
local function checkAndGrantMilestones(player, totalPacks)
	local data = DataService.GetData(player)
	if not data then return {} end
	if type(data.claimedMilestones) ~= "table" then
		data.claimedMilestones = {}
	end

	local triggeredRewards = {}
	for _, milestone in ipairs(Constants.PackMilestones) do
		local threshold = tonumber(milestone.threshold)
		if not threshold or threshold <= 0 then
			continue
		end

		local key = getMilestoneId(milestone) or tostring(threshold)
		local timesEarned = math.floor((totalPacks or 0) / threshold)
		local timesClaimed = data.claimedMilestones[key]
		if timesClaimed == true then timesClaimed = 1 end
		if timesClaimed == nil then
			timesClaimed = math.floor(math.max(0, (totalPacks or 0) - 1) / threshold)
		else
			timesClaimed = tonumber(timesClaimed) or 0
		end

		while timesClaimed < timesEarned do
			timesClaimed += 1
			data.claimedMilestones[key] = timesClaimed
			local reward = buildMilestoneRewardEntry(milestone, timesClaimed, totalPacks)
			if reward then
				table.insert(triggeredRewards, reward)
			end
			DataService.MarkDirty(player)
		end

		data.claimedMilestones[key] = timesClaimed
	end

	table.sort(triggeredRewards, function(a, b)
		return (tonumber(a.threshold) or 0) > (tonumber(b.threshold) or 0)
	end)

	for _, reward in ipairs(triggeredRewards) do
		DataService.EnqueueMilestoneReward(player, reward)
	end

	return triggeredRewards
end

local function getBestInventoryCard(player)
	local inventory = DataService.GetInventory(player)
	local bestCard

	for key, amount in pairs(inventory) do
		if amount > 0 then
			local card = getCardById(key)
			if card then
				local income = Utils.CalculateFansPerSecond(card)
				local bestIncome = bestCard and Utils.CalculateFansPerSecond(bestCard) or -math.huge
				if not bestCard or income > bestIncome or (income == bestIncome and card.name < bestCard.name) then
					bestCard = card
				end
			end
		end
	end

	return bestCard
end

local function getDisplayedIncomePerSecond(player)
	local displayedCards = DataService.GetDisplayedCards(player)
	local total = 0
	local multiplier = getFanEarningsMultiplier(player)

	for _, cardId in pairs(displayedCards) do
		local card = getCardById(cardId)
		if card then
			total += math.floor(Utils.CalculateFansPerSecond(card) * multiplier)
		end
	end

	return total
end

local function getCardIncome(player, card)
	if not card then
		return 0
	end

	local sourceCard = getCardById(card.id) or card
	return math.floor(Utils.CalculateFansPerSecond(sourceCard) * getFanEarningsMultiplier(player))
end

local function refreshPlotDisplayState(player, plot)
	if not player or not plot then
		return
	end

	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		local displayedCardId = DataService.GetDisplayedCard(player, slot.slotIndex)
		local displayedCard = getCardById(displayedCardId)
		if displayedCard then
			BaseService.UpdateDisplaySlot(slot, displayedCard, getCardIncome(player, displayedCard))
		else
			local bestInventoryCard = getBestInventoryCard(player)
			BaseService.SetDisplaySlotAddReady(slot, bestInventoryCard and "Choose Player" or "Inventory Empty", bestInventoryCard ~= nil)
		end
	end
end

local function getFirstEmptyDisplaySlot(player, plot)
	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		if not DataService.GetDisplayedCard(player, slot.slotIndex) then
			return slot
		end
	end

	return nil
end

local function getDisplaySlotByIndex(plot, slotIndex)
	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		if slot.slotIndex == slotIndex then
			return slot
		end
	end

	return nil
end

local SLOT_FLOOR_Y_TOLERANCE = 7

local function isPlayerOnDisplaySlotFloor(player, slot)
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local slotPart = slot and (slot.top or slot.base)
	if not rootPart or not slotPart then
		return false
	end

	return math.abs(rootPart.Position.Y - slotPart.Position.Y) <= SLOT_FLOOR_Y_TOLERANCE
end

local function placeCardOnDisplay(player, plot, slot, cardId)
	local card = getCardById(cardId)
	if not card or not slot then
		return false
	end

	DataService.SetDisplayedCard(player, slot.slotIndex, card.id)
	BaseService.UpdateDisplaySlot(slot, card, getCardIncome(player, card))
	addQuestProgress(player, "placeCard", 1)
	return true
end

local function autoStorePulledCard(player, plot, card)
	if not player or not plot or not card then
		return {
			storedInInventory = true,
			slotIndex = nil,
			slotWorldPosition = nil,
		}
	end

	local emptySlot = getFirstEmptyDisplaySlot(player, plot)
	if emptySlot then
		placeCardOnDisplay(player, plot, emptySlot, card.id)
		refreshPlotDisplayState(player, plot)
		return {
			storedInInventory = false,
			slotIndex = emptySlot.slotIndex,
			slotWorldPosition = emptySlot.top.Position + Vector3.new(0, 4.4, 0),
		}
	end

	DataService.AddCard(player, card.id)
	refreshPlotDisplayState(player, plot)
	return {
		storedInInventory = true,
		slotIndex = nil,
		slotWorldPosition = nil,
	}
end

local function moveDisplayedCardToInventory(player, plot, slot)
	local cardId = DataService.GetDisplayedCard(player, slot.slotIndex)
	local card = getCardById(cardId)
	if not card then
		return false, "There is no player on that slot."
	end

	DataService.ClearDisplayedCard(player, slot.slotIndex)
	DataService.AddCard(player, card.id)
	refreshPlotDisplayState(player, plot)
	return true, card
end

local function addInventoryCardToDisplay(player, plot, slot, cardId)
	local card = getCardById(cardId)
	if not card then
		return false, "Choose a valid player."
	end

	if DataService.GetDisplayedCard(player, slot.slotIndex) then
		return false, "That display slot is already occupied."
	end

	if not DataService.RemoveCard(player, card.id) then
		return false, "That player is no longer in your inventory."
	end

	placeCardOnDisplay(player, plot, slot, card.id)
	refreshPlotDisplayState(player, plot)
	return true, card
end

local function clearPlotPack(plot)
	if plot.activePackModel and plot.activePackModel.Parent then
		plot.activePackModel:Destroy()
	end
	plot.activePackModel = nil
	plot.activePackDef = nil
	plot.activePackBody = nil
	plot.activePackLight = nil
	plot.activePackBaseBrightness = nil
	plot.activePackHitsRemaining = nil
	plot.activePackMaxHits = nil
	plot.activePackHitEmitter = nil
	plot.activePackLeakEmitter = nil
	plot.activePackHighlight = nil
	plot.activePackImpactParts = nil
	plot.activePackCracks = nil
	plot.activePackIntegrity = nil
	plot.activePackShakeUntil = nil
	plot.activePackMilestoneReward = nil
	plot.activePackMilestoneGuarantee = nil
	plot.isOpeningPack = nil
end

local function popNextMilestoneSpawnReward(player)
	if type(DataService.PopMilestoneReward) ~= "function" then
		return nil, nil, nil
	end

	while true do
		local reward = DataService.PopMilestoneReward(player)
		if not reward then
			return nil, nil, nil
		end

		local serialized = serializeMilestoneReward(reward)
		if reward.kind == "pack" then
			local packDef = PackConfig.ById[reward.packId]
			if packDef then
				return packDef, reward, serialized
			end
		elseif reward.kind == "guarantee" and reward.minRarity then
			local packDef = rollPadPackForPlayer(player)
			return packDef, reward, serialized
		end
	end
end

local function spawnPackForPlot(plot)
	if not plot or not plot.ownerPlayer then
		return
	end

	clearPlotPack(plot)

	local rewardPackDef, milestoneReward, milestoneRewardPayload = popNextMilestoneSpawnReward(plot.ownerPlayer)
	local packDef = rewardPackDef or rollPadPackForPlayer(plot.ownerPlayer)
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
	cardBody.Color = packDef.color:Lerp(Color3.fromRGB(6, 8, 14), 0.48)
	cardBody.Size = Vector3.new(5.4, 8, 0.3)
	cardBody.CFrame = rootCFrame
	cardBody.Parent = model

	local topCap = Instance.new("WedgePart")
	topCap.Name = "TopCap"
	topCap.Anchored = true
	topCap.Material = Enum.Material.SmoothPlastic
	topCap.Color = packDef.color:Lerp(Color3.fromRGB(10, 12, 20), 0.36)
	topCap.Size = Vector3.new(5.4, 1.4, 0.3)
	topCap.CFrame = cardBody.CFrame * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
	topCap.Parent = model

	local bottomCap = Instance.new("WedgePart")
	bottomCap.Name = "BottomCap"
	bottomCap.Anchored = true
	bottomCap.Material = Enum.Material.SmoothPlastic
	bottomCap.Color = packDef.color:Lerp(Color3.fromRGB(4, 5, 10), 0.45)
	bottomCap.Size = Vector3.new(5.4, 1.6, 0.3)
	bottomCap.CFrame = cardBody.CFrame * CFrame.new(0, -4.8, 0)
	bottomCap.Parent = model

	local identityParts = {}
	local function addIdentityPart(name, size, offset, material, color, transparency)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Material = material or Enum.Material.Neon
		part.Color = color or packDef.color
		part.Transparency = transparency or 0
		part.Size = size
		part.CFrame = cardBody.CFrame * offset
		part.Parent = model
		table.insert(identityParts, {
			part = part,
			offset = offset,
		})
		return part
	end

	addIdentityPart("LeftColorRail", Vector3.new(0.22, 8.9, 0.42), CFrame.new(-2.88, 0, 0), Enum.Material.Neon, packDef.color)
	addIdentityPart("RightColorRail", Vector3.new(0.22, 8.9, 0.42), CFrame.new(2.88, 0, 0), Enum.Material.Neon, packDef.color)
	addIdentityPart("TopColorRail", Vector3.new(5.9, 0.20, 0.42), CFrame.new(0, 4.08, 0), Enum.Material.Neon, packDef.color)
	addIdentityPart("BottomColorRail", Vector3.new(5.9, 0.20, 0.42), CFrame.new(0, -4.08, 0), Enum.Material.Neon, packDef.color)
	addIdentityPart("PackSpineGlow", Vector3.new(0.12, 7.2, 0.52), CFrame.new(-2.50, 0, 0), Enum.Material.Neon, packDef.color:Lerp(Color3.fromRGB(255, 255, 255), 0.28), 0.12)

	local glow = Instance.new("PointLight")
	glow.Color = packDef.color
	glow.Range = 12
	glow.Brightness = 1.15
	glow.Parent = cardBody

	local hitAttachment = Instance.new("Attachment")
	hitAttachment.Name = "HitAttachment"
	hitAttachment.Parent = cardBody

	local hitEmitter = Instance.new("ParticleEmitter")
	hitEmitter.Name = "HitBurst"
	hitEmitter.Enabled = false
	hitEmitter.Rate = 0
	hitEmitter.Lifetime = NumberRange.new(0.16, 0.28)
	hitEmitter.Speed = NumberRange.new(2.5, 6.5)
	hitEmitter.SpreadAngle = Vector2.new(38, 38)
	hitEmitter.Drag = 4
	hitEmitter.LightEmission = 1
	hitEmitter.LightInfluence = 0
	hitEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 212)),
		ColorSequenceKeypoint.new(0.5, packDef.color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	hitEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.26),
		NumberSequenceKeypoint.new(0.35, 0.42),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	hitEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.6, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	hitEmitter.Parent = hitAttachment

	local leakEmitter = Instance.new("ParticleEmitter")
	leakEmitter.Name = "CrackLeak"
	leakEmitter.Enabled = false
	leakEmitter.Rate = 10
	leakEmitter.Lifetime = NumberRange.new(0.26, 0.54)
	leakEmitter.Speed = NumberRange.new(0.45, 1.6)
	leakEmitter.SpreadAngle = Vector2.new(72, 72)
	leakEmitter.Drag = 2
	leakEmitter.LightEmission = 1
	leakEmitter.LightInfluence = 0
	leakEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.45, packDef.color:Lerp(Color3.fromRGB(255, 255, 255), 0.2)),
		ColorSequenceKeypoint.new(1, packDef.color),
	})
	leakEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(0.45, 0.36),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	leakEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.65, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	leakEmitter.Parent = hitAttachment

	local hitHighlight = Instance.new("Highlight")
	hitHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	hitHighlight.FillColor = packDef.color
	hitHighlight.FillTransparency = 1
	hitHighlight.OutlineColor = Color3.fromRGB(255, 245, 190)
	hitHighlight.OutlineTransparency = 0.82
	hitHighlight.Parent = model

	local packTypeLabel = type(packDef.playerPick) == "table" and "PLAYER PICK" or "1 CARD"
	createSurfaceLabel(Enum.NormalId.Front, packTypeLabel, packDef.displayName, packDef.color, cardBody)
	createSurfaceLabel(Enum.NormalId.Back, packTypeLabel, packDef.displayName, packDef.color, cardBody)
	local crackLines = createPackCrackOverlay(cardBody, packDef.color)

	-- (pack health is shown in the padGui billboard — no floating bar needed)

	-- Continuous idle: slow spin + gentle float.  All three parts updated together so
	-- they never drift apart (the old tween only moved cardBody, leaving caps behind).
	local packOriginX = basePosition.X
	local packOriginY = basePosition.Y + 5.4
	local packOriginZ = basePosition.Z
	local packSpinAngle = 0
	task.spawn(function()
		while model.Parent do
			local now = os.clock()
			local integrity = plot.activePackIntegrity or 1
			local stress = 1 - integrity
			local spinSpeed = 34 + (stress * 54) + (integrity <= 0.30 and 28 or 0)
			packSpinAngle = packSpinAngle + math.rad(spinSpeed) / 30

			local floatY = packOriginY + math.sin(now * (1.3 + stress * 1.4)) * (0.30 + stress * 0.16)
			local hitShake = now < (plot.activePackShakeUntil or 0) and (0.12 + stress * 0.24) or 0
			local criticalShake = integrity <= 0.10 and 0.10 or 0
			local shake = hitShake + criticalShake
			local shakeX = math.sin(now * 42) * shake * plot.facingDirection
			local shakeZ = math.cos(now * 37) * shake
			local leanX = math.sin(now * 17) * math.rad(stress * 4)
			local leanZ = math.cos(now * 19) * math.rad(stress * 3)
			local baseCF = CFrame.new(packOriginX + shakeX, floatY, packOriginZ + shakeZ)
				* CFrame.Angles(leanX, packSpinAngle, leanZ)
			if model.Parent then
				cardBody.CFrame = baseCF
				topCap.CFrame = baseCF * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
				bottomCap.CFrame = baseCF * CFrame.new(0, -4.8, 0)
				for _, identity in ipairs(identityParts) do
					if identity.part and identity.part.Parent then
						identity.part.CFrame = baseCF * identity.offset
					end
				end
			end
			task.wait(1 / 30)
		end
	end)

	plot.activePackModel = model
	plot.activePackDef = packDef
	plot.activePackBody = cardBody
	plot.activePackLight = glow
	plot.activePackBaseBrightness = glow.Brightness
	plot.activePackMaxHits = packDef.hitsRequired or 3
	plot.activePackHitsRemaining = plot.activePackMaxHits
	plot.activePackHitEmitter = hitEmitter
	plot.activePackLeakEmitter = leakEmitter
	plot.activePackHighlight = hitHighlight
	plot.activePackImpactParts = { cardBody, topCap, bottomCap }
	for _, identity in ipairs(identityParts) do
		table.insert(plot.activePackImpactParts, identity.part)
	end
	plot.activePackCracks = crackLines
	plot.activePackIntegrity = 1
	plot.activePackShakeUntil = 0
	plot.activePackMilestoneReward = milestoneReward
	if milestoneReward and milestoneReward.kind == "guarantee" then
		plot.activePackMilestoneGuarantee = {
			minRarity = milestoneReward.minRarity,
			reward = milestoneReward.reward,
			label = milestoneReward.label,
			allowBeyondPackCap = milestoneReward.allowBeyondPackCap == true,
		}
	end

	BaseService.SetPlotPadHealth(plot, packDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, packDef.color)
	do
		local totalPacks = DataService.GetTotalPacksOpened(plot.ownerPlayer)
		local data = DataService.GetData(plot.ownerPlayer)
		BaseService.UpdatePackMilestone(plot, totalPacks, data and data.claimedMilestones or {}, getQueuedMilestoneCount(plot.ownerPlayer))
	end
	if milestoneRewardPayload then
		local sourceLabel = string.upper(tostring(milestoneRewardPayload.label or "REWARD"))
		local packName = packDef.displayName or "Reward Pack"
		if sourceLabel == "SHOP" then
			sendHint(plot.ownerPlayer, "Bought pack spawned: " .. packName .. ".")
		elseif sourceLabel == "DAILY" then
			sendHint(plot.ownerPlayer, "Daily pack spawned: " .. packName .. ".")
		elseif sourceLabel == "QUEST" then
			sendHint(plot.ownerPlayer, "Quest pack spawned: " .. packName .. ".")
		else
			sendHint(plot.ownerPlayer, "Reward pack spawned: " .. packName .. ".")
		end
	end
end

local function recordPlayerPickCard(player, card)
	local data = DataService.GetData(player)
	if not data or not card then
		return false
	end

	data.totalCardsOpened = (data.totalCardsOpened or 0) + 1
	if type(DataService.RecordCardPacked) == "function" then
		DataService.RecordCardPacked(player, card.id)
	end
	addQuestProgress(player, "collectCard", 1)
	DataService.MarkDirty(player)
	return true
end

local function getBestPendingPickCard(pendingPick)
	local bestCard = nil
	local bestIncome = -math.huge
	for _, option in ipairs(pendingPick and pendingPick.pickOptions or {}) do
		local card = getCardById(option and option.id)
		local income = card and Utils.CalculateFansPerSecond(card) or -math.huge
		if card and income > bestIncome then
			bestCard = card
			bestIncome = income
		end
	end
	return bestCard
end

local function claimPendingPlayerPickToInventory(player)
	local pendingPick = pendingPlayerPicks[player]
	if not pendingPick then
		return false
	end

	local card = getBestPendingPickCard(pendingPick)
	pendingPlayerPicks[player] = nil
	playerPickLocks[player] = nil
	if not card then
		return false
	end

	recordPlayerPickCard(player, card)
	DataService.AddCard(player, card.id)
	return true
end

local function awardPendingPlayerPick(player, optionIndex)
	local pendingPick = pendingPlayerPicks[player]
	if not pendingPick then
		return false, { error = "No player pick is waiting." }
	end

	local chosenIndex = math.floor(tonumber(optionIndex) or 0)
	local option = pendingPick.pickOptions and pendingPick.pickOptions[chosenIndex]
	local card = getCardById(option and option.id)
	if not card then
		return false, { error = "Choose one of the shown players." }
	end

	pendingPlayerPicks[player] = nil
	recordPlayerPickCard(player, card)

	local plot = BaseService.GetPlot(player)
	local storageResult
	if plot and plot.ownerPlayer == player then
		local storageOk, storageOrError = pcall(autoStorePulledCard, player, plot, card)
		if storageOk then
			storageResult = storageOrError
		else
			warn("[UnboxAFootballer] Player pick auto-store failed; falling back to inventory:", storageOrError)
			DataService.AddCard(player, card.id)
			refreshPlotDisplayState(player, plot)
			storageResult = {
				storedInInventory = true,
				slotIndex = nil,
				slotWorldPosition = nil,
			}
		end
	else
		DataService.AddCard(player, card.id)
		storageResult = {
			storedInInventory = true,
			slotIndex = nil,
			slotWorldPosition = nil,
		}
	end

	local serializedCard = serializeCardForClient(card)
	local passiveIncome = getCardIncome(player, card)
	PackOpenedEvent:FireClient(player, {
		success = true,
		packId = pendingPick.packId,
		packName = pendingPick.packName,
		newCoins = DataService.GetCoins(player),
		card = serializedCard,
		storedInInventory = storageResult.storedInInventory,
		slotIndex = storageResult.slotIndex,
		slotWorldPosition = storageResult.slotWorldPosition,
		packWorldPosition = pendingPick.packWorldPosition,
		coinsPerSecond = passiveIncome,
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	})

	if storageResult.storedInInventory then
		sendHint(player, card.name .. " went to inventory from your player pick.")
	else
		sendHint(player, card.name .. " is now earning +" .. tostring(passiveIncome) .. "/s on display slot " .. tostring(storageResult.slotIndex) .. ".")
	end

	if plot and plot.ownerPlayer == player then
		BaseService.SetPlotPadStatus(plot, "Rolling Next Pack", "Another free pack is spawning", pendingPick.packColor)
		local respawnDelay = computeSpawnDelay(getUpgradeLevel(player, "PackSpawnRate"))
		task.delay(respawnDelay, function()
			if plot.ownerPlayer == player then
				spawnPackForPlot(plot)
			end
		end)
	end

	return true, {
		success = true,
		selectedCardId = card.id,
		newCoins = DataService.GetCoins(player),
	}
end

-- Reusable function so we can wire up prompt handlers for slots added after startup
-- (e.g. upper-floor slots unlocked by rebirth or loaded from saved data)
local function connectSlotPrompt(plot, slot)
	slot.prompt.Triggered:Connect(function(player)
		if plot.ownerPlayer ~= player then
			PackOpenFailedEvent:FireClient(player, {
				error = (plot.ownerPlayer and plot.ownerPlayer.DisplayName or "Another player") .. "'s display slot is on this base.",
			})
			return
		end

		if not isPlayerOnDisplaySlotFloor(player, slot) then
			PackOpenFailedEvent:FireClient(player, {
				error = "Go to that floor to use this display slot.",
			})
			return
		end

		if DataService.GetDisplayedCard(player, slot.slotIndex) then
			local ok, cardOrError = moveDisplayedCardToInventory(player, plot, slot)
			if ok then
				sendHint(player, cardOrError.name .. " moved into your inventory. Hold E on this slot to place a stored player.")
			else
				PackOpenFailedEvent:FireClient(player, { error = cardOrError })
			end
		else
			if not getBestInventoryCard(player) then
				PackOpenFailedEvent:FireClient(player, {
					error = "You do not have a stored player to add.",
				})
				return
			end

			OpenSlotPickerEvent:FireClient(player, {
				slotIndex = slot.slotIndex,
			})
			sendHint(player, "Choose a stored player for display slot " .. tostring(slot.slotIndex) .. ".")
		end
	end)
end

local function getEffectiveDisplaySlotCount(player)
	local data = DataService.GetData(player)
	return math.min(data and data.baseSlots or Constants.Rebirth.BaseSlots, Constants.Rebirth.MaxSlots)
end

local function syncRebirthMultiplierBadge(player, plot)
	if not player or not plot then
		return
	end

	local data = DataService.GetData(player)
	local multiplier = RebirthService.GetFanMultiplier(data and data.rebirthTier or 0)
	BaseService.UpdateRebirthMultiplier(plot, multiplier)
end

local function syncDisplaySlotsForPlayer(player, plot)
	if not player or not plot then
		return
	end

	local data = DataService.GetData(player)
	local slotCount = getEffectiveDisplaySlotCount(player)
	local visualTier = math.max(data and data.rebirthTier or 0, slotCount > Constants.BaseLayout.DisplaySlotCount and 1 or 0)

	BaseService.SetDisplaySlotLimit(plot, slotCount)
	BaseService.UpdateStadiumTier(plot, visualTier)
	for slotIndex = Constants.BaseLayout.DisplaySlotCount + 1, slotCount do
		local newSlot = BaseService.AddDisplaySlot(plot, slotIndex)
		if newSlot then
			connectSlotPrompt(plot, newSlot)
		end
	end
	syncRebirthMultiplierBadge(player, plot)
	refreshPlotDisplayState(player, plot)
end

local function broadcastServerPackMessage(message, accent)
	for _, player in ipairs(Players:GetPlayers()) do
		sendHint(player, message, {
			accent = accent or (Constants.ServerPack and Constants.ServerPack.Color) or Color3.fromRGB(96, 220, 255),
		})
	end
end

local function getServerPackParent()
	local bases = Workspace:FindFirstChild("Bases")
	local fanZone = bases and bases:FindFirstChild("FanZone")
	return fanZone or Workspace
end

local function countServerPackQualified(state)
	local minHits = math.max(1, math.floor(tonumber(Constants.ServerPack.MinimumHitsForReward) or 3))
	local count = 0
	for _, entry in pairs(state and state.participants or {}) do
		if entry.player and entry.player.Parent and (entry.hits or 0) >= minHits then
			count += 1
		end
	end
	return count
end

local function updateServerPackBillboard(state)
	if not state or not state.healthText or not state.progressFill then
		return
	end

	local maxHealth = math.max(1, tonumber(state.maxHealth) or 1)
	local health = math.max(0, tonumber(state.health) or 0)
	local ratio = math.clamp(health / maxHealth, 0, 1)
	local minHits = math.max(1, math.floor(tonumber(Constants.ServerPack.MinimumHitsForReward) or 3))
	local qualified = countServerPackQualified(state)

	state.healthText.Text = "HEALTH " .. Utils.FormatNumber(math.ceil(health)) .. " / " .. Utils.FormatNumber(maxHealth)
	state.progressFill.Size = UDim2.fromScale(ratio, 1)
	if state.helperText then
		state.helperText.Text = tostring(minHits) .. " HITS TO CLAIM  |  " .. tostring(qualified) .. " QUALIFIED"
	end
end

local function createServerPackBillboard(state, body, packDef, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ServerPackBillboard"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 230
	billboard.Size = UDim2.fromOffset(360, 128)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 8.6, 0)
	billboard.Parent = body

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(6, 10, 20)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Transparency = 0.08
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(0.9, 0, 0.26, 0)
	title.Position = UDim2.new(0.05, 0, 0.08, 0)
	title.Text = string.upper(packDef.displayName or "SERVER PACK")
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = frame

	local healthText = Instance.new("TextLabel")
	healthText.BackgroundTransparency = 1
	healthText.Size = UDim2.new(0.9, 0, 0.19, 0)
	healthText.Position = UDim2.new(0.05, 0, 0.38, 0)
	healthText.TextColor3 = Color3.fromRGB(214, 232, 255)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.GothamBold
	healthText.Parent = frame

	local progressBack = Instance.new("Frame")
	progressBack.BackgroundColor3 = Color3.fromRGB(16, 21, 34)
	progressBack.BorderSizePixel = 0
	progressBack.Size = UDim2.new(0.84, 0, 0.12, 0)
	progressBack.Position = UDim2.new(0.08, 0, 0.62, 0)
	progressBack.Parent = frame
	Instance.new("UICorner", progressBack).CornerRadius = UDim.new(1, 0)

	local progressFill = Instance.new("Frame")
	progressFill.BackgroundColor3 = color
	progressFill.BorderSizePixel = 0
	progressFill.Size = UDim2.fromScale(1, 1)
	progressFill.Parent = progressBack
	Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

	local helperText = Instance.new("TextLabel")
	helperText.BackgroundTransparency = 1
	helperText.Size = UDim2.new(0.9, 0, 0.18, 0)
	helperText.Position = UDim2.new(0.05, 0, 0.78, 0)
	helperText.TextColor3 = Color3.fromRGB(255, 225, 96)
	helperText.TextScaled = true
	helperText.Font = Enum.Font.GothamBlack
	helperText.Parent = frame

	state.healthText = healthText
	state.progressFill = progressFill
	state.helperText = helperText
	updateServerPackBillboard(state)
end

local function createServerPackModel(state)
	local config = Constants.ServerPack or {}
	local packDef = PackConfig.ById.ServerPack
	if not packDef then
		return nil
	end

	local color = config.Color or packDef.color or Color3.fromRGB(96, 220, 255)
	local parent = getServerPackParent()
	local model = Instance.new("Model")
	model.Name = "ServerPackEvent"
	model.Parent = parent

	local groundPosition = config.Position or Vector3.new(0, 0, -82)
	local centerPosition = Vector3.new(groundPosition.X, 7.2, groundPosition.Z)
	local rootCFrame = CFrame.new(centerPosition) * CFrame.Angles(0, math.rad(180), 0)

	local plinth = Instance.new("Part")
	plinth.Name = "ServerPackEventPad"
	plinth.Anchored = true
	plinth.CanCollide = false
	plinth.CanTouch = false
	plinth.CanQuery = false
	plinth.Shape = Enum.PartType.Cylinder
	plinth.Material = Enum.Material.Neon
	plinth.Color = color
	plinth.Transparency = 0.45
	plinth.Size = Vector3.new(0.18, 15, 15)
	plinth.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.36, 0)) * CFrame.Angles(0, 0, math.rad(90))
	plinth.Parent = model

	local body = Instance.new("Part")
	body.Name = "ServerPackBody"
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(8, 15, 28)
	body.Size = Vector3.new(7.4, 10.8, 0.54)
	body.CFrame = rootCFrame
	body.Parent = model

	local topCap = Instance.new("WedgePart")
	topCap.Name = "TopCap"
	topCap.Anchored = true
	topCap.CanCollide = false
	topCap.CanTouch = false
	topCap.CanQuery = false
	topCap.Material = Enum.Material.SmoothPlastic
	topCap.Color = Color3.fromRGB(9, 20, 36)
	topCap.Size = Vector3.new(7.4, 1.8, 0.54)
	topCap.CFrame = body.CFrame * CFrame.new(0, 6.25, 0) * CFrame.Angles(0, 0, math.rad(180))
	topCap.Parent = model

	local bottomCap = Instance.new("WedgePart")
	bottomCap.Name = "BottomCap"
	bottomCap.Anchored = true
	bottomCap.CanCollide = false
	bottomCap.CanTouch = false
	bottomCap.CanQuery = false
	bottomCap.Material = Enum.Material.SmoothPlastic
	bottomCap.Color = Color3.fromRGB(4, 9, 18)
	bottomCap.Size = Vector3.new(7.4, 1.9, 0.54)
	bottomCap.CFrame = body.CFrame * CFrame.new(0, -6.35, 0)
	bottomCap.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 30
	glow.Brightness = 2.2
	glow.Parent = body

	local attachment = Instance.new("Attachment")
	attachment.Name = "ServerPackHitAttachment"
	attachment.Parent = body

	local hitEmitter = Instance.new("ParticleEmitter")
	hitEmitter.Name = "ServerPackHitBurst"
	hitEmitter.Enabled = false
	hitEmitter.Rate = 0
	hitEmitter.Lifetime = NumberRange.new(0.22, 0.42)
	hitEmitter.Speed = NumberRange.new(4, 9)
	hitEmitter.SpreadAngle = Vector2.new(70, 70)
	hitEmitter.Drag = 3
	hitEmitter.LightEmission = 1
	hitEmitter.LightInfluence = 0
	hitEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.45, color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 94)),
	})
	hitEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.34),
		NumberSequenceKeypoint.new(0.4, 0.64),
		NumberSequenceKeypoint.new(1, 0.04),
	})
	hitEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.7, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	hitEmitter.Parent = attachment

	local leakEmitter = Instance.new("ParticleEmitter")
	leakEmitter.Name = "ServerPackCrackLeak"
	leakEmitter.Enabled = false
	leakEmitter.Rate = 18
	leakEmitter.Lifetime = NumberRange.new(0.35, 0.68)
	leakEmitter.Speed = NumberRange.new(1.0, 2.8)
	leakEmitter.SpreadAngle = Vector2.new(90, 90)
	leakEmitter.Drag = 2
	leakEmitter.LightEmission = 1
	leakEmitter.LightInfluence = 0
	leakEmitter.Color = ColorSequence.new(color)
	leakEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(0.42, 0.52),
		NumberSequenceKeypoint.new(1, 0.03),
	})
	leakEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.7, 0.28),
		NumberSequenceKeypoint.new(1, 1),
	})
	leakEmitter.Parent = attachment

	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = color
	highlight.FillTransparency = 0.9
	highlight.OutlineColor = Color3.fromRGB(255, 247, 186)
	highlight.OutlineTransparency = 0.25
	highlight.Parent = model

	createSurfaceLabel(Enum.NormalId.Front, "SERVER PACK", "BOOSTED LUCK", color, body)
	createSurfaceLabel(Enum.NormalId.Back, "SERVER PACK", "BOOSTED LUCK", color, body)
	local crackLines = createPackCrackOverlay(body, color)

	state.model = model
	state.activePackBody = body
	state.activePackLight = glow
	state.activePackBaseBrightness = glow.Brightness
	state.activePackMaxHits = state.maxHealth
	state.activePackHitsRemaining = state.health
	state.activePackHitEmitter = hitEmitter
	state.activePackLeakEmitter = leakEmitter
	state.activePackHighlight = highlight
	state.activePackImpactParts = { body, topCap, bottomCap }
	state.activePackCracks = crackLines
	state.activePackIntegrity = 1
	state.activePackShakeUntil = 0

	createServerPackBillboard(state, body, packDef, color)

	local spinAngle = 0
	task.spawn(function()
		while state.active and model.Parent do
			local now = os.clock()
			local integrity = state.activePackIntegrity or 1
			local stress = 1 - integrity
			spinAngle += math.rad(18 + (stress * 58)) / 30
			local floatY = centerPosition.Y + math.sin(now * (0.92 + stress * 1.4)) * (0.28 + stress * 0.18)
			local hitShake = now < (state.activePackShakeUntil or 0) and (0.16 + stress * 0.34) or 0
			local shakeX = math.sin(now * 44) * hitShake
			local shakeZ = math.cos(now * 39) * hitShake
			local baseCF = CFrame.new(centerPosition.X + shakeX, floatY, centerPosition.Z + shakeZ)
				* CFrame.Angles(math.rad(math.sin(now * 1.2) * 2), spinAngle, math.rad(math.cos(now * 1.1) * 2))
			body.CFrame = baseCF
			topCap.CFrame = baseCF * CFrame.new(0, 6.25, 0) * CFrame.Angles(0, 0, math.rad(180))
			bottomCap.CFrame = baseCF * CFrame.new(0, -6.35, 0)
			task.wait(1 / 30)
		end
	end)

	return model
end

local function awardServerPackPlayer(player, packWorldPosition)
	if not player or not player.Parent then
		return
	end

	local ok, result = PackService.OpenPack(player, "ServerPack", {
		ignoreCost = true,
		source = "serverPack",
		cardPullLuckBonus = Constants.ServerPack.CardPullLuckBonus,
	})

	if not ok then
		PackOpenFailedEvent:FireClient(player, {
			error = result and result.error or "Server Pack reward failed.",
		})
		return
	end

	addQuestProgress(player, "openPack", 1)
	local pulledCard = result.card or (result.cards and result.cards[1])
	if not pulledCard then
		PackOpenFailedEvent:FireClient(player, { error = "Server Pack reward failed." })
		return
	end

	local plot = BaseService.GetPlot(player)
	local storageResult
	if plot and plot.ownerPlayer == player then
		local storageOk, stored = pcall(autoStorePulledCard, player, plot, pulledCard)
		if storageOk then
			storageResult = stored
		else
			warn("[UnboxAFootballer] Server Pack auto-store failed:", stored)
			DataService.AddCard(player, pulledCard.id)
			refreshPlotDisplayState(player, plot)
			storageResult = { storedInInventory = true, slotIndex = nil, slotWorldPosition = nil }
		end
	else
		DataService.AddCard(player, pulledCard.id)
		storageResult = { storedInInventory = true, slotIndex = nil, slotWorldPosition = nil }
	end

	addQuestProgress(player, "collectCard", 1)
	local passiveIncome = getCardIncome(player, pulledCard)
	PackOpenedEvent:FireClient(player, {
		success = true,
		packId = result.packId,
		packName = result.packName,
		newCoins = result.newCoins,
		card = pulledCard,
		storedInInventory = storageResult.storedInInventory,
		slotIndex = storageResult.slotIndex,
		slotWorldPosition = storageResult.slotWorldPosition,
		packWorldPosition = packWorldPosition,
		coinsPerSecond = passiveIncome,
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	})

	local totalPacks = DataService.GetTotalPacksOpened(player)
	local triggeredMilestones = checkAndGrantMilestones(player, totalPacks)
	if plot then
		local milestoneData = DataService.GetData(player)
		BaseService.UpdatePackMilestone(plot, totalPacks, milestoneData and milestoneData.claimedMilestones or {}, getQueuedMilestoneCount(player))
	end
	fireMilestoneRewards(player, triggeredMilestones)

	if storageResult.storedInInventory then
		sendHint(player, pulledCard.name .. " went to inventory from the Server Pack.")
	else
		sendHint(player, pulledCard.name .. " is now earning +" .. tostring(passiveIncome) .. "/s from the Server Pack.")
	end
end

local function resolveServerPack()
	local state = serverPackState
	if not state or state.breaking ~= true then
		return
	end

	local packWorldPosition = state.activePackBody and (state.activePackBody.Position + Vector3.new(0, 3.2, 0)) or nil
	if state.activePackHitEmitter then
		state.activePackHitEmitter:Emit(80)
	end
	if state.activePackLeakEmitter then
		state.activePackLeakEmitter.Enabled = false
		state.activePackLeakEmitter:Emit(60)
	end
	if state.activePackLight then
		state.activePackLight.Brightness = 7
		state.activePackLight.Range = 42
	end
	if state.activePackHighlight then
		state.activePackHighlight.FillTransparency = 0
		state.activePackHighlight.FillColor = Color3.fromRGB(255, 255, 255)
	end
	for _, part in ipairs(state.activePackImpactParts or {}) do
		if part and part.Parent then
			TweenService:Create(part, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = part.Size * 1.85,
				Transparency = 1,
			}):Play()
		end
	end

	local minHits = math.max(1, math.floor(tonumber(Constants.ServerPack.MinimumHitsForReward) or 3))
	local eligible = {}
	local underQualified = {}
	for _, entry in pairs(state.participants or {}) do
		if entry.player and entry.player.Parent then
			if (entry.hits or 0) >= minHits then
				table.insert(eligible, entry.player)
			else
				table.insert(underQualified, entry.player)
			end
		end
	end

	broadcastServerPackMessage("Server Pack cracked! " .. tostring(#eligible) .. " helper" .. (#eligible == 1 and "" or "s") .. " earned a boosted card.", Constants.ServerPack.Color)
	task.wait(0.45)
	for _, player in ipairs(eligible) do
		awardServerPackPlayer(player, packWorldPosition)
	end
	for _, player in ipairs(underQualified) do
		sendHint(player, "Server Pack needs " .. tostring(minHits) .. " hits to claim next time.")
	end

	task.wait(0.35)
	if state.model and state.model.Parent then
		state.model:Destroy()
	end
	state.active = false
	serverPackState = nil
end

local function spawnServerPack()
	local config = Constants.ServerPack or {}
	if config.Enabled == false or serverPackState then
		return false
	end

	local packDef = PackConfig.ById.ServerPack
	if not packDef then
		warn("[UnboxAFootballer] ServerPack pack config missing.")
		return false
	end

	local health = math.max(1, math.floor(tonumber(config.Health) or tonumber(packDef.hitsRequired) or 600))
	local state = {
		active = true,
		breaking = false,
		health = health,
		maxHealth = health,
		participants = {},
		spawnedAt = os.time(),
	}
	serverPackState = state
	createServerPackModel(state)
	updateServerPackBillboard(state)
	broadcastServerPackMessage("Server Pack spawned in the fan zone. Land 3 hits to claim a boosted card.", config.Color)
	return true
end

local function isFacingPosition(rootPart, targetPosition, minDot)
	local delta = targetPosition - rootPart.Position
	local flatDelta = Vector3.new(delta.X, 0, delta.Z)
	local flatLookVector = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
	if flatDelta.Magnitude <= 0.1 or flatLookVector.Magnitude <= 0.1 then
		return true
	end
	return flatLookVector.Unit:Dot(flatDelta.Unit) >= (minDot or Constants.Pitchfork.HitFacingDot or 0.5)
end

local function tryHitServerPack(player, rootPart)
	local state = serverPackState
	if not state or not state.active or state.breaking or not state.activePackBody then
		return false
	end

	local packDelta = state.activePackBody.Position - rootPart.Position
	local hitRange = tonumber(Constants.ServerPack.HitRange) or (Constants.Pitchfork.HitRange + 4)
	if packDelta.Magnitude > hitRange then
		return false
	end

	if not isFacingPosition(rootPart, state.activePackBody.Position, Constants.Pitchfork.HitFacingDot or 0.35) then
		PackOpenFailedEvent:FireClient(player, {
			error = "Face the Server Pack before swinging.",
		})
		return true
	end

	local damage = getPitchforkDamage(player)
	state.health = math.max(0, (state.health or state.maxHealth or 1) - damage)
	state.activePackHitsRemaining = state.health
	local integrityRatio = (state.maxHealth or 1) > 0 and math.clamp(state.health / state.maxHealth, 0, 1) or 0
	local newBrightness = nil
	if state.activePackLight then
		newBrightness = 2.2 + ((1 - integrityRatio) * 4)
		state.activePackLight.Brightness = newBrightness
	end

	local userId = player.UserId
	local entry = state.participants[userId]
	if not entry then
		entry = {
			player = player,
			hits = 0,
			damage = 0,
		}
		state.participants[userId] = entry
	end
	entry.hits += 1
	entry.damage += damage

	updatePackDamageVisuals(state, integrityRatio)
	playPackHitEffect(state, newBrightness)
	updateServerPackBillboard(state)

	PackHitFeedbackEvent:FireClient(player, {
		packId = "ServerPack",
		packName = "Server Pack",
		color = Constants.ServerPack.Color,
		remaining = state.health,
		maxHits = state.maxHealth,
		damage = damage,
		integrity = integrityRatio,
		isFinal = state.health <= 0,
		packWorldPosition = state.activePackBody.Position + Vector3.new(0, 3.2, 0),
	})

	local minHits = math.max(1, math.floor(tonumber(Constants.ServerPack.MinimumHitsForReward) or 3))
	if entry.hits == minHits then
		sendHint(player, "You qualified for the Server Pack reward.")
	end

	if state.health <= 0 then
		state.breaking = true
		task.spawn(resolveServerPack)
	end

	return true
end

for _, plot in ipairs(BaseService.GetPlots()) do
	BaseService.SetPlotPadStatus(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		connectSlotPrompt(plot, slot)
	end
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

	if tryHitServerPack(player, rootPart) then
		return
	end

	local plot = BaseService.GetPlot(player)
	if plot and plot.isOpeningPack then
		return
	end

	if not plot or not plot.activePackDef or not plot.activePackBody then
		PackOpenFailedEvent:FireClient(player, {
			error = "Your next pack is still spawning.",
		})
		return
	end

	local packDelta = plot.activePackBody.Position - rootPart.Position
	if packDelta.Magnitude > Constants.Pitchfork.HitRange then
		PackOpenFailedEvent:FireClient(player, {
			error = "Move closer to the pack on your red pad.",
		})
		return
	end

	local flatPackDelta = Vector3.new(packDelta.X, 0, packDelta.Z)
	local flatLookVector = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
	if flatPackDelta.Magnitude > 0.1 and flatLookVector.Magnitude > 0.1 then
		local facingDot = flatLookVector.Unit:Dot(flatPackDelta.Unit)
		if facingDot < (Constants.Pitchfork.HitFacingDot or 0.5) then
			PackOpenFailedEvent:FireClient(player, {
				error = "Face the pack directly before swinging.",
			})
			return
		end
	end

	local damage = getPitchforkDamage(player)
	plot.activePackHitsRemaining = math.max(0, (plot.activePackHitsRemaining or plot.activePackMaxHits or 1) - damage)
	local integrityRatio = (plot.activePackMaxHits or 1) > 0
		and math.clamp(plot.activePackHitsRemaining / plot.activePackMaxHits, 0, 1)
		or 0
	local newBrightness = nil

	if plot.activePackLight then
		newBrightness = 1.15 + ((1 - integrityRatio) * 2.8)
		plot.activePackLight.Brightness = newBrightness
	end

	updatePackDamageVisuals(plot, integrityRatio)
	playPackHitEffect(plot, newBrightness)

	PackHitFeedbackEvent:FireClient(player, {
		packId = plot.activePackDef.id,
		packName = plot.activePackDef.displayName,
		color = plot.activePackDef.color,
		remaining = plot.activePackHitsRemaining,
		maxHits = plot.activePackMaxHits,
		damage = damage,
		integrity = integrityRatio,
		isFinal = plot.activePackHitsRemaining <= 0,
		packWorldPosition = plot.activePackBody.Position + Vector3.new(0, 2.2, 0),
	})

	if plot.activePackHitsRemaining > 0 then
		BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
		return
	end

	plot.isOpeningPack = true
	BaseService.SetPlotPadStatus(plot, "Pack Cracked", "Breaking open...", plot.activePackDef.color)
	task.wait(0.34)

	-- ── Pack crack burst animation ────────────────────────────────────
	-- Fire before the card pull so players see the pack explode open.
	if plot.activePackHitEmitter then
		plot.activePackHitEmitter:Emit(44)
	end
	if plot.activePackLeakEmitter then
		plot.activePackLeakEmitter.Enabled = false
		plot.activePackLeakEmitter:Emit(34)
	end
	if plot.activePackLight then
		plot.activePackLight.Brightness = 4.8
		plot.activePackLight.Range = 24
	end
	if plot.activePackHighlight then
		plot.activePackHighlight.FillTransparency = 0
		plot.activePackHighlight.FillColor = Color3.fromRGB(255, 255, 255)
	end
	-- Expand + fade all three pack parts simultaneously
	for _, part in ipairs(plot.activePackImpactParts or {}) do
		if part and part.Parent then
			TweenService:Create(
				part,
				TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = part.Size * 1.65, Transparency = 1 }
			):Play()
		end
	end
	task.wait(0.38) -- hold the drama before the card appears

	local openedPackId = plot.activePackDef.id
	local openedPackColor = plot.activePackDef.color
	local openedPackWorldPosition = plot.activePackBody.Position + Vector3.new(0, 2.5, 0)

	local openCallOk, ok, result = pcall(PackService.OpenPack, player, openedPackId, {
		ignoreCost = true,
		source = "pitchfork",
		milestoneGuarantee = plot.activePackMilestoneGuarantee,
	})

	if not openCallOk then
		warn("[UnboxAFootballer] PackService.OpenPack crashed:", ok)
		ok = false
		result = { error = "Pack opening failed. Please try again." }
	end

	if ok then
		addQuestProgress(player, "openPack", 1)
		if result.playerPick == true then
			local pickOptions = result.pickOptions
			if type(pickOptions) ~= "table" or #pickOptions == 0 then
				plot.isOpeningPack = nil
				plot.activePackHitsRemaining = math.max(1, plot.activePackHitsRemaining or 1)
				BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
				PackOpenFailedEvent:FireClient(player, { error = "Player pick failed. Please try again." })
				return
			end

			local totalPacks = DataService.GetTotalPacksOpened(player)
			local triggeredMilestones = checkAndGrantMilestones(player, totalPacks)
			local milestoneData = DataService.GetData(player)
			local claimed = milestoneData and milestoneData.claimedMilestones or {}
			local milestoneOk, milestoneErr = pcall(BaseService.UpdatePackMilestone, plot, totalPacks, claimed, getQueuedMilestoneCount(player))
			if not milestoneOk then
				warn("[UnboxAFootballer] Pack milestone update failed:", milestoneErr)
			end
			fireMilestoneRewards(player, triggeredMilestones)

			pendingPlayerPicks[player] = {
				packId = result.packId,
				packName = result.packName,
				packColor = openedPackColor,
				packWorldPosition = openedPackWorldPosition,
				pickOptions = pickOptions,
				createdAt = os.time(),
			}

			PackOpenedEvent:FireClient(player, {
				success = true,
				playerPick = true,
				packId = result.packId,
				packName = result.packName,
				newCoins = result.newCoins,
				pickOptions = pickOptions,
				packWorldPosition = openedPackWorldPosition,
			})

			if #triggeredMilestones > 0 then
				local rewardInfo = serializeMilestoneReward(triggeredMilestones[1])
				sendHint(player, "Milestone reached: " .. (rewardInfo and rewardInfo.reward or "reward queued") .. ".")
			else
				sendHint(player, "Choose one player from your " .. tostring(result.packName or "Player Pick") .. ".")
			end

			clearPlotPack(plot)
			BaseService.SetPlotPadStatus(plot, "Player Pick", "Choose one reward player", openedPackColor)
			return
		end

		local pulledCard = result.card or (result.cards and result.cards[1]) or nil
		if not pulledCard then
			plot.isOpeningPack = nil
			plot.activePackHitsRemaining = math.max(1, plot.activePackHitsRemaining or 1)
			BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
			PackOpenFailedEvent:FireClient(player, { error = "Pack roll failed. Please try again." })
			return
		end

		local storageOk, storageResult = pcall(autoStorePulledCard, player, plot, pulledCard)
		if not storageOk then
			warn("[UnboxAFootballer] Auto-store failed; falling back to inventory:", storageResult)
			DataService.AddCard(player, pulledCard.id)
			refreshPlotDisplayState(player, plot)
			storageResult = {
				storedInInventory = true,
				slotIndex = nil,
				slotWorldPosition = nil,
			}
			end

			local passiveIncome = getCardIncome(player, pulledCard)
			addQuestProgress(player, "collectCard", 1)

			PackOpenedEvent:FireClient(player, {
			success = true,
			packId = result.packId,
			packName = result.packName,
			newCoins = result.newCoins,
			card = pulledCard,
			storedInInventory = storageResult.storedInInventory,
			slotIndex = storageResult.slotIndex,
			slotWorldPosition = storageResult.slotWorldPosition,
			packWorldPosition = openedPackWorldPosition,
			coinsPerSecond = passiveIncome,
			passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
		})

		local totalPacks = DataService.GetTotalPacksOpened(player)
		local triggeredMilestones = checkAndGrantMilestones(player, totalPacks)
		local milestoneData = DataService.GetData(player)
		local claimed = milestoneData and milestoneData.claimedMilestones or {}
		local milestoneOk, milestoneErr = pcall(BaseService.UpdatePackMilestone, plot, totalPacks, claimed, getQueuedMilestoneCount(player))
		if not milestoneOk then
			warn("[UnboxAFootballer] Pack milestone update failed:", milestoneErr)
		end
		fireMilestoneRewards(player, triggeredMilestones)

		if pulledCard then
			if result.pityInfo then
				sendHint(player, "Milestone guarantee used: " .. (result.pityInfo.reward or "guarantee") .. ".")
			end
			if #triggeredMilestones > 0 then
				local rewardInfo = serializeMilestoneReward(triggeredMilestones[1])
				sendHint(player, "Milestone reached: " .. (rewardInfo and rewardInfo.reward or "reward queued") .. ".")
			end
			if storageResult.storedInInventory then
				sendHint(player, pulledCard.name .. " went to inventory because your display slots are full.")
			else
				sendHint(player, pulledCard.name .. " is now earning +" .. tostring(passiveIncome) .. "/s on display slot " .. tostring(storageResult.slotIndex) .. ".")
			end
		end

		clearPlotPack(plot)
		BaseService.SetPlotPadStatus(plot, "Rolling Next Pack", "Another free pack is spawning", openedPackColor)
		local respawnDelay = computeSpawnDelay(getUpgradeLevel(player, "PackSpawnRate"))
		task.delay(respawnDelay, function()
			if plot.ownerPlayer == player then
				spawnPackForPlot(plot)
			end
		end)
	else
		plot.isOpeningPack = nil
		plot.activePackHitsRemaining = math.max(1, plot.activePackHitsRemaining or 1)
		BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
		PackOpenFailedEvent:FireClient(player, result)
	end
end)

local function handlePlayerAdded(player)
	if initializedPlayers[player] then
		ensurePitchfork(player)
		if player.Character then
			placeCharacterAtOwnedPlot(player, player.Character)
		end
		return
	end
	initializedPlayers[player] = true

	local data = DataService.LoadPlayer(player)
	local plot = BaseService.AssignPlot(player, data.rebirthTier or 0, getEffectiveDisplaySlotCount(player))
	-- Wire up prompt handlers for any extra slots loaded from saved data (slots > base 6)
	if plot then
		syncRebirthMultiplierBadge(player, plot)
		for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
			if slot.slotIndex > 6 then
				connectSlotPrompt(plot, slot)
			end
		end
	end
	EconomyService.EnsureStarterCoins(player)
	ensurePitchfork(player)

	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if player.Parent and character.Parent then
				placeCharacterAtOwnedPlot(player, character)
				applyMovementUpgrade(player, character)
			end
		end)

		task.defer(function()
			local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
			if humanoid then
				humanoid.Died:Once(function()
					task.delay(3, function()
						if player.Parent then
							player:LoadCharacter()
						end
					end)
				end)
			end
		end)
	end)

	if player.Character then
		task.defer(function()
			if player.Parent and player.Character then
				placeCharacterAtOwnedPlot(player, player.Character)
				applyMovementUpgrade(player, player.Character)
			end
		end)
	else
		task.defer(function()
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end

	if plot then
		refreshPlotDisplayState(player, plot)
		do local _tp = DataService.GetTotalPacksOpened(player); local _d = DataService.GetData(player); BaseService.UpdatePackMilestone(plot, _tp, _d and _d.claimedMilestones or {}, getQueuedMilestoneCount(player)) end
		spawnPackForPlot(plot)
	end

	task.defer(function()
		if player.Parent then
			UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player), DataService.GetGems(player))
			pushQuestPayload(player)
			sendHint(player, plot and "Equip your pitchfork and crack the pack on your red pad. Hold E on green slots to move players in or out." or "This server's bases are full right now.")
		end
	end)

	return data
end

Players.PlayerAdded:Connect(handlePlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(handlePlayerAdded, player)
end

task.spawn(function()
	local config = Constants.ServerPack or {}
	if config.Enabled == false then
		return
	end

	task.wait(math.max(5, math.floor(tonumber(config.FirstSpawnDelaySeconds) or 90)))
	while true do
		while #Players:GetPlayers() == 0 do
			task.wait(5)
		end

		if not serverPackState then
			spawnServerPack()
		end

		while serverPackState do
			task.wait(2)
		end

		task.wait(math.max(60, math.floor(tonumber(config.SpawnIntervalSeconds) or (75 * 60))))
	end
end)

-- ── Dev reset command ("/resetdata" in chat) ─────────────────
-- Wipes ALL progress and kicks the player so they rejoin fresh.
-- Remove this block before going to production.
local function wireDevReset(player)
	player.Chatted:Connect(function(msg)
		if msg:lower() == "/resetdata" then
			DataService.DevReset(player)
			player:Kick("✅ Data wiped! Rejoin to start fresh.")
		end
	end)
end
Players.PlayerAdded:Connect(wireDevReset)
for _, player in ipairs(Players:GetPlayers()) do
	wireDevReset(player)
end

Players.PlayerRemoving:Connect(function(player)
	claimPendingPlayerPickToInventory(player)
	initializedPlayers[player] = nil
	swingCooldowns[player] = nil
	packPurchaseLocks[player] = nil
	playerPickLocks[player] = nil
	questClaimLocks[player] = nil
	if serverPackState and serverPackState.participants then
		serverPackState.participants[player.UserId] = nil
		updateServerPackBillboard(serverPackState)
	end
	DataService.SavePlayer(player)
	DataService.UnloadPlayer(player)
	BaseService.ReleasePlot(player)
end)

-- BindToClose fires BEFORE PlayerRemoving when the server shuts down,
-- so cache is still populated here. Save all players in parallel so
-- we don't run out of time waiting for sequential DataStore calls.
game:BindToClose(function()
	local threads = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local t = task.spawn(function()
			claimPendingPlayerPickToInventory(player)
			DataService.SavePlayer(player)
		end)
		table.insert(threads, t)
	end

	-- Wait up to 10 s for all parallel saves to complete.
	-- DataStore SetAsync typically takes <2 s; 10 s covers 1 full retry cycle.
	local deadline = tick() + 10
	local function anyAlive()
		for _, t in ipairs(threads) do
			if coroutine.status(t) ~= "dead" then
				return true
			end
		end
		return false
	end
	while anyAlive() and tick() < deadline do
		task.wait(0.1)
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local passiveIncome = getDisplayedIncomePerSecond(player)
			if passiveIncome > 0 then
				EconomyService.AddCoins(player, passiveIncome)
				UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			end
		end
	end
end)

GetQuestsFn.OnServerInvoke = function(player)
	return buildQuestPayload(player)
end

ClaimQuestFn.OnServerInvoke = function(player, questId)
	if questClaimLocks[player] then
		return { success = false, error = "Quest reward already processing.", quests = buildQuestPayload(player) }
	end

	if type(questId) ~= "string" then
		return { success = false, error = "Choose a quest first.", quests = buildQuestPayload(player) }
	end

	questClaimLocks[player] = true
	local ok, result = pcall(claimQuestReward, player, questId)
	questClaimLocks[player] = nil
	if not ok then
		warn("[UnboxAFootballer] Quest claim failed:", result)
		return { success = false, error = "Quest claim failed.", quests = buildQuestPayload(player) }
	end
	return result
end

GetPlayerDataFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return nil
	end

	return {
		coins = data.coins,
		gems = data.gems or 0,
		rebirthTier = data.rebirthTier or 0,
		rebirthTokens = data.rebirthTokens or 0,
		fanMultiplier = type(RebirthService.GetFanMultiplier) == "function"
			and RebirthService.GetFanMultiplier(data.rebirthTier or 0)
			or 1,
		totalCardsOpened = data.totalCardsOpened or 0,
		totalPacksOpened = DataService.GetTotalPacksOpened(player),
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
		canClaimFreePack = EconomyService.CanClaimFreePack(player),
		freePackRemaining = EconomyService.GetFreePackRemaining(player),
		canClaimDailyReward = EconomyService.CanClaimDailyReward(player),
		dailyRewardRemaining = EconomyService.GetDailyRewardRemaining(player),
		dailyRewardStreak = data.dailyRewardStreak or 0,
		queuedRewardCount = getQueuedMilestoneCount(player),
		limitedPackCooldowns = buildPackPurchaseCooldownPayload(player),
		inventoryCounts = data.inventory,
	}
end

local function buildInventoryPayload(player)
	local data = DataService.GetData(player)
	if not data then
		return {}
	end

	local inventoryById = {}
	for key, amount in pairs(DataService.GetInventory(player)) do
		local cardId = tonumber(key)
		local card = cardId and CardData.ById[cardId]
		if card and amount > 0 then
			local existing = inventoryById[card.id]
			local fansPerSecond = Utils.CalculateFansPerSecond(card)
			if existing then
				existing.quantity += amount
			else
				inventoryById[card.id] = {
					id = card.id,
					name = card.name,
					nation = card.nation,
					position = card.position,
					rarity = card.rarity,
					quantity = amount,
					fansPerSecond = fansPerSecond,
					sellValue = Utils.GetSellValue(card),
				}
			end
		end
	end

	local inventory = {}
	for _, cardEntry in pairs(inventoryById) do
		table.insert(inventory, cardEntry)
	end

	table.sort(inventory, function(a, b)
		if a.fansPerSecond == b.fansPerSecond then
			return a.name < b.name
		end
		return a.fansPerSecond > b.fansPerSecond
	end)

	return inventory
end

GetInventoryFn.OnServerInvoke = function(player)
	return buildInventoryPayload(player)
end

local function getDisplayedCardIdSet(player)
	local displayedSet = {}
	for _, cardId in pairs(DataService.GetDisplayedCards(player) or {}) do
		local numericId = tonumber(cardId)
		if numericId then
			displayedSet[math.floor(numericId)] = true
		end
	end
	return displayedSet
end

local function buildDisplayedCardPayload(player)
	local displayed = {}
	for slotIndex, cardId in pairs(DataService.GetDisplayedCards(player) or {}) do
		local card = getCardById(cardId)
		if card then
			local entry = serializeCardForClient(card)
			entry.slotIndex = tonumber(slotIndex)
			table.insert(displayed, entry)
		end
	end
	table.sort(displayed, function(a, b)
		return (a.slotIndex or 0) < (b.slotIndex or 0)
	end)
	return displayed
end

buildRebirthVaultPayload = function(player)
	local data = DataService.GetData(player)
	if not data then
		return {
			success = false,
			error = "Your data is still loading.",
		}
	end

	local tier = data.rebirthTier or 0
	local maxSlots = RebirthService.GetVaultSlots(tier)
	local nextSlots = RebirthService.GetVaultSlots(tier + 1)
	local displayedSet = getDisplayedCardIdSet(player)
	local inventoryCounts = DataService.GetInventory(player)
	local validVaultIds = {}
	local vault = {}

	for _, cardId in ipairs(DataService.GetRebirthVault(player)) do
		local numericId = tonumber(cardId)
		local card = numericId and getCardById(numericId)
		if card and maxSlots > 0 and #validVaultIds < maxSlots and not displayedSet[card.id] and (inventoryCounts[tostring(card.id)] or 0) > 0 then
			table.insert(validVaultIds, card.id)
			local entry = serializeCardForClient(card)
			entry.quantity = inventoryCounts[tostring(card.id)] or 0
			table.insert(vault, entry)
		end
	end

	if #validVaultIds ~= #(data.rebirthVault or {}) then
		DataService.SetRebirthVault(player, validVaultIds)
	end

	local inventory = buildInventoryPayload(player)
	local vaultSet = {}
	for _, cardId in ipairs(validVaultIds) do
		vaultSet[cardId] = true
	end
	for _, entry in ipairs(inventory) do
		entry.inVault = vaultSet[entry.id] == true
		entry.onDisplay = displayedSet[entry.id] == true
	end

	return {
		success = true,
		rebirthTier = tier,
		maxSlots = maxSlots,
		nextSlots = nextSlots,
		unlocked = maxSlots > 0,
		unlockTier = 3,
		note = "Only stored inventory players can enter the vault. Remove a player from a green display slot first.",
		vault = vault,
		inventory = inventory,
		displayed = buildDisplayedCardPayload(player),
	}
end

GetRebirthVaultFn.OnServerInvoke = function(player)
	return buildRebirthVaultPayload(player)
end

SetRebirthVaultFn.OnServerInvoke = function(player, requestedCardIds)
	local data = DataService.GetData(player)
	if not data then
		return { success = false, error = "Your data is still loading." }
	end

	if type(requestedCardIds) ~= "table" then
		return { success = false, error = "Choose players for the vault.", vault = buildRebirthVaultPayload(player) }
	end

	local maxSlots = RebirthService.GetVaultSlots(data.rebirthTier or 0)
	if maxSlots <= 0 then
		return { success = false, error = "Vault unlocks at Rebirth 3.", vault = buildRebirthVaultPayload(player) }
	end

	local displayedSet = getDisplayedCardIdSet(player)
	local inventoryCounts = DataService.GetInventory(player)
	local accepted = {}
	local seen = {}

	for _, value in ipairs(requestedCardIds) do
		if #accepted >= maxSlots then
			break
		end
		local cardId = tonumber(value)
		if cardId then
			cardId = math.floor(cardId)
			local card = getCardById(cardId)
			if card and not seen[cardId] then
				if displayedSet[cardId] then
					return {
						success = false,
						error = card.name .. " is on a green display slot. Remove them first.",
						vault = buildRebirthVaultPayload(player),
					}
				end
				if (inventoryCounts[tostring(cardId)] or 0) <= 0 then
					return {
						success = false,
						error = card.name .. " is not in your stored inventory.",
						vault = buildRebirthVaultPayload(player),
					}
				end

				table.insert(accepted, cardId)
				seen[cardId] = true
			end
		end
	end

	DataService.SetRebirthVault(player, accepted)
	sendHint(player, #accepted > 0 and ("Vault saved: " .. tostring(#accepted) .. "/" .. tostring(maxSlots) .. " player(s).") or "Vault cleared.")
	return {
		success = true,
		vault = buildRebirthVaultPayload(player),
	}
end

local function getCollectionUnlockedCount(collection)
	local count = 0
	for key, amount in pairs(collection or {}) do
		if CardData.ById[tonumber(key)] and (tonumber(amount) or 0) > 0 then
			count += 1
		end
	end
	return count
end

local function buildCollectionPayload(player)
	local data = DataService.GetData(player)
	if not data then
		return nil
	end

	local collection = DataService.GetCollection(player)
	local unlockedCount = getCollectionUnlockedCount(collection)
	local claimedRewards = data.collectionRewards or {}
	local rewards = {}
	local claimedCount = 0

	for _, reward in ipairs(Constants.CollectionRewards or {}) do
		local id = tostring(reward.id)
		local claimed = claimedRewards[id] == true
		local requiredCards = reward.requiredCards or math.huge
		if claimed then
			claimedCount += 1
		end
		table.insert(rewards, {
			id = id,
			label = reward.label,
			requiredCards = requiredCards,
			progress = math.min(unlockedCount, requiredCards),
			reward = reward.reward,
			claimed = claimed,
			canClaim = (not claimed) and unlockedCount >= requiredCards,
		})
	end

	return {
		counts = collection,
		viewed = DataService.GetCollectionViewed(player),
		unlockedCount = unlockedCount,
		totalCards = #CardData.Pool,
		claimedRewards = claimedRewards,
		rewards = rewards,
		claimedRewardCount = claimedCount,
		totalRewardCount = #rewards,
		coins = DataService.GetCoins(player),
	}
end

GetCollectionFn.OnServerInvoke = function(player)
	return buildCollectionPayload(player)
end

ClaimCollectionRewardFn.OnServerInvoke = function(player, rewardId)
	local data = DataService.GetData(player)
	if not data then
		return { success = false, error = "Your data is still loading." }
	end

	rewardId = tostring(rewardId or "")
	local rewardSpec
	for _, reward in ipairs(Constants.CollectionRewards or {}) do
		if tostring(reward.id) == rewardId then
			rewardSpec = reward
			break
		end
	end

	if not rewardSpec then
		return { success = false, error = "Unknown collection reward." }
	end

	data.collectionRewards = data.collectionRewards or {}
	if data.collectionRewards[rewardId] == true then
		return { success = false, error = "Reward already claimed.", collection = buildCollectionPayload(player) }
	end

	local unlockedCount = getCollectionUnlockedCount(DataService.GetCollection(player))
	if unlockedCount < (rewardSpec.requiredCards or math.huge) then
		return { success = false, error = "Unlock more cards first.", collection = buildCollectionPayload(player) }
	end

	data.collectionRewards[rewardId] = true
	DataService.MarkDirty(player)
	if rewardSpec.fans and rewardSpec.fans > 0 then
		EconomyService.AddCoins(player, rewardSpec.fans)
		UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
	end

	return {
		success = true,
		reward = rewardSpec.reward,
		coins = DataService.GetCoins(player),
		collection = buildCollectionPayload(player),
	}
end

MarkCollectionCardViewedFn.OnServerInvoke = function(player, cardId)
	if type(cardId) ~= "number" then
		return { success = false, error = "Invalid card." }
	end

	local ok = DataService.MarkCollectionCardViewed(player, cardId)
	if not ok then
		return { success = false, error = "Card is not collected.", collection = buildCollectionPayload(player) }
	end

	return {
		success = true,
		collection = buildCollectionPayload(player),
	}
end

PlaceInventoryCardInSlotFn.OnServerInvoke = function(player, slotIndex, cardId)
	if type(slotIndex) ~= "number" or type(cardId) ~= "number" then
		return { success = false, error = "Choose a valid player and display slot." }
	end

	local plot = BaseService.GetPlot(player)
	if not plot or plot.ownerPlayer ~= player then
		return { success = false, error = "You do not have an active stadium yet." }
	end

	local slot = getDisplaySlotByIndex(plot, slotIndex)
	if not slot then
		return { success = false, error = "That display slot does not exist." }
	end

	if not isPlayerOnDisplaySlotFloor(player, slot) then
		return { success = false, error = "Go to that floor to use this display slot." }
	end

	local ok, cardOrError = addInventoryCardToDisplay(player, plot, slot, cardId)
	if not ok then
		return { success = false, error = cardOrError }
	end

	sendHint(player, cardOrError.name .. " added to display slot " .. tostring(slotIndex) .. " for +" .. tostring(getCardIncome(player, cardOrError)) .. "/s.")

	return {
		success = true,
		card = serializeCardForClient(cardOrError),
		slotIndex = slotIndex,
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	}
end

OpenPackFn.OnServerInvoke = function(player, packId)
	return {
		success = false,
		error = "Use your pitchfork on the pack at your red pad.",
	}
end

ChoosePlayerPickFn.OnServerInvoke = function(player, optionIndex)
	if playerPickLocks[player] then
		return { success = false, error = "Player pick already processing." }
	end

	playerPickLocks[player] = true
	local callOk, ok, payload = pcall(awardPendingPlayerPick, player, optionIndex)
	playerPickLocks[player] = nil
	if not callOk then
		warn("[UnboxAFootballer] Player pick award failed:", ok)
		return { success = false, error = "Player pick failed. Try again." }
	end
	if not ok then
		return payload or { success = false, error = "Player pick failed." }
	end
	return payload
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

	local earned = Utils.GetSellValue(card)
	EconomyService.AddCoins(player, earned)
	addQuestProgress(player, "sellCard", 1)
	refreshPlotDisplayState(player, BaseService.GetPlot(player))
	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))

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
	local soldCount = 0
	for _, cardId in ipairs(cardIds) do
		if type(cardId) == "number" then
			local card = CardData.ById[cardId]
			if card and DataService.RemoveCard(player, cardId) then
				total += Utils.GetSellValue(card)
				soldCount += 1
			end
		end
	end

	if total > 0 then
		EconomyService.AddCoins(player, total)
		addQuestProgress(player, "sellCard", soldCount)
		UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
	end
	refreshPlotDisplayState(player, BaseService.GetPlot(player))

	return {
		success = true,
		coinsEarned = total,
		newCoins = DataService.GetCoins(player),
	}
end

local function buildUpgradePayload(player)
	local payload = {
		coins = DataService.GetCoins(player),
		upgrades = {},
	}

	for _, key in ipairs(Constants.UpgradeKeys) do
		local spec = Constants.Upgrades[key]
		local level = getUpgradeLevel(player, key)
		local nextCost = getUpgradeCost(key, level)
		local entry = {
			key = key,
			displayName = spec.displayName,
			description = spec.description,
			level = level,
			maxLevel = spec.maxLevel,
			nextCost = nextCost,
			maxed = level >= spec.maxLevel,
		}

		if key == "PitchforkDamage" then
			entry.currentValue = computePitchforkDamage(level)
			entry.nextValue = computePitchforkDamage(level + 1)
			entry.valueSuffix = "× per swing"
		elseif key == "PackSpawnLuck" then
			entry.currentValue = computePackSpawnLuckValue(level)
			entry.nextValue = computePackSpawnLuckValue(level + 1)
			entry.valueSuffix = "% better packs"
		elseif key == "CardPullLuck" then
			entry.currentValue = computeCardPullLuckValue(level)
			entry.nextValue = computeCardPullLuckValue(level + 1)
			entry.valueSuffix = "% pull luck"
		elseif key == "MoveSpeed" then
			entry.currentValue = computeWalkSpeed(level)
			entry.nextValue = computeWalkSpeed(level + 1)
			entry.valueSuffix = " studs/s"
		end

		table.insert(payload.upgrades, entry)
	end

	return payload
end

GetUpgradesFn.OnServerInvoke = function(player)
	return buildUpgradePayload(player)
end

PurchaseUpgradeFn.OnServerInvoke = function(player, upgradeKey)
	if type(upgradeKey) ~= "string" or not Constants.Upgrades[upgradeKey] then
		return { success = false, error = "Unknown upgrade." }
	end

	local level = getUpgradeLevel(player, upgradeKey)
	local spec = Constants.Upgrades[upgradeKey]
	if level >= spec.maxLevel then
		return { success = false, error = "Upgrade already maxed." }
	end

	local cost = getUpgradeCost(upgradeKey, level)
	if not cost then
		return { success = false, error = "Upgrade already maxed." }
	end

	local ok, err = DataService.SpendCoins(player, cost)
	if not ok then
		return { success = false, error = err or "Not enough Fans." }
	end

	local data = DataService.GetData(player)
	data.upgrades = data.upgrades or {}
	data.upgrades[upgradeKey] = level + 1
	DataService.MarkDirty(player)

	if upgradeKey == "MoveSpeed" then
		applyMovementUpgrade(player)
	end

	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))

	local payload = buildUpgradePayload(player)
	payload.success = true
	payload.purchasedKey = upgradeKey
	payload.coinsSpent = cost
	return payload
end

PurchasePackFn.OnServerInvoke = function(player, packId)
	if packPurchaseLocks[player] then
		return {
			success = false,
			error = "Purchase already processing.",
			newCoins = DataService.GetCoins(player),
			newGems = DataService.GetGems(player),
			queuedRewardCount = getQueuedMilestoneCount(player),
			limitedPackCooldowns = buildPackPurchaseCooldownPayload(player),
		}
	end

	packPurchaseLocks[player] = true
	local function finish(payload)
		packPurchaseLocks[player] = nil
		return payload
	end

	if type(packId) ~= "string" then
		return finish({ success = false, error = "Choose a pack first." })
	end

	local data = DataService.GetData(player)
	if not data then
		return finish({ success = false, error = "Your data is still loading." })
	end

	local packDef = PackConfig.ById[packId]
	if not packDef or not PackConfig.IsShopBuyable(packId) then
		return finish({ success = false, error = "That pack is not for sale." })
	end

	local cost = PackConfig.GetShopCost(packDef)
	if cost <= 0 then
		return finish({ success = false, error = "That pack is not for sale." })
	end
	local currency = type(PackConfig.GetShopCurrency) == "function" and PackConfig.GetShopCurrency(packDef) or "Fans"

	local cooldownRemaining, purchaseCooldown = getPackPurchaseCooldownRemaining(data, packDef)
	if purchaseCooldown > 0 then
		if type(data.limitedPackPurchases) ~= "table" then
			data.limitedPackPurchases = {}
		end
		if cooldownRemaining > 0 then
			return finish({
				success = false,
				error = packDef.displayName .. " ready in " .. Utils.FormatCountdown(cooldownRemaining) .. ".",
				newCoins = DataService.GetCoins(player),
				newGems = DataService.GetGems(player),
				queuedRewardCount = getQueuedMilestoneCount(player),
				limitedPackCooldowns = buildPackPurchaseCooldownPayload(player),
			})
		end
	end

	local ok, err
	if currency == "Gems" then
		ok, err = DataService.SpendGems(player, cost)
	else
		ok, err = DataService.SpendCoins(player, cost)
	end
	if not ok then
		return finish({
			success = false,
			error = err or ("Not enough " .. currency .. "."),
			newCoins = DataService.GetCoins(player),
			newGems = DataService.GetGems(player),
			queuedRewardCount = getQueuedMilestoneCount(player),
			limitedPackCooldowns = buildPackPurchaseCooldownPayload(player),
		})
	end

	local queuedReward = queuePackRewardForPad(player, packId, "SHOP", packDef.displayName .. " Queued")
	if not queuedReward then
		if currency == "Gems" then
			DataService.AddGems(player, cost)
		else
			EconomyService.AddCoins(player, cost)
		end
		UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player), DataService.GetGems(player))
		return finish({
			success = false,
			error = "Pack could not be queued. Try again.",
			newCoins = DataService.GetCoins(player),
			newGems = DataService.GetGems(player),
			queuedRewardCount = getQueuedMilestoneCount(player),
			limitedPackCooldowns = buildPackPurchaseCooldownPayload(player),
		})
	end

	if purchaseCooldown > 0 then
		data.limitedPackPurchases[packId] = os.time()
		DataService.MarkDirty(player)
	end

	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player), DataService.GetGems(player))
	addQuestProgress(player, "buyPack", 1)
	sendHint(player, packDef.displayName .. " bought and queued for your red pad.")

	return finish({
		success = true,
		packId = packId,
		packName = packDef.displayName,
		currency = currency,
		coinsSpent = currency == "Fans" and cost or 0,
		gemsSpent = currency == "Gems" and cost or 0,
		newCoins = DataService.GetCoins(player),
		newGems = DataService.GetGems(player),
		queuedRewardCount = getQueuedMilestoneCount(player),
		rewardQueued = true,
		limitedPackCooldowns = buildPackPurchaseCooldownPayload(player),
	})
end

-- ── Free Pack claim ───────────────────────────────────────────────────────────
-- Player taps "CLAIM FREE PACK" in the Shop panel.  We stamp the cooldown here
-- (EconomyService.ClaimFreePack), open a Gold Pack with ignoreCost so no Fans
-- are charged, auto-store the card, then fire PackOpenedEvent so the card reveal
-- screen appears exactly like a pitchfork crack.
ClaimFreePackFn.OnServerInvoke = function(player)
	local ok, err = EconomyService.ClaimFreePack(player)
	if not ok then
		return { success = false, error = err or "Free pack not ready." }
	end

	local packOk, result = PackService.OpenPack(player, "GoldPack", { ignoreCost = true })
	if not packOk then
		-- Rare: pack logic failed after cooldown was already stamped.  Let it
		-- ride — player can retry on next cooldown.
		return { success = false, error = result and result.error or "Pack failed. Try again." }
	end
	addQuestProgress(player, "openPack", 1)
	addQuestProgress(player, "claimFreePack", 1)

	local pulledCard = result.card or (result.cards and result.cards[1]) or nil
	local plot = BaseService.GetPlot(player)
	local storageResult

	if plot then
		storageResult = autoStorePulledCard(player, plot, pulledCard)
	else
		if pulledCard then
			DataService.AddCard(player, pulledCard.id)
		end
		storageResult = { storedInInventory = true, slotIndex = nil }
	end

	local passiveIncome = getCardIncome(player, pulledCard)
	if pulledCard then
		addQuestProgress(player, "collectCard", 1)
	end
	local totalPacks = DataService.GetTotalPacksOpened(player)
	local triggeredMilestones = checkAndGrantMilestones(player, totalPacks)
	if plot then
		do
			local _d = DataService.GetData(player)
			BaseService.UpdatePackMilestone(plot, totalPacks, _d and _d.claimedMilestones or {}, getQueuedMilestoneCount(player))
		end
	end
	fireMilestoneRewards(player, triggeredMilestones)
	if result.pityInfo then
		sendHint(player, "Milestone guarantee used: " .. (result.pityInfo.reward or "guarantee") .. ".")
	end
	if #triggeredMilestones > 0 then
		local rewardInfo = serializeMilestoneReward(triggeredMilestones[1])
		sendHint(player, "Milestone reached: " .. (rewardInfo and rewardInfo.reward or "reward queued") .. ".")
	end

	PackOpenedEvent:FireClient(player, {
		success = true,
		packId = result.packId,
		packName = result.packName,
		newCoins = result.newCoins,
		card = pulledCard,
		storedInInventory = storageResult.storedInInventory,
		slotIndex = storageResult.slotIndex,
		slotWorldPosition = storageResult.slotWorldPosition,
		packWorldPosition = plot and (plot.packPad.Position + Vector3.new(0, 6, 0)) or nil,
		coinsPerSecond = passiveIncome,
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	})

	return {
		success = true,
		freePackRemaining = Constants.FreePackCooldown,
	}
end

-- ── Daily Reward claim ────────────────────────────────────────────────────────
-- Daily streak rewards are queued packs. They spawn before the next natural pad
-- pack, using the same queue system as pack milestones.
ClaimDailyRewardFn.OnServerInvoke = function(player)
	local granted, rewardOrErr, streak = EconomyService.TryGrantDailyReward(player)
	if not granted then
		return {
			success = false,
			error = rewardOrErr or "Daily reward not ready yet.",
			dailyRewardRemaining = EconomyService.GetDailyRewardRemaining(player),
		}
	end
	addQuestProgress(player, "claimDailyReward", 1)

	local queuedReward
	local reward = type(rewardOrErr) == "table" and rewardOrErr or nil
	if reward and reward.packId then
		local packDef = PackConfig.ById[reward.packId]
		queuedReward = {
			milestoneId = "daily_streak_" .. tostring(streak or 1),
			kind = "pack",
			packId = reward.packId,
			reward = ((packDef and packDef.displayName) or reward.label or "Daily Pack") .. " Queued",
			label = "DAILY",
			threshold = reward.day or 0,
			repeatCount = streak or 1,
			earnedAt = DataService.GetTotalPacksOpened(player),
		}

		if DataService.EnqueueMilestoneReward(player, queuedReward) then
			fireMilestoneRewards(player, { queuedReward })
			sendHint(player, ((packDef and packDef.displayName) or reward.label or "Daily pack") .. " queued for your next spawn.")
		else
			queuedReward = nil
		end
	end

	local plot = BaseService.GetPlot(player)
	if plot then
		local totalPacks = DataService.GetTotalPacksOpened(player)
		local data = DataService.GetData(player)
		BaseService.UpdatePackMilestone(plot, totalPacks, data and data.claimedMilestones or {}, getQueuedMilestoneCount(player))
	end

	return {
		success = true,
		rewardQueued = queuedReward ~= nil,
		dailyRewardStreak = streak or 0,
		dailyRewardPackId = reward and reward.packId or nil,
		dailyRewardPackName = reward and (PackConfig.ById[reward.packId] and PackConfig.ById[reward.packId].displayName or reward.label) or nil,
		newCoins = DataService.GetCoins(player),
		dailyRewardRemaining = Constants.DailyRewardCooldown,
		queuedRewardCount = getQueuedMilestoneCount(player),
	}
end

GetRebirthStatusFn.OnServerInvoke = function(player)
	return RebirthService.GetStatus(player)
end

RequestRebirthFn.OnServerInvoke = function(player)
	local ok, result = RebirthService.PerformRebirth(player)
	if not ok then
		return {
			success = false,
			status = result,
			error = result and result.reason or "You cannot rebirth yet.",
		}
	end

	local plot = BaseService.GetPlot(player)
	if plot then
		BaseService.ClearPlotDisplays(plot)
		do local _tp = DataService.GetTotalPacksOpened(player); local _d = DataService.GetData(player); BaseService.UpdatePackMilestone(plot, _tp, _d and _d.claimedMilestones or {}, getQueuedMilestoneCount(player)) end
		refreshPlotDisplayState(player, plot)
		local newData = DataService.GetData(player)
		if newData then
			syncDisplaySlotsForPlayer(player, plot)
		end
	end

	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
	sendHint(player, "Rebirth complete! Your stadium reset, but your permanent fan multiplier increased.")

	return {
		success = true,
		status = result,
		coins = DataService.GetCoins(player),
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
	}
end

print("[UnboxAFootballer] Pack systems ready")
