local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Utils = require(ReplicatedStorage.Shared.Utils)

local BaseService = {}

local layout = Constants.BaseLayout
local basesFolder
local plots = {}
local assignedPlots = {}

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function createSignLabel(text, size, position, color, parent)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Size = size,
		Position = position,
		Text = text,
		TextColor3 = color,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, parent)
end

local function createOwnerSignText(text, size, position, color, style, parent)
	style = style or {}

	local label = make("TextLabel", {
		BackgroundTransparency = 1,
		Size = size,
		Position = position,
		Text = text,
		TextColor3 = color,
		TextStrokeColor3 = style.textStrokeColor or Color3.fromRGB(5, 8, 14),
		TextStrokeTransparency = style.textStrokeTransparency or 0.65,
		TextScaled = style.textScaled == true,
		TextSize = style.textSize or 30,
		Font = style.font or Enum.Font.GothamBold,
		TextWrapped = style.textWrapped == true,
		TextXAlignment = style.textXAlignment or Enum.TextXAlignment.Center,
		TextYAlignment = style.textYAlignment or Enum.TextYAlignment.Center,
	}, parent)

	if style.textScaled then
		make("UITextSizeConstraint", {
			MinTextSize = style.minTextSize or 20,
			MaxTextSize = style.maxTextSize or 150,
		}, label)
	end

	return label
end

local function formatStadiumTitle(ownerName)
	if not ownerName or ownerName == "" then
		return "OPEN"
	end

	return string.upper(ownerName) .. "'S"
end

local function updateOwnerSign(plot, ownerName, subtitle)
	if ownerName and ownerName ~= "" then
		plot.ownerTopLabel.Text = "HOME CLUB"
		plot.ownerNameLabel.Text = formatStadiumTitle(ownerName)
		plot.ownerSubtitleLabel.Text = "STADIUM"
	else
		plot.ownerTopLabel.Text = "AVAILABLE PLOT"
		plot.ownerNameLabel.Text = "OPEN"
		plot.ownerSubtitleLabel.Text = "STADIUM"
	end

	plot.ownerTopLabel.Visible = true
	plot.ownerSubtitleLabel.Visible = true
end

local function updatePadLabel(plot, title, subtitle, color)
	plot.padTitleLabel.Text = title
	plot.padSubtitleLabel.Text = subtitle
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = false
end

local function updatePadHealth(plot, title, currentValue, maxValue, color)
	local ratio = maxValue > 0 and math.clamp(currentValue / maxValue, 0, 1) or 0
	plot.padTitleLabel.Text = title
	plot.padSubtitleLabel.Text = string.format("%d / %d HP", currentValue, maxValue)
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = true
	plot.padBarFill.BackgroundColor3 = color
	plot.padBarFill.Size = UDim2.new(ratio, 0, 1, 0)
end

