local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

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
local OpenSlotPickerEvent = makeEvent("OpenSlotPicker")

local GetPlayerDataFn = makeFunction("GetPlayerData")
local OpenPackFn = makeFunction("OpenPack")
local SellCardFn = makeFunction("SellCard")
local SellAllCardsFn = makeFunction("SellAllCards")
local GetInventoryFn = makeFunction("GetInventory")
local GetUpgradesFn = makeFunction("GetUpgrades")
local PurchaseUpgradeFn = makeFunction("PurchaseUpgrade")
local PlaceInventoryCardInSlotFn = makeFunction("PlaceInventoryCardInSlot")
local ClaimFreePackFn = makeFunction("ClaimFreePack")
local ClaimDailyRewardFn = makeFunction("ClaimDailyReward")
local GetRebirthStatusFn = makeFunction("GetRebirthStatus")
local RequestRebirthFn = makeFunction("RequestRebirth")
local OpenRebirthUIEvent = makeEvent("OpenRebirthUI")

PackService.Init(DataService, EconomyService, {
	UpdateCoins = UpdateCoinsEvent,
	PackOpened = PackOpenedEvent,
	PackOpenFailed = PackOpenFailedEvent,
})
EconomyService.Init(DataService)
RebirthService.Init(DataService)

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
end

local swingCooldowns = {}
local initializedPlayers = {}

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
	frame.BackgroundColor3 = Color3.fromRGB(22, 18, 8)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 247, 191)),
		ColorSequenceKeypoint.new(0.35, color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(96, 66, 10)),
	})
	gradient.Rotation = 25
	gradient.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(31, 24, 10)
	stroke.Thickness = 3
	stroke.Parent = frame

	local top = Instance.new("TextLabel")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(0.42, 0, 0.28, 0)
	top.Position = UDim2.new(0.06, 0, 0.06, 0)
	top.Text = title
	top.TextColor3 = Color3.fromRGB(20, 15, 8)
	top.TextScaled = true
	top.Font = Enum.Font.GothamBlack
	top.TextXAlignment = Enum.TextXAlignment.Left
	top.Parent = frame

	local middle = Instance.new("TextLabel")
	middle.BackgroundTransparency = 1
	middle.Size = UDim2.new(0.84, 0, 0.22, 0)
	middle.Position = UDim2.new(0.08, 0, 0.61, 0)
	middle.Text = subtitle
	middle.TextColor3 = Color3.fromRGB(48, 38, 14)
	middle.TextScaled = true
	middle.Font = Enum.Font.GothamBold
	middle.Parent = frame

	local stripes = Instance.new("Frame")
	stripes.BackgroundTransparency = 0.8
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

	if plot.activePackHitEmitter then
		plot.activePackHitEmitter:Emit(14)
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

-- ── Milestone pity tracking ───────────────────────────────────────────────────
local function checkAndGrantMilestones(player, totalPacks)
	local data = DataService.GetData(player)
	if not data then return end
	if type(data.claimedMilestones) ~= "table" then
		data.claimedMilestones = {}
	end

	for _, milestone in ipairs(Constants.PackMilestones) do
		local threshold = tonumber(milestone.threshold)
		if not threshold or threshold <= 0 then
			continue
		end

		local key = tostring(threshold)
		local timesEarned = math.floor((totalPacks or 0) / threshold)
		local timesClaimed = data.claimedMilestones[key]
		if timesClaimed == true then timesClaimed = 1 end
		timesClaimed = tonumber(timesClaimed) or 0

		while timesClaimed < timesEarned do
			timesClaimed += 1
			data.claimedMilestones[key] = timesClaimed
			DataService.MarkDirty(player)
		end

		data.claimedMilestones[key] = timesClaimed
	end
end

local function getBestInventoryCard(player)
	local inventory = DataService.GetInventory(player)
	local bestCard

	for key, amount in pairs(inventory) do
		if amount > 0 then
			local card = getCardById(key)
			if card then
				local powerScore = Utils.GetPowerScore(card)
				local bestPowerScore = bestCard and Utils.GetPowerScore(bestCard) or -math.huge
				if not bestCard or powerScore > bestPowerScore or (powerScore == bestPowerScore and card.name < bestCard.name) then
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

