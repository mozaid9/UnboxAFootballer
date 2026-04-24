local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

if ServerScriptService:GetAttribute("UnboxMainBooted") then
	warn("[UnboxAFootballer] Duplicate Main detected, skipping older copy")
	return
end
ServerScriptService:SetAttribute("UnboxMainBooted", true)

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

PackService.Init(DataService, EconomyService, {
	UpdateCoins = UpdateCoinsEvent,
	PackOpened = PackOpenedEvent,
	PackOpenFailed = PackOpenFailedEvent,
})
EconomyService.Init(DataService)
RebirthService.Init(DataService)

BaseService.BuildBaseMap()

local swingCooldowns = {}

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
	local character = player.Character

	local hasEquipped = character and character:FindFirstChild("Pitchfork")
	if backpack and not hasEquipped and not backpack:FindFirstChild("Pitchfork") then
		createPitchforkTool().Parent = backpack
	end
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
	return math.floor(spec.baseCost * (spec.costMultiplier ^ level))
end

local function computePitchforkDamage(level)
	local spec = Constants.Upgrades.PitchforkDamage
	return spec.baseDamage + level * spec.damagePerLevel
end

local function computeSpawnDelay(level)
	local spec = Constants.Upgrades.PackSpawnRate
	return math.max(spec.minDelay, spec.baseDelay - level * spec.delayReductionPerLevel)
end

local function computeLuckShift(level)
	local spec = Constants.Upgrades.PadLuck
	return math.min(level * spec.shiftPerLevel, spec.maxShift)
end

local function computeWalkSpeed(level)
	local spec = Constants.Upgrades.MoveSpeed
	return math.min(spec.baseWalkSpeed + level * spec.speedPerLevel, spec.maxWalkSpeed)
end

local function getPitchforkDamage(player)
	return computePitchforkDamage(getUpgradeLevel(player, "PitchforkDamage"))
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

	local baseBrightness = settleBrightness or plot.activePackBaseBrightness or 2.8
	pulseLight(plot.activePackLight, baseBrightness, baseBrightness + 3.4, 0.1)

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
	local weights = {}
	for _, packDef in ipairs(PackConfig.PadSpawnOrder) do
		table.insert(weights, packDef.padWeight or 1)
	end

	if player and #weights >= 3 then
		local shift = computeLuckShift(getUpgradeLevel(player, "PadLuck"))
		local takeable = math.max(0, weights[1] - 5)
		local taken = math.min(shift, takeable)
		weights[1] = weights[1] - taken
		local toRare = math.floor(taken * 0.6)
		local toPremium = taken - toRare
		weights[2] = weights[2] + toRare
		weights[3] = weights[3] + toPremium
	end

	local chosenIndex = Utils.WeightedRandom(weights)
	return PackConfig.PadSpawnOrder[chosenIndex]
end

local function getCardById(cardId)
	return cardId and CardData.ById[tonumber(cardId)] or nil
end

local function getBestInventoryCard(player)
	local inventory = DataService.GetInventory(player)
	local bestCard

	for key, amount in pairs(inventory) do
		if amount > 0 then
			local card = getCardById(key)
			if card then
				if not bestCard or card.rating > bestCard.rating or (card.rating == bestCard.rating and card.name < bestCard.name) then
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

	for _, cardId in pairs(displayedCards) do
		local card = getCardById(cardId)
		if card then
			total += Utils.GetPassiveIncome(card.rating)
		end
	end

	return total
end

local function refreshPlotDisplayState(player, plot)
	if not player or not plot then
		return
	end

	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
		local displayedCardId = DataService.GetDisplayedCard(player, slot.slotIndex)
		local displayedCard = getCardById(displayedCardId)
		if displayedCard then
			BaseService.UpdateDisplaySlot(slot, displayedCard, Utils.GetPassiveIncome(displayedCard.rating))
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
	BaseService.UpdateDisplaySlot(slot, card, Utils.GetPassiveIncome(card.rating))
	return true
end

local function autoStorePulledCard(player, plot, card)
	if not player or not plot or not card then
		return {
			storedInInventory = true,
			slotIndex = nil,
		}
	end

	local emptySlot = getFirstEmptyDisplaySlot(player, plot)
	if emptySlot then
		placeCardOnDisplay(player, plot, emptySlot, card.id)
		refreshPlotDisplayState(player, plot)
		return {
			storedInInventory = false,
			slotIndex = emptySlot.slotIndex,
		}
	end

	DataService.AddCard(player, card.id)
	refreshPlotDisplayState(player, plot)
	return {
		storedInInventory = true,
		slotIndex = nil,
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
	glow.Range = 18
	glow.Brightness = 2.8
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

	createSurfaceLabel(Enum.NormalId.Front, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)
	createSurfaceLabel(Enum.NormalId.Back, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)

	local floatTween = TweenService:Create(cardBody, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		CFrame = cardBody.CFrame * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, math.rad(4), 0),
	})
	floatTween:Play()

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