local function createFence(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(76, 80, 90),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createStadiumTier(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(102, 108, 120),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createStadiumWedge(parent, size, cframe)
	make("WedgePart", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(120, 126, 138),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createDisplayCardFace(face, card, incomePerSecond, parent)
	local rarityColor = Utils.GetRarityColor(card.rarity)
	local isPremium = card.rarity == "Premium Gold"
	local trimColor = isPremium and Color3.fromRGB(252, 240, 200) or Color3.fromRGB(218, 170, 52)

	local gui = make("SurfaceGui", {
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, parent)

	-- Outer card frame
	local frame = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(38, 26, 10),
		BorderSizePixel = 0,
	}, gui)

	-- Vertical rarity gradient — bright at top, deep brown at bottom
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor),
			ColorSequenceKeypoint.new(0.48, rarityColor:Lerp(Color3.fromRGB(86, 60, 18), 0.45)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 22, 8)),
		}),
		Rotation = 90,
	}, frame)

	-- Outer gold trim
	make("UIStroke", {
		Color = trimColor,
		Thickness = 4,
	}, frame)

	-- Inner inset border detail
	local innerBorder = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, -14),
		Position = UDim2.fromOffset(7, 7),
	}, frame)
	make("UIStroke", {
		Color = Color3.fromRGB(24, 16, 4),
		Thickness = 1.5,
		Transparency = 0.35,
	}, innerBorder)

	-- Rating (dominant, top-left)
	local ratingLabel = createSignLabel(tostring(card.rating), UDim2.new(0.34, 0, 0.24, 0), UDim2.new(0.1, 0, 0.06, 0), Color3.fromRGB(22, 12, 2), frame)
	ratingLabel.TextXAlignment = Enum.TextXAlignment.Left
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.6,
		Transparency = 0.15,
	}, ratingLabel)

	-- Position (under rating)
	local positionLabel = createSignLabel(card.position, UDim2.new(0.28, 0, 0.1, 0), UDim2.new(0.11, 0, 0.3, 0), Color3.fromRGB(34, 22, 6), frame)
	positionLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Divider band between top cluster and name
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 14, 4),
		BorderSizePixel = 0,
		Size = UDim2.new(0.74, 0, 0, 2),
		Position = UDim2.new(0.13, 0, 0.44, 0),
	}, frame)

	-- Player name (big, centered)
	local nameLabel = createSignLabel(card.name, UDim2.new(0.84, 0, 0.16, 0), UDim2.new(0.08, 0, 0.48, 0), Color3.fromRGB(22, 12, 4), frame)
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.2,
		Transparency = 0.3,
	}, nameLabel)

	-- Nation (below name)
	createSignLabel(card.nation, UDim2.new(0.78, 0, 0.08, 0), UDim2.new(0.11, 0, 0.67, 0), Color3.fromRGB(46, 32, 10), frame)

	-- Income pill at bottom
	local incomePill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(26, 58, 32),
		Size = UDim2.new(0.72, 0, 0.11, 0),
		Position = UDim2.new(0.14, 0, 0.82, 0),
		BorderSizePixel = 0,
	}, frame)
	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = incomePill
	make("UIStroke", {
		Color = Color3.fromRGB(126, 214, 142),
		Thickness = 1.5,
		Transparency = 0.3,
	}, incomePill)

	createSignLabel("+" .. tostring(incomePerSecond) .. " /s", UDim2.fromScale(0.9, 0.72), UDim2.fromScale(0.05, 0.14), Color3.fromRGB(228, 255, 220), incomePill)
end

local function clearDisplayCard(slot)
	if slot.cardModel and slot.cardModel.Parent then
		slot.cardModel:Destroy()
	end
	slot.cardModel = nil
	slot.model:SetAttribute("Occupied", false)
end

local function setSlotPrompt(slot, actionText, objectText, enabled)
	slot.prompt.ActionText = actionText
	slot.prompt.ObjectText = objectText
	slot.prompt.Enabled = enabled
end

local function createDisplaySlot(parent, index, cframe, lookDirection)
	local model = make("Model", {
		Name = "DisplaySlot" .. index,
	}, parent)

	local base = make("Part", {
		Name = "Base",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(20, 26, 38),
		Size = layout.DisplaySlotSize,
		CFrame = cframe,
	}, model)

	local top = make("Part", {
		Name = "Top",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(46, 205, 113),
		Size = Vector3.new(layout.DisplaySlotSize.X - 1.4, 0.18, layout.DisplaySlotSize.Z - 1.4),
		CFrame = base.CFrame + Vector3.new(0, layout.DisplaySlotSize.Y / 2 + 0.1, 0),
	}, model)

	local prompt = make("ProximityPrompt", {
		Name = "SlotPrompt",
		ActionText = "Add Player",
		ObjectText = "Inventory Empty",
		KeyboardKeyCode = Enum.KeyCode.E,
		HoldDuration = 0.65,
		MaxActivationDistance = 10,
		RequiresLineOfSight = false,
		Enabled = false,
	}, base)

	model:SetAttribute("SlotIndex", index)
	model:SetAttribute("Occupied", false)

	return {
		model = model,
		base = base,
		top = top,
		prompt = prompt,
		slotIndex = index,
		lookDirection = lookDirection,
		cardModel = nil,
	}
end