local function placeCardOnDisplay(player, plot, slot, cardId)
	local card = getCardById(cardId)
	if not card or not slot then
		return false
	end

	DataService.SetDisplayedCard(player, slot.slotIndex, card.id)
	BaseService.UpdateDisplaySlot(slot, card, getCardIncome(player, card))
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
	plot.activePackHighlight = nil
	plot.activePackImpactParts = nil
	plot.isOpeningPack = nil
end

local function spawnPackForPlot(plot)
	if not plot or not plot.ownerPlayer then
		return
	end

	clearPlotPack(plot)

	local packDef = rollPadPackForPlayer(plot.ownerPlayer)
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
	cardBody.Color = Color3.fromRGB(28, 22, 8)
	cardBody.Size = Vector3.new(5.4, 8, 0.3)
	cardBody.CFrame = rootCFrame
	cardBody.Parent = model

	local topCap = Instance.new("WedgePart")
	topCap.Name = "TopCap"
	topCap.Anchored = true
	topCap.Material = Enum.Material.SmoothPlastic
	topCap.Color = Color3.fromRGB(28, 22, 8)
	topCap.Size = Vector3.new(5.4, 1.4, 0.3)
	topCap.CFrame = cardBody.CFrame * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
	topCap.Parent = model

	local bottomCap = Instance.new("WedgePart")
	bottomCap.Name = "BottomCap"
	bottomCap.Anchored = true
	bottomCap.Material = Enum.Material.SmoothPlastic
	bottomCap.Color = Color3.fromRGB(20, 16, 6)
	bottomCap.Size = Vector3.new(5.4, 1.6, 0.3)
	bottomCap.CFrame = cardBody.CFrame * CFrame.new(0, -4.8, 0)
	bottomCap.Parent = model

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

	local hitHighlight = Instance.new("Highlight")
	hitHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	hitHighlight.FillColor = packDef.color
	hitHighlight.FillTransparency = 1
	hitHighlight.OutlineColor = Color3.fromRGB(255, 245, 190)
	hitHighlight.OutlineTransparency = 0.82
	hitHighlight.Parent = model

	createSurfaceLabel(Enum.NormalId.Front, "1 CARD", packDef.displayName, packDef.color, cardBody)
	createSurfaceLabel(Enum.NormalId.Back, "1 CARD", packDef.displayName, packDef.color, cardBody)

	-- (pack health is shown in the padGui billboard — no floating bar needed)

	-- Continuous idle: slow spin + gentle float.  All three parts updated together so
	-- they never drift apart (the old tween only moved cardBody, leaving caps behind).
	local packOriginX = basePosition.X
	local packOriginY = basePosition.Y + 5.4
	local packOriginZ = basePosition.Z
	local packSpinAngle = 0
	task.spawn(function()
		while model.Parent do
			packSpinAngle = packSpinAngle + math.rad(34) / 30 -- ≈ 34°/s slow spin
			local floatY = packOriginY + math.sin(os.clock() * 1.3) * 0.30
			local baseCF = CFrame.new(packOriginX, floatY, packOriginZ)
				* CFrame.Angles(0, packSpinAngle, 0)
			if model.Parent then
				cardBody.CFrame = baseCF
				topCap.CFrame = baseCF * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
				bottomCap.CFrame = baseCF * CFrame.new(0, -4.8, 0)
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
	plot.activePackHighlight = hitHighlight
	plot.activePackImpactParts = { cardBody, topCap, bottomCap }

	BaseService.SetPlotPadHealth(plot, packDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, packDef.color)
	sendHint(plot.ownerPlayer, packDef.displayName .. " spawned on your red pad. Crack it with your pitchfork and use Hold E on green slots to swap players.")
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
	local newBrightness = nil

	if plot.activePackLight then
		newBrightness = 1.15 + ((plot.activePackMaxHits - plot.activePackHitsRemaining) * 0.28)
		plot.activePackLight.Brightness = newBrightness
	end

	playPackHitEffect(plot, newBrightness)

	if plot.activePackHitsRemaining > 0 then
		BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
		return
	end

	plot.isOpeningPack = true
	BaseService.SetPlotPadStatus(plot, "Pack Cracked", "Claiming your player", plot.activePackDef.color)

	-- ── Pack crack burst animation ────────────────────────────────────
	-- Fire before the card pull so players see the pack explode open.
	if plot.activePackHitEmitter then
		plot.activePackHitEmitter:Emit(44)
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
	})

	if not openCallOk then
		warn("[UnboxAFootballer] PackService.OpenPack crashed:", ok)
		ok = false
		result = { error = "Pack opening failed. Please try again." }
	end

	if ok then
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
		checkAndGrantMilestones(player, totalPacks)
		local milestoneData = DataService.GetData(player)
		local claimed = milestoneData and milestoneData.claimedMilestones or {}
		local milestoneOk, milestoneErr = pcall(BaseService.UpdatePackMilestone, plot, totalPacks, claimed)
		if not milestoneOk then
			warn("[UnboxAFootballer] Pack milestone update failed:", milestoneErr)
		end

		if pulledCard then
			if result.pityInfo then
				sendHint(player, "Pack milestone hit: " .. (result.pityInfo.reward or "guarantee") .. " upgraded this pull.")
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
	EconomyService.TryGrantDailyReward(player)
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
		do local _tp = DataService.GetTotalPacksOpened(player); local _d = DataService.GetData(player); BaseService.UpdatePackMilestone(plot, _tp, _d and _d.claimedMilestones or {}) end
		spawnPackForPlot(plot)
	end

	task.defer(function()
		if player.Parent then
			UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			sendHint(player, plot and "Equip your pitchfork and crack the pack on your red pad. Hold E on green slots to move players in or out." or "This server's bases are full right now.")
		end
	end)

	return data
