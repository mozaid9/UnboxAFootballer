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

local function formatStadiumTitle(ownerName)
	if not ownerName or ownerName == "" then
		return "OPEN STADIUM"
	end

	return string.upper(ownerName) .. "'S STADIUM"
end

local function updateOwnerSign(plot, ownerName, subtitle)
	plot.ownerNameLabel.Text = formatStadiumTitle(ownerName)
	plot.ownerSubtitleLabel.Text = subtitle or ""
	plot.ownerSubtitleLabel.Visible = subtitle ~= nil and subtitle ~= ""
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
	local gui = make("SurfaceGui", {
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, parent)

	local frame = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 18, 10),
		BorderSizePixel = 0,
	}, gui)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 234, 158)),
			ColorSequenceKeypoint.new(0.45, Utils.GetRarityColor(card.rarity)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(112, 82, 14)),
		}),
		Rotation = 22,
	}, frame)

	make("UIStroke", {
		Color = Color3.fromRGB(24, 18, 8),
		Thickness = 2,
	}, frame)

	createSignLabel(tostring(card.rating), UDim2.new(0.32, 0, 0.16, 0), UDim2.new(0.08, 0, 0.05, 0), Color3.fromRGB(24, 16, 8), frame).TextXAlignment = Enum.TextXAlignment.Left
	createSignLabel(card.position, UDim2.new(0.26, 0, 0.08, 0), UDim2.new(0.08, 0, 0.16, 0), Color3.fromRGB(48, 38, 12), frame).TextXAlignment = Enum.TextXAlignment.Left
	createSignLabel(card.name, UDim2.new(0.82, 0, 0.14, 0), UDim2.new(0.09, 0, 0.56, 0), Color3.fromRGB(30, 22, 10), frame)
	createSignLabel(card.nation, UDim2.new(0.74, 0, 0.08, 0), UDim2.new(0.13, 0, 0.72, 0), Color3.fromRGB(54, 42, 14), frame)
	createSignLabel("+" .. tostring(incomePerSecond) .. "/s", UDim2.new(0.78, 0, 0.1, 0), UDim2.new(0.11, 0, 0.84, 0), Color3.fromRGB(22, 74, 38), frame)
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
	local entrancePillarHeight = wallHeight + 2
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

	local ownerSignPosition = position + (centerDirection * (layout.PlotSize.X / 2 + 1.2)) + Vector3.new(0, wallHeight + 2.7, 0)
	local entranceBeam = createFence(
		model,
		Vector3.new(entrancePillarWidth + 0.8, 1.1, entranceWidth + 0.8),
		baseCFrame * CFrame.new(frontEdgeX + (facingDirection * 0.8), wallHeight + 2.4, 0)
	)
	_ = entranceBeam
	local ownerSign = make("Part", {
		Name = "OwnerSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(14, 3.5, 0.6),
		CFrame = CFrame.lookAt(ownerSignPosition, ownerSignPosition + centerDirection),
	}, model)

	local ownerGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, ownerSign)

	local ownerFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 14, 24),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, ownerGui)

	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 3,
	}, ownerFrame)

	local ownerNameLabel = createSignLabel("OPEN STADIUM", UDim2.new(1, -18, 0.56, 0), UDim2.new(0, 9, 0.14, 0), Color3.fromRGB(245, 238, 220), ownerFrame)
	local ownerSubtitleLabel = createSignLabel("Walk in and claim it", UDim2.new(1, -18, 0.16, 0), UDim2.new(0, 9, 0.72, 0), Color3.fromRGB(180, 176, 164), ownerFrame)
	ownerSubtitleLabel.Font = Enum.Font.GothamBold

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
		displaySlots[slotIndex] = createDisplaySlot(displayFolder, slotIndex, baseCFrame * CFrame.new(worldOffset), centerDirection)
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
			spawnPad.Position + Vector3.new(0, 3, 0) + centerDirection
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