local function createPlot(plotId, side, laneIndex, position)
	local model = make("Model", {
		Name = "Base" .. plotId,
	}, basesFolder)

	local facingDirection = side == "Left" and 1 or -1
	local baseCFrame = CFrame.new(position)
	local centerDirection = Vector3.new(facingDirection, 0, 0)
	local padOffset = 16
	local wallHeight = layout.FenceHeight or 4.5
	local wallThickness = layout.WallThickness or 1.2
	local entranceWidth = layout.EntranceWidth or 16
	local entrancePillarWidth = layout.EntrancePillarWidth or 2.2
	local padInfoMaxDistance = layout.PadInfoMaxDistance or 38
	local wallY = wallHeight / 2 + layout.PlotSize.Y / 2
	local frontEdgeX = facingDirection * (layout.PlotSize.X / 2)
	local backEdgeX = -frontEdgeX

	local floor = make("Part", {
		Name = "Floor",
		Anchored = true,
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(78, 148, 72),
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	local borderTop = createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY, -layout.PlotSize.Z / 2))
	local borderBottom = createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY, layout.PlotSize.Z / 2))
	local backWall = createFence(model, Vector3.new(wallThickness, wallHeight, layout.PlotSize.Z + wallThickness), baseCFrame * CFrame.new(backEdgeX, wallY, 0))
	local frontWallSegmentLength = math.max(8, (layout.PlotSize.Z - entranceWidth) / 2)
	local frontWallZOffset = (entranceWidth / 2) + (frontWallSegmentLength / 2)
	local frontWallNorth = createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY, -frontWallZOffset))
	local frontWallSouth = createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY, frontWallZOffset))
	local entrancePillarHeight = wallHeight + 5.6
	local entrancePillarX = frontEdgeX + (facingDirection * ((entrancePillarWidth - wallThickness) / 2))
	local entrancePillarNorth = createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2, -(entranceWidth / 2)))
	local entrancePillarSouth = createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2, entranceWidth / 2))
	_ = borderTop
	_ = borderBottom
	_ = backWall
	_ = frontWallNorth
	_ = frontWallSouth
	_ = entrancePillarNorth
	_ = entrancePillarSouth

	local standRise = 0.9
	local standDepth = 4.8
	for step = 1, 3 do
		local levelOffset = (step - 1) * 2.9
		local levelY = layout.PlotSize.Y / 2 + (standRise / 2) + ((step - 1) * standRise)
		local sideZ = (layout.PlotSize.Z / 2) + 2.2 + levelOffset
		createStadiumTier(model, Vector3.new(layout.PlotSize.X - 10, standRise, standDepth), baseCFrame * CFrame.new(0, levelY, sideZ))
		createStadiumTier(model, Vector3.new(layout.PlotSize.X - 10, standRise, standDepth), baseCFrame * CFrame.new(0, levelY, -sideZ))

		local backX = backEdgeX - (facingDirection * (2.6 + levelOffset))
		createStadiumTier(model, Vector3.new(standDepth, standRise, layout.PlotSize.Z + 8), baseCFrame * CFrame.new(backX, levelY, 0))
	end

	createStadiumWedge(
		model,
		Vector3.new(4.6, 3.2, layout.PlotSize.Z + 8),
		baseCFrame * CFrame.new(backEdgeX - (facingDirection * 10.6), 2.1, 0) * CFrame.Angles(0, math.rad(side == "Left" and 180 or 0), math.rad(90))
	)
	createStadiumWedge(
		model,
		Vector3.new(layout.PlotSize.X - 10, 3.2, 4.6),
		baseCFrame * CFrame.new(0, 2.1, (layout.PlotSize.Z / 2) + 10.4) * CFrame.Angles(0, 0, math.rad(180))
	)
	createStadiumWedge(
		model,
		Vector3.new(layout.PlotSize.X - 10, 3.2, 4.6),
		baseCFrame * CFrame.new(0, 2.1, -(layout.PlotSize.Z / 2) - 10.4)
	)

	local centerStrip = make("Part", {
		Name = "CenterStrip",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(242, 241, 235),
		Size = Vector3.new(layout.PlotSize.X - 8, 0.12, 8),
		CFrame = baseCFrame * CFrame.new(0, 0.56, 0),
	}, model)

	local packPad = make("Part", {
		Name = "PackPad",
		Anchored = true,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(221, 49, 49),
		Size = layout.PackPadSize,
		CFrame = baseCFrame * CFrame.new(-facingDirection * padOffset, 0.45, 0),
	}, model)

	local packPadBorder = make("Part", {
		Name = "PackPadBorder",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(86, 16, 16),
		Size = Vector3.new(layout.PackPadSize.X + 2, 0.2, layout.PackPadSize.Z + 2),
		CFrame = packPad.CFrame - Vector3.new(0, 0.22, 0),
	}, model)
	_ = packPadBorder

	local spawnPad = make("Part", {
		Name = "SpawnPad",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(242, 241, 235),
		Size = Vector3.new(10, 0.45, 10),
		CFrame = baseCFrame * CFrame.new(facingDirection * padOffset, 0.45, 0),
	}, model)

	local entranceBeamY = entrancePillarHeight + layout.PlotSize.Y / 2 - 0.6
	local ownerSignPosition = position + (centerDirection * (layout.PlotSize.X / 2 + 2.1)) + Vector3.new(0, entranceBeamY + 3.1, 0)
	local entranceBeam = createFence(
		model,
		Vector3.new(entrancePillarWidth + 1, 1.4, entranceWidth + 1.2),
		baseCFrame * CFrame.new(frontEdgeX + (facingDirection * 0.9), entranceBeamY, 0)
	)
	_ = entranceBeam
	local ownerSign = make("Part", {
		Name = "OwnerSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(16, 4.4, 0.6),
		CFrame = CFrame.lookAt(ownerSignPosition, ownerSignPosition + centerDirection),
	}, model)

	local ownerGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 160,
		LightInfluence = 0,
	}, ownerSign)

	local ownerFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 14, 24),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, ownerGui)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 14, 24)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 20, 34)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 12, 20)),
		}),
		Rotation = 90,
	}, ownerFrame)

	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 3,
	}, ownerFrame)

	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 0),
	}, ownerFrame)

	local ownerTopLabel = createOwnerSignText("AVAILABLE PLOT", UDim2.fromScale(0.7, 0.12), UDim2.fromScale(0.15, 0.08), Color3.fromRGB(255, 223, 120), {
		textScaled = true,
		minTextSize = 24,
		maxTextSize = 58,
		textStrokeTransparency = 0.9,
		font = Enum.Font.GothamBlack,
	}, ownerFrame)

	local ownerNameLabel = createOwnerSignText("OPEN", UDim2.fromScale(0.86, 0.3), UDim2.fromScale(0.07, 0.25), Color3.fromRGB(245, 238, 220), {
		textScaled = true,
		minTextSize = 64,
		maxTextSize = 240,
		textStrokeTransparency = 0.72,
		font = Enum.Font.GothamBlack,
	}, ownerFrame)

	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.58, 0.014),
		Position = UDim2.fromScale(0.21, 0.58),
	}, ownerFrame)

	local ownerSubtitleLabel = createOwnerSignText("STADIUM", UDim2.fromScale(0.76, 0.2), UDim2.fromScale(0.12, 0.64), Color3.fromRGB(214, 206, 184), {
		textScaled = true,
		minTextSize = 44,
		maxTextSize = 160,
		textStrokeTransparency = 0.84,
		font = Enum.Font.GothamBlack,
	}, ownerFrame)

	local padGui = make("BillboardGui", {
		Name = "PadGui",
		Size = UDim2.fromOffset(150, 52),
		StudsOffset = Vector3.new(0, 3.2, 0),
		AlwaysOnTop = false,
		MaxDistance = padInfoMaxDistance,
	}, packPad)

	local padFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 14, 24),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, padGui)

	make("UICorner", {
		CornerRadius = UDim.new(0, 12),
	}, padFrame)

	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 1.5,
		Transparency = 0.22,
	}, padFrame)

	local padAccent = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 85, 85),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 6, 1, -12),
		Position = UDim2.new(0, 8, 0, 6),
	}, padFrame)

	make("UICorner", {
		CornerRadius = UDim.new(0, 6),
	}, padAccent)

	local padTitleLabel = createSignLabel("Pack Pad", UDim2.new(1, -24, 0, 20), UDim2.new(0, 22, 0, 4), Color3.fromRGB(245, 238, 220), padFrame)
	local padSubtitleLabel = createSignLabel("Waiting for owner", UDim2.new(1, -24, 0, 12), UDim2.new(0, 22, 0, 24), Color3.fromRGB(180, 176, 164), padFrame)
	padTitleLabel.TextScaled = false
	padTitleLabel.TextSize = 18
	padTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.TextScaled = false
	padSubtitleLabel.TextSize = 10
	padSubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.Font = Enum.Font.GothamBold

	local padBarBack = make("Frame", {
		Visible = false,
		BackgroundColor3 = Color3.fromRGB(34, 38, 48),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -28, 0, 8),
		Position = UDim2.new(0, 20, 1, -14),
	}, padFrame)

	make("UICorner", {
		CornerRadius = UDim.new(0, 5),
	}, padBarBack)

	local padBarFill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
	}, padBarBack)

	make("UICorner", {
		CornerRadius = UDim.new(0, 5),
	}, padBarFill)

	local displayFolder = make("Folder", {
		Name = "DisplaySlots",
	}, model)

	local slotOffsets = {
		Vector3.new(-12, 1.75, -14),
		Vector3.new(0, 1.75, -14),
		Vector3.new(12, 1.75, -14),
		Vector3.new(-12, 1.75, 14),
		Vector3.new(0, 1.75, 14),
		Vector3.new(12, 1.75, 14),
	}

	local displaySlots = {}
	for slotIndex = 1, layout.DisplaySlotCount do
		local localOffset = slotOffsets[slotIndex]
		local worldOffset = Vector3.new(localOffset.X * facingDirection, localOffset.Y, localOffset.Z)
		local slotLookDirection = localOffset.Z < 0 and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1)
		displaySlots[slotIndex] = createDisplaySlot(displayFolder, slotIndex, baseCFrame * CFrame.new(worldOffset), slotLookDirection)
	end

	local plot = {
		id = plotId,
		side = side,
		laneIndex = laneIndex,
		model = model,
		facingDirection = facingDirection,
		floor = floor,
		packPad = packPad,
		spawnPad = spawnPad,
		ownerSign = ownerSign,
		ownerTopLabel = ownerTopLabel,
		ownerNameLabel = ownerNameLabel,
		ownerSubtitleLabel = ownerSubtitleLabel,
		padTitleLabel = padTitleLabel,
		padSubtitleLabel = padSubtitleLabel,
		padAccent = padAccent,
		padGui = padGui,
		padBarBack = padBarBack,
		padBarFill = padBarFill,
		displaySlots = displaySlots,
		spawnCFrame = CFrame.lookAt(
			spawnPad.Position + Vector3.new(0, 3, 0),
			packPad.Position + Vector3.new(0, 3, 0)
		),
	}

	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))

	return plot