for _, plot in ipairs(BaseService.GetPlots()) do
	BaseService.SetPlotPadStatus(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	for _, slot in ipairs(BaseService.GetDisplaySlots(plot)) do
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
	if not plot or not plot.activePackDef or not plot.activePackBody or plot.isOpeningPack then
		PackOpenFailedEvent:FireClient(player, {
			error = "Your next pack is still spawning.",
		})
		return
	end

	if (rootPart.Position - plot.activePackBody.Position).Magnitude > Constants.Pitchfork.HitRange then
		PackOpenFailedEvent:FireClient(player, {
			error = "Move closer to the pack on your red pad.",
		})
		return
	end

	local damage = getPitchforkDamage(player)
	plot.activePackHitsRemaining = math.max(0, (plot.activePackHitsRemaining or plot.activePackMaxHits or 1) - damage)
	local newBrightness = nil

	if plot.activePackLight then
		newBrightness = 2.4 + ((plot.activePackMaxHits - plot.activePackHitsRemaining) * 0.65)
		plot.activePackLight.Brightness = newBrightness
	end

	playPackHitEffect(plot, newBrightness)

	if plot.activePackHitsRemaining > 0 then
		BaseService.SetPlotPadHealth(plot, plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackMaxHits, plot.activePackDef.color)
		return
	end

	plot.isOpeningPack = true
	BaseService.SetPlotPadStatus(plot, "Pack Cracked", "Claiming your player", plot.activePackDef.color)

	local openedPackId = plot.activePackDef.id
	local openedPackColor = plot.activePackDef.color

	local ok, result = PackService.OpenPack(player, openedPackId, {
		ignoreCost = true,
		source = "pitchfork",
	})

	if ok then
		local pulledCard = result.card or (result.cards and result.cards[1]) or nil
		local storageResult = autoStorePulledCard(player, plot, pulledCard)
		local passiveIncome = pulledCard and Utils.GetPassiveIncome(pulledCard.rating) or 0

		PackOpenedEvent:FireClient(player, {
			success = true,
			packId = result.packId,
			packName = result.packName,
			newCoins = result.newCoins,
			card = pulledCard,
			storedInInventory = storageResult.storedInInventory,
			slotIndex = storageResult.slotIndex,
			coinsPerSecond = passiveIncome,
			passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
		})

		if pulledCard then
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

Players.PlayerAdded:Connect(function(player)
	local data = DataService.LoadPlayer(player)
	local plot = BaseService.AssignPlot(player)
	EconomyService.EnsureStarterCoins(player)
	EconomyService.TryGrantDailyReward(player)
	ensurePitchfork(player)

	if player.Character then
		task.defer(function()
			if player.Parent then
				BaseService.PlaceCharacterAtPlot(player, player.Character)
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		task.delay(0.15, function()
			if player.Parent and character.Parent then
				BaseService.PlaceCharacterAtPlot(player, character)
				ensurePitchfork(player)
				applyMovementUpgrade(player, character)
			end
		end)
	end)

	if player.Character then
		task.defer(function()
			if player.Parent and player.Character then
				applyMovementUpgrade(player, player.Character)
			end
		end)
	end

	if plot then
		refreshPlotDisplayState(player, plot)
		spawnPackForPlot(plot)
	end

	task.defer(function()
		if player.Parent then
			UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			sendHint(player, plot and "Equip your pitchfork and crack the pack on your red pad. Hold E on green slots to move players in or out." or "This server's bases are full right now.")
		end
	end)

	return data
end)

Players.PlayerRemoving:Connect(function(player)
	swingCooldowns[player] = nil
	DataService.SavePlayer(player)
	DataService.UnloadPlayer(player)
	BaseService.ReleasePlot(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
	task.wait(2)
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
		totalCardsOpened = data.totalCardsOpened or 0,
		passiveCoinsPerSecond = getDisplayedIncomePerSecond(player),
		canClaimFreePack = EconomyService.CanClaimFreePack(player),
		freePackRemaining = EconomyService.GetFreePackRemaining(player),
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
			if existing then
				existing.quantity += amount
			else
				inventoryById[card.id] = {
					id = card.id,
					name = card.name,
					nation = card.nation,
					position = card.position,
					rating = card.rating,
					rarity = card.rarity,
					quantity = amount,
					sellValue = Utils.GetSellValue(card.rating),
				}
			end
		end
	end

	local inventory = {}
	for _, cardEntry in pairs(inventoryById) do
		table.insert(inventory, cardEntry)
	end

	table.sort(inventory, function(a, b)
		if a.rating == b.rating then
			return a.name < b.name
		end
		return a.rating > b.rating
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

	sendHint(player, cardOrError.name .. " added to display slot " .. tostring(slotIndex) .. " for +" .. tostring(Utils.GetPassiveIncome(cardOrError.rating)) .. "/s.")

	return {
		success = true,
		card = cardOrError,
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

	local earned = Utils.GetSellValue(card.rating)
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
				total += Utils.GetSellValue(card.rating)
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
			entry.valueSuffix = " dmg/swing"
		elseif key == "PackSpawnRate" then
			entry.currentValue = computeSpawnDelay(level)
			entry.nextValue = computeSpawnDelay(level + 1)
			entry.valueSuffix = "s respawn"
		elseif key == "PadLuck" then
			entry.currentValue = computeLuckShift(level)
			entry.nextValue = computeLuckShift(level + 1)
			entry.valueSuffix = " luck shift"
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

print("[UnboxAFootballer] Pack systems ready")