end

Players.PlayerAdded:Connect(handlePlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(handlePlayerAdded, player)
end

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
	initializedPlayers[player] = nil
	swingCooldowns[player] = nil
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
		dailyRewardRemaining = math.max(
			0,
			Constants.DailyRewardCooldown - (os.time() - (data.lastDailyReward or 0))
		),
		inventoryCounts = data.inventory,
	}
end

GetInventoryFn.OnServerInvoke = function(player)
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
	for _, cardId in ipairs(cardIds) do
		if type(cardId) == "number" then
			local card = CardData.ById[cardId]
			if card and DataService.RemoveCard(player, cardId) then
				total += Utils.GetSellValue(card)
			end
		end
	end

	if total > 0 then
		EconomyService.AddCoins(player, total)
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
	local totalPacks = DataService.GetTotalPacksOpened(player)
	checkAndGrantMilestones(player, totalPacks)
	if plot then
		do
			local _d = DataService.GetData(player)
			BaseService.UpdatePackMilestone(plot, totalPacks, _d and _d.claimedMilestones or {})
		end
	end
	if result.pityInfo then
		sendHint(player, "Pack milestone hit: " .. (result.pityInfo.reward or "guarantee") .. " upgraded this pull.")
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
-- Normally granted automatically on login, but players can also claim through
-- the Shop if 24 h have elapsed while they're still in the session.
ClaimDailyRewardFn.OnServerInvoke = function(player)
	local granted = EconomyService.TryGrantDailyReward(player)
	if not granted then
		local data = DataService.GetData(player)
		local remaining = data
				and math.max(0, Constants.DailyRewardCooldown - (os.time() - (data.lastDailyReward or 0)))
			or Constants.DailyRewardCooldown
		return {
			success = false,
			error = "Daily reward not ready yet.",
			dailyRewardRemaining = remaining,
		}
	end

	UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))

	return {
		success = true,
		coinsAwarded = Constants.DailyRewardCoins,
		newCoins = DataService.GetCoins(player),
		dailyRewardRemaining = Constants.DailyRewardCooldown,
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
		do local _tp = DataService.GetTotalPacksOpened(player); local _d = DataService.GetData(player); BaseService.UpdatePackMilestone(plot, _tp, _d and _d.claimedMilestones or {}) end
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