end

function BaseService.BuildBaseMap()
	plots = {}
	assignedPlots = {}

	if basesFolder then
		basesFolder:Destroy()
	end

	basesFolder = make("Folder", {
		Name = "PlayerBases",
	}, Workspace)

	local mapWidth = layout.SideOffset * 2 + layout.PlotSize.X + 40
	local mapLength = layout.PlotSpacing * layout.PlotsPerSide + layout.PlotSize.Z + 80
	make("Part", {
		Name = "LobbyGround",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(48, 54, 64),
		Size = Vector3.new(mapWidth, 4, mapLength),
		CFrame = CFrame.new(0, -2.0, 0),
	}, basesFolder)

	make("Part", {
		Name = "LobbyPlaza",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Pebble,
		Color = Color3.fromRGB(86, 94, 108),
		Size = Vector3.new(mapWidth - 8, 0.2, mapLength - 8),
		CFrame = CFrame.new(0, 0.1, 0),
	}, basesFolder)

	for sideIndex = 1, 2 do
		for laneIndex = 1, layout.PlotsPerSide do
			local plotId = #plots + 1
			local x = sideIndex == 1 and -layout.SideOffset or layout.SideOffset
			local z = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
			local side = sideIndex == 1 and "Left" or "Right"
			table.insert(plots, createPlot(plotId, side, laneIndex, Vector3.new(x, 0.5, z)))
		end
	end

	return plots
