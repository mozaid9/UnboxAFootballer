local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)

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

local function updateOwnerSign(plot, ownerName, subtitle)
	plot.ownerNameLabel.Text = ownerName
	plot.ownerSubtitleLabel.Text = subtitle
end

local function updatePadLabel(plot, title, subtitle, color)
	plot.padTitleLabel.Text = title
	plot.padSubtitleLabel.Text = subtitle
	plot.padAccent.BackgroundColor3 = color
end

local function createFence(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(120, 84, 40),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createDisplaySlot(parent, index, cframe)
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

	model:SetAttribute("SlotIndex", index)
	model:SetAttribute("Occupied", false)

	return model
end

local function createPlot(plotId, side, laneIndex, position)
	local model = make("Model", {
		Name = "Base" .. plotId,
	}, basesFolder)

	local facingDirection = side == "Left" and 1 or -1
	local baseCFrame = CFrame.new(position)
	local centerDirection = Vector3.new(facingDirection, 0, 0)
	local padOffset = 16
	local signOffset = 20

	local floor = make("Part", {
		Name = "Floor",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(67, 163, 79),
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	local borderTop = createFence(model, Vector3.new(layout.PlotSize.X, 0.7, 1.2), baseCFrame * CFrame.new(0, 0.8, -layout.PlotSize.Z / 2))
	local borderBottom = createFence(model, Vector3.new(layout.PlotSize.X, 0.7, 1.2), baseCFrame * CFrame.new(0, 0.8, layout.PlotSize.Z / 2))
	local borderLeft = createFence(model, Vector3.new(1.2, 0.7, layout.PlotSize.Z), baseCFrame * CFrame.new(-layout.PlotSize.X / 2, 0.8, 0))
	local borderRight = createFence(model, Vector3.new(1.2, 0.7, layout.PlotSize.Z), baseCFrame * CFrame.new(layout.PlotSize.X / 2, 0.8, 0))
	_ = borderTop
	_ = borderBottom
	_ = borderLeft
	_ = borderRight

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

	local ownerSignPosition = position + Vector3.new(facingDirection * signOffset, 4.3, -14)
	local ownerSign = make("Part", {
		Name = "OwnerSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(7, 5, 0.5),
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

	local ownerNameLabel = createSignLabel("UNCLAIMED BASE", UDim2.new(1, -14, 0.44, 0), UDim2.new(0, 7, 0.1, 0), Color3.fromRGB(245, 238, 220), ownerFrame)
	local ownerSubtitleLabel = createSignLabel("Waiting for player", UDim2.new(1, -14, 0.24, 0), UDim2.new(0, 7, 0.58, 0), Color3.fromRGB(180, 176, 164), ownerFrame)
	ownerSubtitleLabel.Font = Enum.Font.GothamBold

	local padGui = make("BillboardGui", {
		Name = "PadGui",
		Size = UDim2.fromOffset(168, 48),
		StudsOffset = Vector3.new(0, 3.7, 0),
		AlwaysOnTop = true,
		MaxDistance = 120,
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
	local padSubtitleLabel = createSignLabel("Waiting for owner", UDim2.new(1, -24, 0, 14), UDim2.new(0, 22, 0, 24), Color3.fromRGB(180, 176, 164), padFrame)
	padTitleLabel.TextScaled = false
	padTitleLabel.TextSize = 18
	padTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.TextScaled = false
	padSubtitleLabel.TextSize = 11
	padSubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	padSubtitleLabel.Font = Enum.Font.GothamBold

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
		displaySlots[slotIndex] = createDisplaySlot(displayFolder, slotIndex, baseCFrame * CFrame.new(worldOffset))
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
		displaySlots = displaySlots,
		spawnCFrame = CFrame.lookAt(
			spawnPad.Position + Vector3.new(0, 3, 0),
			spawnPad.Position + Vector3.new(0, 3, 0) + centerDirection
		),
	}

	updateOwnerSign(plot, "UNCLAIMED BASE", "Waiting for player")
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
			updateOwnerSign(plot, player.DisplayName, "Your club base")
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
	updateOwnerSign(plot, "UNCLAIMED BASE", "Waiting for player")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	assignedPlots[player] = nil
end

function BaseService.GetPlot(player)
	return assignedPlots[player]
end

function BaseService.SetPlotPadStatus(plot, title, subtitle, color)
	if plot then
		updatePadLabel(plot, title, subtitle, color or Color3.fromRGB(255, 85, 85))
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