end

function BaseService.GetPlots()
	if #plots == 0 then
		BaseService.BuildBaseMap()
	end
	return plots
end

function BaseService.AssignPlot(player)
	if assignedPlots[player] then
		return assignedPlots[player]
	end

	if #plots == 0 then
		BaseService.BuildBaseMap()
	end

	for _, plot in ipairs(plots) do
		if not plot.ownerPlayer then
			plot.ownerPlayer = player
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			plot.model:SetAttribute("OwnerName", player.DisplayName)
			updateOwnerSign(plot, player.DisplayName, "")
			updatePadLabel(plot, "Rolling Pack", "Preparing your next spawn", Color3.fromRGB(255, 170, 48))
			assignedPlots[player] = plot
			return plot
		end
	end

	return nil
end

function BaseService.ReleasePlot(player)
	local plot = assignedPlots[player]
	if not plot then
		return
	end

	if plot.activePackModel and plot.activePackModel.Parent then
		plot.activePackModel:Destroy()
	end

	plot.activePackModel = nil
	plot.activePackDef = nil
	plot.ownerPlayer = nil
	plot.model:SetAttribute("OwnerUserId", nil)
	plot.model:SetAttribute("OwnerName", nil)
	BaseService.ClearPlotDisplays(plot)
	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	assignedPlots[player] = nil
end

function BaseService.GetPlot(player)
	return assignedPlots[player]
end

function BaseService.GetDisplaySlots(plot)
	return plot and plot.displaySlots or {}
end

function BaseService.SetPlotPadStatus(plot, title, subtitle, color)
	if plot then
		updatePadLabel(plot, title, subtitle, color or Color3.fromRGB(255, 85, 85))
	end
end

function BaseService.SetPlotPadHealth(plot, title, currentValue, maxValue, color)
	if plot then
		updatePadHealth(plot, title, currentValue, maxValue, color or Color3.fromRGB(255, 215, 0))
	end
end

function BaseService.UpdateDisplaySlot(slot, card, incomePerSecond)
	clearDisplayCard(slot)

	if not card then
		setSlotPrompt(slot, "Add Player", "Inventory Empty", false)
		return
	end

	local cardModel = make("Model", {
		Name = "DisplayCard",
	}, slot.model)

	local cardPosition = slot.top.Position + Vector3.new(0, 4.2, 0)
	local cardPart = make("Part", {
		Name = "CardPart",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 20, 10),
		Size = Vector3.new(4.25, 6.2, 0.26),
		CFrame = CFrame.lookAt(cardPosition, cardPosition + slot.lookDirection),
	}, cardModel)

	make("PointLight", {
		Color = Utils.GetRarityColor(card.rarity),
		Range = 12,
		Brightness = 1.7,
	}, cardPart)

	createDisplayCardFace(Enum.NormalId.Front, card, incomePerSecond, cardPart)
	createDisplayCardFace(Enum.NormalId.Back, card, incomePerSecond, cardPart)

	slot.cardModel = cardModel
	slot.model:SetAttribute("Occupied", true)
	setSlotPrompt(slot, "Remove Player", card.name, true)
end

function BaseService.SetDisplaySlotAddReady(slot, objectText, enabled)
	clearDisplayCard(slot)
	setSlotPrompt(slot, "Add Player", objectText or "From Inventory", enabled)
end

function BaseService.ClearPlotDisplays(plot)
	for _, slot in ipairs(plot.displaySlots or {}) do
		clearDisplayCard(slot)
		setSlotPrompt(slot, "Add Player", "Inventory Empty", false)
	end
end

function BaseService.PlaceCharacterAtPlot(player, character)
	local plot = assignedPlots[player]
	local targetCharacter = character or player.Character
	if not plot or not targetCharacter then
		return
	end

	targetCharacter:PivotTo(plot.spawnCFrame)
end

return BaseService
