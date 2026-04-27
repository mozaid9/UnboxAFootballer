local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Utils = require(ReplicatedStorage.Shared.Utils)

local BaseService = {}

local layout = Constants.BaseLayout
local fanZoneConfig = Constants.FanZone
local packMilestones = Constants.PackMilestones
local basesFolder
local plots = {}
local assignedPlots = {}
local animatedTurnstiles = {}

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function replaceLightingEffect(className, name, props)
	local oldEffect = Lighting:FindFirstChild(name)
	if oldEffect then
		oldEffect:Destroy()
	end

	props = props or {}
	props.Name = name
	return make(className, props, Lighting)
end

local function configureMapLighting()
	Lighting.ClockTime = 19.25
	Lighting.Brightness = 1.9
	Lighting.Ambient = Color3.fromRGB(96, 108, 136)
	Lighting.OutdoorAmbient = Color3.fromRGB(68, 78, 104)
	Lighting.EnvironmentDiffuseScale = 0.58
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.FogColor = Color3.fromRGB(42, 51, 68)
	Lighting.FogStart = 320
	Lighting.FogEnd = 760

	replaceLightingEffect("Atmosphere", "UnboxNightAtmosphere", {
		Density = 0.16,
		Offset = 0.04,
		Color = Color3.fromRGB(185, 204, 230),
		Decay = Color3.fromRGB(38, 46, 62),
		Glare = 0.18,
		Haze = 0.95,
	})

	replaceLightingEffect("BloomEffect", "UnboxGoldBloom", {
		Intensity = 0.018,
		Size = 8,
		Threshold = 3.4,
	})

	replaceLightingEffect("ColorCorrectionEffect", "UnboxColorGrade", {
		Brightness = 0,
		Contrast = 0.05,
		Saturation = 0.08,
		TintColor = Color3.fromRGB(242, 247, 255),
	})
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

local function getNextPackMilestone(totalPacks)
	totalPacks = math.max(0, totalPacks or 0)

	local bestMilestone
	for _, milestone in ipairs(packMilestones or {}) do
		local interval = milestone.interval
		if type(interval) == "number" and interval > 0 then
			local nextAt = (math.floor(totalPacks / interval) + 1) * interval
			local previousAt = nextAt - interval
			local progress = math.clamp((totalPacks - previousAt) / interval, 0, 1)
			if not bestMilestone or nextAt < bestMilestone.nextAt or (nextAt == bestMilestone.nextAt and interval > bestMilestone.interval) then
				bestMilestone = {
					interval = interval,
					nextAt = nextAt,
					progress = progress,
					reward = milestone.reward or "Reward",
				}
			end
		end
	end

	return bestMilestone or {
		interval = 50,
		nextAt = 50,
		progress = 0,
		reward = "Rare Pack",
	}
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
	-- Show percentage remaining instead of raw hit numbers
	local pct = math.ceil(ratio * 100)
	plot.padSubtitleLabel.Text = pct .. "% remaining — keep swinging!"
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = true
	-- Bar colour shifts green → yellow → red as health drops
	local r = math.clamp(2 * (1 - ratio), 0, 1)
	local g = math.clamp(2 * ratio, 0, 1)
	plot.padBarFill.BackgroundColor3 = Color3.new(r, g, 0)
	plot.padBarFill.Size = UDim2.new(ratio, 0, 1, 0)
end

local function createFence(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(28, 36, 50),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createStadiumTier(parent, size, cframe)
	make("Part", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(112, 124, 148),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createStadiumWedge(parent, size, cframe)
	make("WedgePart", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(78, 88, 108),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createGlowStrip(parent, name, size, cframe, color, transparency)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = color or Color3.fromRGB(255, 215, 0),
		Transparency = transparency or 0.18,
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createGroundDisk(parent, name, position, diameter, height, color, material, transparency)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Shape = Enum.PartType.Cylinder,
		Material = material or Enum.Material.SmoothPlastic,
		Color = color,
		Transparency = transparency or 0,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
	}, parent)
end

local function createFloatingHubLabel(parent, position, title, subtitle)
	local anchor = make("Part", {
		Name = "FloatingHubLabelAnchor",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
	}, parent)

	local gui = make("BillboardGui", {
		Name = "FloatingHubLabel",
		AlwaysOnTop = false,
		Size = UDim2.fromOffset(320, 96),
		StudsOffset = Vector3.zero,
		MaxDistance = 230,
	}, anchor)

	local frame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 18) }, frame)
	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 2,
		Transparency = 0.16,
	}, frame)

	local titleLabel = createSignLabel(title, UDim2.fromScale(0.92, 0.54), UDim2.fromScale(0.04, 0.08), Color3.fromRGB(255, 215, 0), frame)
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextStrokeTransparency = 0.45
	local subtitleLabel = createSignLabel(subtitle, UDim2.fromScale(0.88, 0.24), UDim2.fromScale(0.06, 0.64), Color3.fromRGB(235, 229, 210), frame)
	subtitleLabel.Font = Enum.Font.GothamBold

	return anchor
end

local function createParticleAnchor(parent, name, position, rate, colorSequence, texture, sizeSequence)
	local anchor = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
	}, parent)

	make("ParticleEmitter", {
		Name = "Particles",
		Texture = texture,
		Color = colorSequence,
		LightEmission = 0.65,
		Rate = rate,
		Lifetime = NumberRange.new(1.4, 2.6),
		Speed = NumberRange.new(1.4, 3.0),
		SpreadAngle = Vector2.new(180, 180),
		Size = sizeSequence,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.72, 0.42),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Acceleration = Vector3.new(0, 1.2, 0),
	}, anchor)

	return anchor
end

local function createPitchLine(parent, name, size, cframe, transparency)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(238, 240, 232),
		Transparency = transparency or 0.02,
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createPitchCircle(parent, baseCFrame, y, radius)
	local segments = 28
	local lineWidth = 0.18
	local segmentLength = (2 * math.pi * radius) / segments * 0.74

	for index = 1, segments do
		local angle = ((index - 1) / segments) * 2 * math.pi
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local yaw = -(angle + (math.pi / 2))

		createPitchLine(
			parent,
			"CenterCircleSegment",
			Vector3.new(segmentLength, 0.045, lineWidth),
			baseCFrame * CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0),
			0.03
		)
	end
end

local function createPenaltyBox(parent, baseCFrame, endX, y, depth, width, lineThickness, namePrefix)
	local direction = endX >= 0 and -1 or 1
	local innerX = endX + direction * depth
	local centerX = endX + direction * (depth / 2)

	createPitchLine(parent, namePrefix .. "InnerLine", Vector3.new(lineThickness, 0.05, width), baseCFrame * CFrame.new(innerX, y, 0), 0.03)
	createPitchLine(parent, namePrefix .. "NorthSide", Vector3.new(depth, 0.05, lineThickness), baseCFrame * CFrame.new(centerX, y, -(width / 2)), 0.03)
	createPitchLine(parent, namePrefix .. "SouthSide", Vector3.new(depth, 0.05, lineThickness), baseCFrame * CFrame.new(centerX, y, width / 2), 0.03)
end

local function createCornerGoal(parent, name, goalCFrame)
	local model = make("Model", {
		Name = name,
	}, parent)

	local goalWidth = 5.4
	local goalHeight = 2.65
	local goalDepth = 1.9
	local thickness = 0.18
	local postColor = Color3.fromRGB(245, 247, 240)
	local netColor = Color3.fromRGB(205, 222, 238)

	local function goalPart(partName, size, localOffset)
		make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = postColor,
			Size = size,
			CFrame = goalCFrame * CFrame.new(localOffset),
		}, model)
	end

	local function netPart(partName, size, localOffset)
		make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = netColor,
			Transparency = 0.24,
			Size = size,
			CFrame = goalCFrame * CFrame.new(localOffset),
		}, model)
	end

	goalPart("LeftPost", Vector3.new(thickness, goalHeight, thickness), Vector3.new(-goalWidth / 2, goalHeight / 2, 0))
	goalPart("RightPost", Vector3.new(thickness, goalHeight, thickness), Vector3.new(goalWidth / 2, goalHeight / 2, 0))
	goalPart("Crossbar", Vector3.new(goalWidth + thickness, thickness, thickness), Vector3.new(0, goalHeight, 0))
	goalPart("BackLeftPost", Vector3.new(thickness, goalHeight * 0.78, thickness), Vector3.new(-goalWidth / 2, (goalHeight * 0.78) / 2, goalDepth))
	goalPart("BackRightPost", Vector3.new(thickness, goalHeight * 0.78, thickness), Vector3.new(goalWidth / 2, (goalHeight * 0.78) / 2, goalDepth))
	goalPart("BackCrossbar", Vector3.new(goalWidth + thickness, thickness, thickness), Vector3.new(0, goalHeight * 0.78, goalDepth))
	goalPart("LeftRoofRail", Vector3.new(thickness, thickness, goalDepth), Vector3.new(-goalWidth / 2, goalHeight * 0.89, goalDepth / 2))
	goalPart("RightRoofRail", Vector3.new(thickness, thickness, goalDepth), Vector3.new(goalWidth / 2, goalHeight * 0.89, goalDepth / 2))

	for index = -2, 2 do
		netPart("BackNetVertical", Vector3.new(0.045, goalHeight * 0.66, 0.045), Vector3.new((goalWidth / 5) * index, goalHeight * 0.36, goalDepth + 0.03))
	end

	for index = 1, 4 do
		netPart("BackNetHorizontal", Vector3.new(goalWidth, 0.045, 0.045), Vector3.new(0, goalHeight * (index / 5), goalDepth + 0.035))
	end

	return model
end

local function createAngledCornerGoal(parent, name, baseCFrame, localX, localZ)
	local worldPosition = (baseCFrame * CFrame.new(localX, 0.6, localZ)).Position
	local lookPosition = (baseCFrame * CFrame.new(0, 0.6, 0)).Position
	createCornerGoal(parent, name, CFrame.lookAt(worldPosition, lookPosition))
end

local function createFootballPitchDetails(parent, baseCFrame)
	local pitchFolder = make("Folder", {
		Name = "FootballPitchDetails",
	}, parent)

	local y = 0.63
	local lineThickness = 0.26
	local pitchLength = layout.PlotSize.X - 10
	local pitchWidth = layout.PlotSize.Z - 8
	local halfLength = pitchLength / 2
	local halfWidth = pitchWidth / 2

	createPitchLine(pitchFolder, "NorthTouchline", Vector3.new(pitchLength, 0.05, lineThickness), baseCFrame * CFrame.new(0, y, -halfWidth), 0.02)
	createPitchLine(pitchFolder, "SouthTouchline", Vector3.new(pitchLength, 0.05, lineThickness), baseCFrame * CFrame.new(0, y, halfWidth), 0.02)
	createPitchLine(pitchFolder, "FrontGoalLine", Vector3.new(lineThickness, 0.05, pitchWidth), baseCFrame * CFrame.new(halfLength, y, 0), 0.02)
	createPitchLine(pitchFolder, "BackGoalLine", Vector3.new(lineThickness, 0.05, pitchWidth), baseCFrame * CFrame.new(-halfLength, y, 0), 0.02)
	createPitchLine(pitchFolder, "HalfwayLine", Vector3.new(lineThickness, 0.05, pitchWidth), baseCFrame * CFrame.new(0, y, 0), 0.06)
	createPitchCircle(pitchFolder, baseCFrame, y + 0.01, 5.7)
	createPitchLine(pitchFolder, "CenterSpot", Vector3.new(0.72, 0.06, 0.72), baseCFrame * CFrame.new(0, y + 0.02, 0), 0.02)

	createPenaltyBox(pitchFolder, baseCFrame, halfLength, y + 0.01, 8.4, 19, lineThickness, "FrontPenalty")
	createPenaltyBox(pitchFolder, baseCFrame, -halfLength, y + 0.01, 8.4, 19, lineThickness, "BackPenalty")
	createPenaltyBox(pitchFolder, baseCFrame, halfLength, y + 0.02, 4.4, 11, lineThickness, "FrontSixYard")
	createPenaltyBox(pitchFolder, baseCFrame, -halfLength, y + 0.02, 4.4, 11, lineThickness, "BackSixYard")

	local cornerGoalX = halfLength - 3
	local cornerGoalZ = halfWidth - 2.6
	createAngledCornerGoal(pitchFolder, "NorthEastCornerGoal", baseCFrame, cornerGoalX, -cornerGoalZ)
	createAngledCornerGoal(pitchFolder, "SouthEastCornerGoal", baseCFrame, cornerGoalX, cornerGoalZ)
	createAngledCornerGoal(pitchFolder, "NorthWestCornerGoal", baseCFrame, -cornerGoalX, -cornerGoalZ)
	createAngledCornerGoal(pitchFolder, "SouthWestCornerGoal", baseCFrame, -cornerGoalX, cornerGoalZ)

	return pitchFolder
end

local createSurfaceText

local function createPlanter(parent, position, scale)
	scale = scale or 1

	local model = make("Model", {
		Name = "Planter",
	}, parent)

	make("Part", {
		Name = "Base",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 23, 34),
		Size = Vector3.new(4.2, 1.2, 4.2) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 0.6 * scale, 0)),
	}, model)

	make("Part", {
		Name = "Bush",
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(42, 126, 52),
		Size = Vector3.new(4.6, 3.4, 4.6) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 2.4 * scale, 0)),
	}, model)

	return model
end

local function prepareImportedModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			descendant.Enabled = false
		end
	end
end

local function tryCreateImportedFloodlight(parent, name, position, targetPosition, targetHeight)
	local assetId = fanZoneConfig.FloodlightAssetId
	if type(assetId) ~= "number" or assetId <= 0 then
		return nil
	end

	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not ok or not loaded then
		warn("[UnboxAFootballer] Could not load floodlight asset " .. tostring(assetId) .. ": " .. tostring(loaded))
		return nil
	end

	loaded.Name = name
	loaded.Parent = parent
	prepareImportedModel(loaded)

	local _, size = loaded:GetBoundingBox()
	local scale = math.clamp((targetHeight or 31) / math.max(size.Y, 0.1), 0.12, 4)
	pcall(function()
		loaded:ScaleTo(scale)
	end)

	local targetFlat = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
	loaded:PivotTo(CFrame.lookAt(position, targetFlat))

	local boundsCFrame, boundsSize = loaded:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	loaded:PivotTo(loaded:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))

	return loaded
end

local function tryCreateImportedDecor(parent, name, assetId, position, facingPos, targetHeight)
	if type(assetId) ~= "number" or assetId <= 0 then
		return nil
	end

	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not ok or not loaded then
		warn("[UnboxAFootballer] Could not load decor asset " .. tostring(assetId) .. ": " .. tostring(loaded))
		return nil
	end

	loaded.Name = name
	loaded.Parent = parent
	prepareImportedModel(loaded)

	local _, size = loaded:GetBoundingBox()
	local scale = math.clamp((targetHeight or 8) / math.max(size.Y, 0.1), 0.08, 5)
	pcall(function()
		loaded:ScaleTo(scale)
	end)

	local lookAt = facingPos or (position + Vector3.new(0, 0, -1))
	loaded:PivotTo(CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)))

	local boundsCFrame, boundsSize = loaded:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	loaded:PivotTo(loaded:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))

	return loaded
end

-- Loads the shared stadium seats/bleacher model and places one copy on each
-- of the three stand sides (north, south, back).  Scales by the widest
-- horizontal axis so the seats span the full stand width.  Fails silently.
local function tryAddStadiumSeats(parent, baseCFrame, facingDirection, assetId)
	if type(assetId) ~= "number" or assetId <= 0 then return end

	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not loaded then
		warn("[BaseService] Stadium seats load failed:", assetId, loaded)
		return
	end
	prepareImportedModel(loaded)

	local _, rawSize = loaded:GetBoundingBox()
	local rawSpan = math.max(rawSize.X, rawSize.Z, 0.1)
	if rawSpan <= 0.1 then loaded:Destroy() return end

	local pitchPos   = baseCFrame.Position
	local floorY     = pitchPos.Y + layout.PlotSize.Y / 2
	local sideWidth  = layout.PlotSize.X - 10           -- 46 studs
	local backWidth  = layout.PlotSize.Z + 8            -- 52 studs
	local sideStandZ = layout.PlotSize.Z / 2 + 9        -- centre of side stand
	local backStandX = layout.PlotSize.X / 2 + 7        -- centre of back stand

	local function placeSide(name, worldPos, lookTarget, widthTarget)
		local scaleF = math.clamp(widthTarget / rawSpan, 0.04, 10)
		local clone = loaded:Clone()
		clone.Name = name
		clone.Parent = parent
		pcall(function() clone:ScaleTo(scaleF) end)
		clone:PivotTo(CFrame.lookAt(worldPos, Vector3.new(lookTarget.X, worldPos.Y, lookTarget.Z)))
		local bc, bs = clone:GetBoundingBox()
		clone:PivotTo(clone:GetPivot() + Vector3.new(0, floorY - (bc.Position.Y - bs.Y * 0.5), 0))
	end

	-- North stand (Z negative): fans face south toward the pitch
	placeSide("StadiumSeatsNorth",
		pitchPos + Vector3.new(0, 0, -sideStandZ),
		pitchPos,
		sideWidth)

	-- South stand (Z positive): fans face north toward the pitch
	placeSide("StadiumSeatsSouth",
		pitchPos + Vector3.new(0, 0, sideStandZ),
		pitchPos,
		sideWidth)

	-- Back stand: fans face toward the entrance / pitch front
	placeSide("StadiumSeatsBack",
		pitchPos + Vector3.new(-facingDirection * backStandX, 0, 0),
		pitchPos + Vector3.new(facingDirection * 20, 0, 0),
		backWidth)

	loaded:Destroy()
end

local function createFloodlightBeam(parent, name, position, targetPosition, poleHeight, options)
	options = options or {}
	local anchorPosition = position + Vector3.new(0, poleHeight + 1.5, 0)
	local anchor = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.lookAt(anchorPosition, targetPosition),
	}, parent)

	make("SpotLight", {
		Name = "FloodBeam",
		Face = Enum.NormalId.Front,
		Color = Color3.fromRGB(255, 245, 218),
		Range = options.range or 112,
		Angle = options.angle or 52,
		Brightness = options.brightness or 1.85,
		Shadows = false,
	}, anchor)

	make("PointLight", {
		Name = "FloodFill",
		Color = Color3.fromRGB(255, 235, 190),
		Range = options.fillRange or 28,
		Brightness = options.fillBrightness or 0.18,
		Shadows = false,
	}, anchor)

	return anchor
end

local function createFloodlightRig(parent, name, position, targetPosition, options)
	options = options or {}
	local model = make("Model", {
		Name = name,
	}, parent)

	local poleHeight = options.poleHeight or 30
	local imported = tryCreateImportedFloodlight(model, "ImportedFloodlight", position, targetPosition, options.modelHeight or 31)
	createFloodlightBeam(model, "LightAnchor", position, targetPosition, poleHeight, options)

	if imported then
		return model
	end

	make("Part", {
		Name = "Pole",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(1.2, poleHeight, 1.2),
		CFrame = CFrame.new(position + Vector3.new(0, poleHeight / 2, 0)),
	}, model)

	local panelPosition = position + Vector3.new(0, poleHeight + 1.5, 0)
	local panel = make("Part", {
		Name = "LightPanel",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(12.5, 6.2, 0.55),
		CFrame = CFrame.lookAt(panelPosition, targetPosition),
	}, model)

	for row = 1, 2 do
		for column = 1, 4 do
			local x = -3.9 + ((column - 1) * 2.6)
			local y = -1.15 + ((row - 1) * 2.3)
			make("Part", {
				Name = "Bulb",
				Anchored = true,
				CanCollide = false,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 250, 225),
				Size = Vector3.new(1.45, 1.45, 0.42),
				CFrame = panel.CFrame * CFrame.new(x, y, -0.38),
			}, model)
		end
	end

	return model
end

local function createLightPost(parent, name, position, targetPosition)
	local model = make("Model", {
		Name = name,
	}, parent)

	local poleHeight = 11
	make("Part", {
		Name = "Pole",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(0.55, poleHeight, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, poleHeight / 2, 0)),
	}, model)

	local headPosition = position + Vector3.new(0, poleHeight + 0.65, 0)
	local head = make("Part", {
		Name = "LightHead",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(3.5, 1.55, 0.42),
		CFrame = CFrame.lookAt(headPosition, targetPosition),
	}, model)

	for index = 1, 3 do
		make("Part", {
			Name = "Bulb",
			Anchored = true,
			CanCollide = false,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 245, 210),
			Size = Vector3.new(0.72, 0.72, 0.25),
			CFrame = head.CFrame * CFrame.new(-1.1 + ((index - 1) * 1.1), 0, -0.3),
		}, model)
	end

	make("SpotLight", {
		Name = "PostBeam",
		Face = Enum.NormalId.Front,
		Color = Color3.fromRGB(255, 236, 188),
		Range = 48,
		Angle = 42,
		Brightness = 0.86,
		Shadows = false,
	}, head)

	make("PointLight", {
		Name = "PostFill",
		Color = Color3.fromRGB(255, 220, 150),
		Range = 13,
		Brightness = 0.18,
		Shadows = false,
	}, head)

	return model
end

local function createSoftFillLight(parent, name, position, range, brightness, color)
	local anchor = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
	}, parent)

	make("PointLight", {
		Name = "SoftFill",
		Color = color or Color3.fromRGB(255, 232, 178),
		Range = range,
		Brightness = brightness,
		Shadows = false,
	}, anchor)

	return anchor
end

local function createVerticalBanner(parent, name, position, lookTarget, title)
	local model = make("Model", {
		Name = name,
	}, parent)

	make("Part", {
		Name = "Post",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(0.55, 10, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, 5, 0)),
	}, model)

	local banner = make("Part", {
		Name = "Banner",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(4.8, 8.5, 0.35),
		CFrame = CFrame.lookAt(position + Vector3.new(0, 6.2, 0), lookTarget),
	}, model)
	createSurfaceText(banner, title, "FOOTBALLER")

	return model
end

local function createFanZoneBench(parent, name, position, facingPos)
	local model = make("Model", {
		Name = name,
	}, parent)

	local cframe = CFrame.lookAt(position + Vector3.new(0, 1.15, 0), Vector3.new(facingPos.X, position.Y + 1.15, facingPos.Z))

	make("Part", {
		Name = "Seat",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(132, 86, 42),
		Size = Vector3.new(7.2, 0.34, 1.25),
		CFrame = cframe,
	}, model)

	make("Part", {
		Name = "Back",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(116, 74, 36),
		Size = Vector3.new(7.2, 1.1, 0.28),
		CFrame = cframe * CFrame.new(0, 0.55, 0.76) * CFrame.Angles(math.rad(-10), 0, 0),
	}, model)

	for x = -2.7, 2.7, 5.4 do
		make("Part", {
			Name = "Leg",
			Anchored = true,
			CanCollide = true,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(28, 32, 42),
			Size = Vector3.new(0.26, 1.1, 0.26),
			CFrame = cframe * CFrame.new(x, -0.68, -0.28),
		}, model)
		make("Part", {
			Name = "Leg",
			Anchored = true,
			CanCollide = true,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(28, 32, 42),
			Size = Vector3.new(0.26, 1.1, 0.26),
			CFrame = cframe * CFrame.new(x, -0.68, 0.42),
		}, model)
	end

	return model
end

local function createFanZoneBoard(parent, name, position, facingPos, title, subtitle)
	local board = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(16, 3.2, 0.45),
		CFrame = CFrame.lookAt(position, Vector3.new(facingPos.X, position.Y, facingPos.Z)),
	}, parent)
	createSurfaceText(board, title, subtitle or "")
	return board
end

local function createWaypoint(parent, name, position)
	make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(position),
	}, parent)
end

createSurfaceText = function(part, title, subtitle)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = make("SurfaceGui", {
			Face = face,
			PixelsPerStud = 90,
			LightInfluence = 0,
		}, part)

		local frame = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(8, 12, 20),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, gui)

		make("UIStroke", {
			Color = Color3.fromRGB(255, 215, 0),
			Thickness = 3,
		}, frame)

		createSignLabel(title, UDim2.fromScale(0.92, 0.42), UDim2.fromScale(0.04, 0.15), Color3.fromRGB(255, 215, 0), frame)
		if subtitle and subtitle ~= "" then
			local subtitleLabel = createSignLabel(subtitle, UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.07, 0.62), Color3.fromRGB(245, 238, 220), frame)
			subtitleLabel.Font = Enum.Font.GothamBold
		end
	end
end

local function createTurnstile(parent, cframe)
	local model = make("Model", {
		Name = "Turnstile",
	}, parent)

	local post = make("Part", {
		Name = "Post",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(170, 130, 42),
		Size = Vector3.new(0.35, 3.4, 0.35),
		CFrame = cframe,
	}, model)

	local arms = {}
	for index = 1, 4 do
		local angle = math.rad((index - 1) * 90)
		local arm = make("Part", {
			Name = "Arm" .. index,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(255, 215, 0),
			Size = Vector3.new(2.3, 0.14, 0.14),
			CFrame = cframe * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, angle, 0),
		}, model)
		table.insert(arms, { part = arm, angle = angle })
	end

	table.insert(animatedTurnstiles, {
		post = post,
		arms = arms,
		baseCFrame = cframe,
	})

	return model
end

local function startTurnstileAnimations()
	for _, turnstile in ipairs(animatedTurnstiles) do
		task.spawn(function()
			local spin = math.random() * math.pi
			while turnstile.post.Parent do
				spin += math.rad(4)
				for _, armData in ipairs(turnstile.arms) do
					if armData.part.Parent then
						armData.part.CFrame = turnstile.baseCFrame * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, spin + armData.angle, 0)
					end
				end
				task.wait(0.04)
			end
		end)
	end
end

local function createFanGate(parent, name, z, facingDirection)
	local gate = make("Model", {
		Name = name,
	}, parent)

	local center = Vector3.new(0, 0, z)
	local columnColor = Color3.fromRGB(24, 30, 42)
	local signColor = Color3.fromRGB(8, 12, 20)
	local lookDirection = Vector3.new(0, 0, facingDirection)

	make("Part", {
		Name = "LeftColumn",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = columnColor,
		Size = Vector3.new(4, 13, 4),
		CFrame = CFrame.new(center + Vector3.new(-17, 6.5, 0)),
	}, gate)

	make("Part", {
		Name = "RightColumn",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = columnColor,
		Size = Vector3.new(4, 13, 4),
		CFrame = CFrame.new(center + Vector3.new(17, 6.5, 0)),
	}, gate)

	make("Part", {
		Name = "TopBeam",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = columnColor,
		Size = Vector3.new(40, 3, 4),
		CFrame = CFrame.new(center + Vector3.new(0, 11.5, 0)),
	}, gate)

	local sign = make("Part", {
		Name = "WelcomeSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = signColor,
		Size = Vector3.new(30, 7.5, 0.5),
		CFrame = CFrame.lookAt(center + Vector3.new(0, 16.5, -facingDirection * 0.3), center + Vector3.new(0, 16.5, -facingDirection * 0.3) + lookDirection),
	}, gate)

	-- Custom sign GUI — fixed size constraints prevent text squishing on a wide panel
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = make("SurfaceGui", {
			Face = face,
			PixelsPerStud = 50,
			LightInfluence = 0,
		}, sign)

		local frame = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(8, 12, 20),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, gui)

		make("UIStroke", { Color = Color3.fromRGB(255, 215, 0), Thickness = 3 }, frame)

		-- Gold top accent bar
		make("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 215, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 8),
		}, frame)

		-- "WELCOME FANS!" — large, constrained so it doesn't over-stretch
		local title = make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.88, 0.52),
			Position = UDim2.fromScale(0.06, 0.07),
			Text = "WELCOME FANS!",
			TextColor3 = Color3.fromRGB(255, 215, 0),
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, frame)
		make("UITextSizeConstraint", { MaxTextSize = 110, MinTextSize = 20 }, title)

		-- Divider
		make("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 215, 0),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.75, 0.022),
			Position = UDim2.fromScale(0.125, 0.62),
		}, frame)

		-- "TURNSTILES" — smaller subtitle
		local sub = make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.6, 0.26),
			Position = UDim2.fromScale(0.2, 0.66),
			Text = "TURNSTILES",
			TextColor3 = Color3.fromRGB(195, 188, 168),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, frame)
		make("UITextSizeConstraint", { MaxTextSize = 55, MinTextSize = 10 }, sub)
	end

	for index = 1, 3 do
		local x = -8 + ((index - 1) * 8)
		createTurnstile(gate, CFrame.new(center + Vector3.new(x, 2.1, -facingDirection * 2)))
	end

	return gate
end

-- ── Food kiosk ────────────────────────────────────────────────────────────────
-- Concession stand with bright red/yellow market colours so it reads clearly
-- against the dark plaza.  `position` is the base centre (Y=0).
-- `facingPos` is the direction the serving counter faces (toward the walkway).
local function sanitizeImportedAsset(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = true
		end
	end
end

local function tryCreateImportedKiosk(parent, name, position, signText, facingPos, assetId)
	if type(assetId) ~= "number" or assetId <= 0 then
		return nil
	end

	local loadedOk, assetRoot = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not loadedOk or not assetRoot then
		warn("[BaseService] Could not load kiosk asset", assetId, assetRoot)
		return nil
	end

	local model = make("Model", { Name = name }, parent)
	for _, child in ipairs(assetRoot:GetChildren()) do
		child.Parent = model
	end
	assetRoot:Destroy()
	sanitizeImportedAsset(model)

	local hasParts = false
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			hasParts = true
			break
		end
	end

	if not hasParts then
		model:Destroy()
		warn("[BaseService] Kiosk asset has no usable parts", assetId)
		return nil
	end

	local _, size = model:GetBoundingBox()
	local maxHorizontal = math.max(size.X, size.Z, 0.1)
	local scale = math.clamp(8.5 / maxHorizontal, 0.15, 4)
	pcall(function()
		model:ScaleTo(scale)
	end)

	local targetCFrame = CFrame.lookAt(
		position,
		Vector3.new(facingPos.X, position.Y, facingPos.Z)
	)
	model:PivotTo(targetCFrame)

	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	model:PivotTo(model:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))

	local sign = make("Part", {
		Name = "KioskLoadedSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(255, 183, 53),
		Transparency = 0.0,
		Size = Vector3.new(5.2, 1.05, 0.2),
		CFrame = targetCFrame * CFrame.new(0, 4.6, 2.15),
	}, model)
	local signGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 90,
		LightInfluence = 0,
	}, sign)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = signText,
		TextColor3 = Color3.fromRGB(20, 12, 0),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, signGui)

	return model
end

-- Per-stall colour palettes so each fallback booth looks distinct even
-- when InsertService can't load the Toolbox model.
local KIOSK_THEMES = {
	-- 1: POPCORN — warm butter yellow
	{ booth = Color3.fromRGB(34, 28, 10),  canopy = Color3.fromRGB(252, 210, 0),  stripe = Color3.fromRGB(232, 160, 0),  sign = Color3.fromRGB(255, 210, 40),  light = Color3.fromRGB(255, 215, 80) },
	-- 2: HOT DOGS — classic red & mustard
	{ booth = Color3.fromRGB(168, 28, 18),  canopy = Color3.fromRGB(232, 48, 24),  stripe = Color3.fromRGB(248, 195, 0),  sign = Color3.fromRGB(255, 185, 30),  light = Color3.fromRGB(255, 140, 40) },
	-- 3: BURGERS — rich brown & orange
	{ booth = Color3.fromRGB(82, 44, 14),   canopy = Color3.fromRGB(188, 100, 24), stripe = Color3.fromRGB(240, 155, 30), sign = Color3.fromRGB(248, 130, 18),  light = Color3.fromRGB(240, 120, 30) },
	-- 4: DRINKS — cool blue & cyan
	{ booth = Color3.fromRGB(14, 42, 88),   canopy = Color3.fromRGB(28, 120, 200), stripe = Color3.fromRGB(60, 200, 228), sign = Color3.fromRGB(90, 200, 255),  light = Color3.fromRGB(80, 180, 255) },
}

local function createFoodKiosk(parent, name, position, kioskIndex, facingPos)
	local assets = fanZoneConfig.KioskAssets
	local asset = type(assets) == "table" and assets[kioskIndex or 1]
	local assetId = asset and asset.id or 0
	local signText = asset and asset.label or "FOOD"
	local importedModel = tryCreateImportedKiosk(parent, name, position, signText, facingPos, assetId)
	if importedModel then
		return importedModel
	end

	-- Fallback: hand-built primitive booth with a theme unique to this stall.
	local theme = KIOSK_THEMES[kioskIndex] or KIOSK_THEMES[1]

	local model = make("Model", { Name = name }, parent)

	local flatFacing = Vector3.new(facingPos.X, 0, facingPos.Z)
	local boothCF = CFrame.lookAt(position + Vector3.new(0, 2.1, 0), flatFacing + Vector3.new(0, 2.1, 0))

	-- Main booth body
	make("Part", {
		Name = "Booth",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = theme.booth,
		Size = Vector3.new(6.5, 4.2, 2.4),
		CFrame = boothCF,
	}, model)

	-- White trim band across the top of the booth front
	make("Part", {
		Name = "BoothTopTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(238, 232, 215),
		Size = Vector3.new(6.5, 0.32, 2.42),
		CFrame = boothCF * CFrame.new(0, 2.26, 0),
	}, model)

	-- Serving counter — wood-look tan slab protruding toward customers
	make("Part", {
		Name = "Counter",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(205, 172, 112),
		Size = Vector3.new(6.5, 0.30, 1.2),
		CFrame = boothCF * CFrame.new(0, 0.45, 1.32),
	}, model)

	-- Canopy
	make("Part", {
		Name = "Canopy",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = theme.canopy,
		Size = Vector3.new(8.0, 0.40, 4.6),
		CFrame = boothCF * CFrame.new(0, 2.38, 0.95),
	}, model)

	-- Three contrasting stripes across the canopy
	for i = 1, 3 do
		make("Part", {
			Name = "CanopyStripe" .. i,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.SmoothPlastic,
			Color = theme.stripe,
			Size = Vector3.new(8.0, 0.42, 0.62),
			CFrame = boothCF * CFrame.new(0, 2.39, -1.0 + (i - 1) * 1.08),
		}, model)
	end

	-- Sign above the canopy — themed colour per stall
	local sign = make("Part", {
		Name = "KioskSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = theme.sign,
		Transparency = 0.0,
		Size = Vector3.new(6.0, 1.4, 0.22),
		CFrame = boothCF * CFrame.new(0, 3.55, 1.24),
	}, model)

	local signGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 100,
		LightInfluence = 0,
	}, sign)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = signText,
		TextColor3 = Color3.fromRGB(12, 8, 2),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, signGui)

	return model
end

local function createStallWorker(parent, name, groundPosition, facingPos, shirtColor)
	local model = make("Model", {
		Name = name,
	}, parent)

	local skinColor = Color3.fromRGB(234, 184, 146)
	local pantsColor = Color3.fromRGB(22, 26, 34)
	local pivotPosition = Vector3.new(groundPosition.X, 3.1, groundPosition.Z)
	local flatFacing = Vector3.new(facingPos.X, pivotPosition.Y, facingPos.Z)
	local pivot = CFrame.lookAt(pivotPosition, flatFacing)

	local function part(partName, size, localCFrame, color, material)
		return make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = material or Enum.Material.SmoothPlastic,
			Color = color,
			Size = size,
			CFrame = pivot * localCFrame,
		}, model)
	end

	part("Torso", Vector3.new(1.45, 1.55, 0.75), CFrame.new(0, 0, 0), shirtColor)

	local head = part("Head", Vector3.new(1.05, 1.05, 1.05), CFrame.new(0, 1.33, 0), skinColor)
	make("SpecialMesh", {
		MeshType = Enum.MeshType.Head,
		Scale = Vector3.new(1.05, 1.05, 1.05),
	}, head)
	make("Decal", {
		Name = "Face",
		Texture = "rbxasset://textures/face.png",
		Face = Enum.NormalId.Front,
	}, head)

	part("Left Arm", Vector3.new(0.62, 1.5, 0.62), CFrame.new(-1.03, -0.02, 0), skinColor)
	part("Right Arm", Vector3.new(0.62, 1.5, 0.62), CFrame.new(1.03, -0.02, 0), skinColor)
	part("Left Leg", Vector3.new(0.62, 1.7, 0.62), CFrame.new(-0.36, -1.45, 0), pantsColor)
	part("Right Leg", Vector3.new(0.62, 1.7, 0.62), CFrame.new(0.36, -1.45, 0), pantsColor)

	local apron = part("Apron", Vector3.new(1.16, 0.72, 0.08), CFrame.new(0, -0.18, -0.41), Color3.fromRGB(245, 238, 215), Enum.Material.SmoothPlastic)
	_ = apron

	return model
end

local function createFanZone(mapWidth, mapLength)
	local plaza = make("Model", {
		Name = "FanZone",
	}, basesFolder)

	local modelAssets = fanZoneConfig.ModelAssets or {}
	local waypointFolder = make("Folder", {
		Name = "Waypoints",
	}, plaza)

	local northZ = (mapLength / 2) - 32
	local southZ = -(mapLength / 2) + 32

	make("Part", {
		Name = "MainWalkway",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(54, 63, 80),
		Size = Vector3.new(54, 0.18, mapLength - 64),
		CFrame = CFrame.new(0, 0.24, 0),
	}, plaza)
	make("Part", {
		Name = "MainWalkwayLeftEdge",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(210, 168, 52),
		Transparency = 0.42,
		Size = Vector3.new(0.28, 0.08, mapLength - 78),
		CFrame = CFrame.new(-27, 0.38, 0),
	}, plaza)
	make("Part", {
		Name = "MainWalkwayRightEdge",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(210, 168, 52),
		Transparency = 0.42,
		Size = Vector3.new(0.28, 0.08, mapLength - 78),
		CFrame = CFrame.new(27, 0.38, 0),
	}, plaza)

	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		make("Part", {
			Name = "StadiumPath" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(58, 66, 82),
			Size = Vector3.new((layout.SideOffset * 2) - 22, 0.14, 14),
			CFrame = CFrame.new(0, 0.28, laneZ),
		}, plaza)
		make("Part", {
			Name = "StadiumPathGuideA" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(210, 168, 52),
			Transparency = 0.50,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.22),
			CFrame = CFrame.new(0, 0.4, laneZ - 6.8),
		}, plaza)
		make("Part", {
			Name = "StadiumPathGuideB" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(210, 168, 52),
			Transparency = 0.50,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.22),
			CFrame = CFrame.new(0, 0.4, laneZ + 6.8),
		}, plaza)
	end

	-- ── Pathway lighting ─────────────────────────────────────────────────────
	-- Warm overhead lights every 56 studs along the main walkway
	do
		local LAMP_SPACING = 56
		local lampZ = southZ + 28
		while lampZ < northZ - 20 do
			local anchor = make("Part", {
				Name = "WalkwayLampAnchor",
				Anchored = true, CanCollide = false,
				Transparency = 1,
				Size = Vector3.new(1, 1, 1),
				CFrame = CFrame.new(0, 7.5, lampZ),
			}, plaza)
			make("PointLight", {
				Color = Color3.fromRGB(255, 224, 160),
				Range = 38,
				Brightness = 0.42,
				Shadows = false,
			}, anchor)
			lampZ = lampZ + LAMP_SPACING
		end
	end

	-- Gold accent lights at each stadium lane crossing
	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		for _, xSide in ipairs({ -22, 22 }) do
			local crossAnchor = make("Part", {
				Name = "LaneCrossLamp",
				Anchored = true, CanCollide = false,
				Transparency = 1,
				Size = Vector3.new(1, 1, 1),
				CFrame = CFrame.new(xSide, 5.5, laneZ),
			}, plaza)
			make("PointLight", {
				Color = Color3.fromRGB(255, 210, 80),
				Range = 26,
				Brightness = 0.32,
				Shadows = false,
			}, crossAnchor)
		end
	end

	-- ── FAN ZONE deck: a clean centre area that separates the statue and
	-- concessions from the travel lanes, so the plaza no longer feels like
	-- random props dropped into the road.
	make("Part", {
		Name = "FanZoneDeck",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(36, 43, 57),
		Size = Vector3.new(54, 0.12, 46),
		CFrame = CFrame.new(0, 0.43, 0),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckNorthTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(54, 0.08, 0.28),
		CFrame = CFrame.new(0, 0.52, -23),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckSouthTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(54, 0.08, 0.28),
		CFrame = CFrame.new(0, 0.52, 23),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckWestTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(0.28, 0.08, 46),
		CFrame = CFrame.new(-27, 0.52, 0),
	}, plaza)

	make("Part", {
		Name = "FanZoneDeckEastTrim",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(214, 170, 52),
		Transparency = 0.12,
		Size = Vector3.new(0.28, 0.08, 46),
		CFrame = CFrame.new(27, 0.52, 0),
	}, plaza)

	-- ── Centre podium: three stepped tiers + elevated spinning football ──────────
	-- Roblox cylinders have their length along X, so we rotate 90° on Z to stand
	-- them upright (flat faces become top/bottom).

	-- Tier 1 — wide base (bottom at Y=0, top at Y=3.2)
	make("Part", {
		Name = "PedestalTier1",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 14, 24),
		Size = Vector3.new(3.2, 24, 24),
		CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Tier 2 — mid (bottom ≈ Y=3.3, top ≈ Y=5.9)
	make("Part", {
		Name = "PedestalTier2",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(14, 19, 32),
		Size = Vector3.new(2.6, 16, 16),
		CFrame = CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Tier 3 — top plinth (bottom ≈ Y=6.1, top ≈ Y=8.4)
	make("Part", {
		Name = "PedestalTier3",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 24, 40),
		Size = Vector3.new(2.3, 10, 10),
		CFrame = CFrame.new(0, 7.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- ── Planter ring around the podium ────────────────────────────────
	-- Six smaller planters form a decorative circle at radius 17, just
	-- outside the Tier1 ring (radius ≈ 12).
	local RING_RADIUS = 17
	local RING_COUNT = 6
	for ringIndex = 1, RING_COUNT do
		local angle = math.rad((ringIndex - 1) * (360 / RING_COUNT))
		createPlanter(plaza, Vector3.new(math.cos(angle) * RING_RADIUS, 0, math.sin(angle) * RING_RADIUS), 0.52)
	end

	local statue = tryCreateImportedDecor(plaza, "FootballStatue", modelAssets.FootballStatue, Vector3.new(0, 8.45, 0), Vector3.new(0, 8.45, -12), 12.0)
	if not statue then
		-- Gold football fallback (centre at Y=12.0, radius=3.5 -> bottom Y=8.5)
		local ball = make("Part", {
			Name = "GoldFootball",
			Anchored = true,
			CanCollide = false,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(255, 202, 61),
			Size = Vector3.new(7, 7, 7),
			CFrame = CFrame.new(0, 12.0, 0),
		}, plaza)

		make("PointLight", {
			Color = Color3.fromRGB(255, 215, 0),
			Range = 16,
			Brightness = 0.38,
			Shadows = false,
		}, ball)

		-- Slow spin + tilt so the ball looks like it's rolling in the air.
		task.spawn(function()
			local ballAngle = 0
			local ballBaseY = 12.0
			while ball.Parent do
				ballAngle = ballAngle + math.rad(20) / 30
				local floatOffset = math.sin(os.clock() * 0.85) * 0.38
				ball.CFrame = CFrame.new(0, ballBaseY + floatOffset, 0)
					* CFrame.Angles(math.rad(22), ballAngle, 0)
				task.wait(1 / 30)
			end
		end)
	end

	createFanZoneBoard(plaza, "FanZoneSouthBoard", Vector3.new(0, 3.2, -16), Vector3.new(0, 3.2, -40), "FAN ZONE", "FOOD  •  FANS  •  FOOTBALL")
	createFanZoneBoard(plaza, "FanZoneNorthBoard", Vector3.new(0, 3.2, 16), Vector3.new(0, 3.2, 40), "FAN ZONE", "FOOD  •  FANS  •  FOOTBALL")

	createFanGate(plaza, "NorthFanGate", northZ, -1)
	createFanGate(plaza, "SouthFanGate", southZ, 1)

	-- ── Food & drinks kiosks ──────────────────────────────────────────
	-- Four stalls form a clean food-court shape outside the central deck.
	-- NPCs detour here as they pass through the plaza, then carry on.
	-- Y=0.35 sits the booth base flush on the plaza surface (top ≈ Y=0.33)
	local center0 = Vector3.new(0, 0.35, 0)  -- all stalls face the podium

	createFoodKiosk(plaza, "KioskNW",
		Vector3.new(-36, 0.35, -15), 1, center0)  -- POPCORN

	createFoodKiosk(plaza, "KioskNE",
		Vector3.new(36, 0.35, -15),  2, center0)  -- HOT DOGS

	createFoodKiosk(plaza, "KioskSW",
		Vector3.new(-36, 0.35, 15),  3, center0)  -- BURGERS

	createFoodKiosk(plaza, "KioskSE",
		Vector3.new(36, 0.35, 15),   4, center0)  -- DRINKS

	-- Static stall workers make the food court feel staffed, while moving
	-- crowd NPCs stop at the matching named waypoints below.
	createStallWorker(plaza, "PopcornWorker", Vector3.new(-39.8, 0, -16.6), center0, Color3.fromRGB(248, 203, 42))
	createStallWorker(plaza, "HotDogWorker", Vector3.new(39.8, 0, -16.6), center0, Color3.fromRGB(218, 46, 28))
	createStallWorker(plaza, "BurgerWorker", Vector3.new(-39.8, 0, 16.6), center0, Color3.fromRGB(198, 106, 34))
	createStallWorker(plaza, "DrinkWorker", Vector3.new(39.8, 0, 16.6), center0, Color3.fromRGB(44, 150, 218))

	createFanZoneBench(plaza, "BenchSouthWest", Vector3.new(-15, 0.35, -25), center0)
	createFanZoneBench(plaza, "BenchSouthEast", Vector3.new(15, 0.35, -25), center0)
	createFanZoneBench(plaza, "BenchNorthWest", Vector3.new(-15, 0.35, 25), center0)
	createFanZoneBench(plaza, "BenchNorthEast", Vector3.new(15, 0.35, 25), center0)

	local planterPositions = {
		Vector3.new(-28, 0, -23),
		Vector3.new(28, 0, -23),
		Vector3.new(-28, 0, 23),
		Vector3.new(28, 0, 23),
		Vector3.new(-18, 0, northZ - 18),
		Vector3.new(18, 0, northZ - 18),
		Vector3.new(-18, 0, southZ + 18),
		Vector3.new(18, 0, southZ + 18),
	}
	for _, planterPosition in ipairs(planterPositions) do
		createPlanter(plaza, planterPosition, 0.9)
	end

	createSoftFillLight(plaza, "CenterPlazaFill", Vector3.new(0, 13, 0), 78, 0.3, Color3.fromRGB(255, 225, 170))
	createSoftFillLight(plaza, "NorthPlazaFill", Vector3.new(0, 13, northZ - 8), 68, 0.22, Color3.fromRGB(230, 238, 255))
	createSoftFillLight(plaza, "SouthPlazaFill", Vector3.new(0, 13, southZ + 8), 68, 0.22, Color3.fromRGB(230, 238, 255))
	-- Wide overhead fills directly above the west and east stadium blocks
	createSoftFillLight(plaza, "WestStadiumFill", Vector3.new(-layout.SideOffset, 18, 0), 88, 0.24, Color3.fromRGB(240, 228, 200))
	createSoftFillLight(plaza, "EastStadiumFill", Vector3.new(layout.SideOffset, 18, 0), 88, 0.24, Color3.fromRGB(240, 228, 200))
	-- Per-lane fills so each plot row is independently lit
	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		createSoftFillLight(plaza, "WestLaneFill" .. laneIndex, Vector3.new(-layout.SideOffset, 20, laneZ), 64, 0.18, Color3.fromRGB(235, 225, 195))
		createSoftFillLight(plaza, "EastLaneFill" .. laneIndex, Vector3.new(layout.SideOffset, 20, laneZ), 64, 0.18, Color3.fromRGB(235, 225, 195))
	end

	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		createLightPost(plaza, "LaneWestLightA" .. laneIndex, Vector3.new(-47, 0, laneZ - 24), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneWestLightB" .. laneIndex, Vector3.new(-47, 0, laneZ + 24), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightA" .. laneIndex, Vector3.new(47, 0, laneZ - 24), Vector3.new(layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightB" .. laneIndex, Vector3.new(47, 0, laneZ + 24), Vector3.new(layout.SideOffset, 1, laneZ))
	end

	-- ── Player spawn ─────────────────────────────────────────────────
	-- Roblox Studio adds a default SpawnLocation at (0,0,0) which drops
	-- players onto the central podium.  Remove EVERY SpawnLocation in the
	-- Workspace (including the studio default) then place ours just inside
	-- the south gate so players start at the fan zone entrance.
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
	local spawnLoc = make("SpawnLocation", {
		Name = "FanZoneSpawn",
		Anchored = true,
		CanCollide = true,
		Neutral = true,
		AllowTeamChangeOnTouch = false,
		Duration = 0,
		Transparency = 1,
		Size = Vector3.new(8, 1, 8),
		CFrame = CFrame.new(0, 0.75, southZ + 6),
	}, Workspace)
	_ = spawnLoc

	createWaypoint(waypointFolder, "NorthGate", Vector3.new(0, 3.1, northZ - 10))
	createWaypoint(waypointFolder, "SouthGate", Vector3.new(0, 3.1, southZ + 10))
	createWaypoint(waypointFolder, "Center", Vector3.new(0, 3.1, 0))
	createWaypoint(waypointFolder, "WestLoop", Vector3.new(-16, 3.1, 0))
	createWaypoint(waypointFolder, "EastLoop", Vector3.new(16, 3.1, 0))
	-- Food stand queues: each stall has 4 queue slots running diagonally
	-- back from the counter toward the centre walkway.  Slot 1 is the
	-- front of the queue (talking to the worker), slot 4 is the back.
	-- CrowdService claims slots 1→4 in order so NPCs naturally line up.
	local stallQueueDefs = {
		{ name = "Popcorn", baseX = -36, baseZ = -15 },
		{ name = "HotDogs", baseX =  36, baseZ = -15 },
		{ name = "Burgers", baseX = -36, baseZ =  15 },
		{ name = "Drinks",  baseX =  36, baseZ =  15 },
	}
	for _, stall in ipairs(stallQueueDefs) do
		-- Direction from stall toward plaza centre (0, 0)
		local dx, dz = -stall.baseX, -stall.baseZ
		local mag = math.sqrt((dx * dx) + (dz * dz))
		local ux, uz = dx / mag, dz / mag
		for slot = 1, 4 do
			local d = 4 + (slot * 3)  -- 7, 10, 13, 16 studs from stall
			local px = stall.baseX + (ux * d)
			local pz = stall.baseZ + (uz * d)
			createWaypoint(
				waypointFolder,
				"Food" .. stall.name .. slot,
				Vector3.new(px, 3.1, pz)
			)
		end
	end

	startTurnstileAnimations()
	return plaza
end

local function createDisplayCardFace(face, card, incomePerSecond, parent)
	local style = Utils.GetRarityStyle(card.rarity)
	local rarityColor = style.primary
	local secondaryColor = style.secondary or rarityColor
	local darkColor = style.dark or Color3.fromRGB(16, 12, 8)
	local trimColor = style.trim or rarityColor
	local textColor = style.text or Constants.UI.Text
	local rarityLabel = string.upper(style.label or card.rarity or "CARD")

	local gui = make("SurfaceGui", {
		Face = face,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, parent)

	local frame = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = darkColor,
		BorderSizePixel = 0,
	}, gui)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12)),
			ColorSequenceKeypoint.new(0.42, secondaryColor),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 138,
	}, frame)

	make("UIStroke", {
		Color = trimColor,
		Thickness = 4,
	}, frame)

	local innerBorder = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, -14),
		Position = UDim2.fromOffset(7, 7),
	}, frame)
	make("UIStroke", {
		Color = Color3.fromRGB(24, 16, 4),
		Thickness = 1.5,
		Transparency = 0.55,
	}, innerBorder)

	local rarityBand = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(6, 7, 10),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Size = UDim2.new(0.76, 0, 0.1, 0),
		Position = UDim2.new(0.12, 0, 0.06, 0),
	}, frame)
	local rarityCorner = Instance.new("UICorner")
	rarityCorner.CornerRadius = UDim.new(1, 0)
	rarityCorner.Parent = rarityBand
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.4,
		Transparency = 0.2,
	}, rarityBand)
	local rarityText = createSignLabel(rarityLabel, UDim2.fromScale(0.92, 0.82), UDim2.fromScale(0.04, 0.09), textColor, rarityBand)
	make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 18 }, rarityText)

	local positionBadge = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(9, 11, 17),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.new(0.24, 0, 0.1, 0),
		Position = UDim2.new(0.1, 0, 0.2, 0),
	}, frame)
	local positionCorner = Instance.new("UICorner")
	positionCorner.CornerRadius = UDim.new(0.25, 0)
	positionCorner.Parent = positionBadge
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.2,
		Transparency = 0.25,
	}, positionBadge)
	createSignLabel(card.position or "--", UDim2.fromScale(0.9, 0.82), UDim2.fromScale(0.05, 0.09), textColor, positionBadge)

	local nationLabel = createSignLabel(card.nation or "Unknown", UDim2.new(0.48, 0, 0.08, 0), UDim2.new(0.41, 0, 0.21, 0), textColor, frame)
	nationLabel.TextXAlignment = Enum.TextXAlignment.Right
	make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 14 }, nationLabel)

	local portrait = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(2, 3, 6),
		BackgroundTransparency = 0.24,
		BorderSizePixel = 0,
		Size = UDim2.new(0.54, 0, 0.29, 0),
		Position = UDim2.new(0.23, 0, 0.34, 0),
	}, frame)
	local portraitCorner = Instance.new("UICorner")
	portraitCorner.CornerRadius = UDim.new(0.18, 0)
	portraitCorner.Parent = portrait
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1,
		Transparency = 0.55,
	}, portrait)

	local head = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = textColor,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.12, 0),
		Size = UDim2.fromScale(0.26, 0.25),
	}, portrait)
	local headCorner = Instance.new("UICorner")
	headCorner.CornerRadius = UDim.new(1, 0)
	headCorner.Parent = head

	local shoulders = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = textColor,
		BackgroundTransparency = 0.26,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.43, 0),
		Size = UDim2.fromScale(0.58, 0.34),
	}, portrait)
	local shouldersCorner = Instance.new("UICorner")
	shouldersCorner.CornerRadius = UDim.new(0.35, 0)
	shouldersCorner.Parent = shoulders

	make("Frame", {
		BackgroundColor3 = trimColor,
		BorderSizePixel = 0,
		Size = UDim2.new(0.72, 0, 0, 2),
		Position = UDim2.new(0.14, 0, 0.67, 0),
	}, frame)

	local nameLabel = createSignLabel(string.upper(card.name or "Player"), UDim2.new(0.84, 0, 0.12, 0), UDim2.new(0.08, 0, 0.7, 0), textColor, frame)
	make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 18 }, nameLabel)
	make("UIStroke", {
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 1.2,
		Transparency = 0.3,
	}, nameLabel)

	local incomePill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(26, 58, 32),
		Size = UDim2.new(0.72, 0, 0.11, 0),
		Position = UDim2.new(0.14, 0, 0.84, 0),
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

	createSignLabel("+" .. tostring(incomePerSecond) .. " fans/s", UDim2.fromScale(0.9, 0.72), UDim2.fromScale(0.05, 0.14), Color3.fromRGB(228, 255, 220), incomePill)
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

	local slotW = layout.DisplaySlotSize.X
	local slotH = layout.DisplaySlotSize.Y
	local slotD = layout.DisplaySlotSize.Z
	local topY  = slotH / 2

	-- Pedestal body — dark polished concrete
	local base = make("Part", {
		Name = "Base",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(14, 19, 30),
		Size = layout.DisplaySlotSize,
		CFrame = cframe,
	}, model)

	-- Slim gold neon rim around the top edge (4 strips)
	local rimThickness = 0.22
	local rimHeight    = 0.28
	local rimY         = topY + rimHeight / 2
	local rimColor     = Color3.fromRGB(255, 210, 60)
	local rimTransp    = 0.28
	for _, axis in ipairs({
		{ Vector3.new(slotW, rimHeight, rimThickness), Vector3.new(0,  rimY, -(slotD / 2)) },
		{ Vector3.new(slotW, rimHeight, rimThickness), Vector3.new(0,  rimY,  (slotD / 2)) },
		{ Vector3.new(rimThickness, rimHeight, slotD), Vector3.new(-(slotW / 2), rimY, 0)  },
		{ Vector3.new(rimThickness, rimHeight, slotD), Vector3.new( (slotW / 2), rimY, 0)  },
	}) do
		make("Part", {
			Name = "RimStrip",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = rimColor,
			Transparency = rimTransp,
			Size = axis[1],
			CFrame = cframe + axis[2],
		}, model)
	end

	-- Gold glow display pad on top
	local top = make("Part", {
		Name = "Top",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 205, 50),
		Transparency = 0.52,
		Size = Vector3.new(slotW - 1.6, 0.14, slotD - 1.6),
		CFrame = base.CFrame + Vector3.new(0, topY + 0.08, 0),
	}, model)

	-- Slot number on the player-facing face.
	-- lookDirection points toward the player, so map it to the correct NormalId:
	--   lookDirection.Z > 0  (+Z toward player) → Back face  (+Z = NormalId.Back)
	--   lookDirection.Z < 0  (-Z toward player) → Front face (-Z = NormalId.Front)
	local numFace = lookDirection.Z > 0 and Enum.NormalId.Back or Enum.NormalId.Front
	local numGui = make("SurfaceGui", {
		Name = "SlotNum",
		Face = numFace,
		AlwaysOnTop = false,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 30,
	}, base)
	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = tostring(index),
		TextColor3 = Color3.fromRGB(255, 210, 60),
		TextTransparency = 0.36,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, numGui)

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
	local padInfoMaxDistance = layout.PadInfoMaxDistance or 22
	local wallY = wallHeight / 2 + layout.PlotSize.Y / 2
	local frontEdgeX = facingDirection * (layout.PlotSize.X / 2)
	local backEdgeX = -frontEdgeX

	local floor = make("Part", {
		Name = "Floor",
		Anchored = true,
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(76, 158, 82),
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	local borderTop    = createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY, -layout.PlotSize.Z / 2))
	local borderBottom = createFence(model, Vector3.new(layout.PlotSize.X + wallThickness, wallHeight, wallThickness), baseCFrame * CFrame.new(0, wallY, layout.PlotSize.Z / 2))
	local backWall     = createFence(model, Vector3.new(wallThickness, wallHeight, layout.PlotSize.Z + wallThickness), baseCFrame * CFrame.new(backEdgeX, wallY, 0))
	local frontWallSegmentLength = math.max(8, (layout.PlotSize.Z - entranceWidth) / 2)
	local frontWallZOffset = (entranceWidth / 2) + (frontWallSegmentLength / 2)
	local frontWallNorth = createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY, -frontWallZOffset))
	local frontWallSouth = createFence(model, Vector3.new(wallThickness, wallHeight, frontWallSegmentLength), baseCFrame * CFrame.new(frontEdgeX, wallY, frontWallZOffset))
	local entrancePillarHeight = wallHeight + 5.6
	local entrancePillarX = frontEdgeX + (facingDirection * ((entrancePillarWidth - wallThickness) / 2))
	local entrancePillarNorth = createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2, -(entranceWidth / 2)))
	local entrancePillarSouth = createFence(model, Vector3.new(entrancePillarWidth, entrancePillarHeight, wallThickness + 0.8), baseCFrame * CFrame.new(entrancePillarX, entrancePillarHeight / 2 + layout.PlotSize.Y / 2,  (entranceWidth / 2)))

	-- ── Neon gold trim along wall tops ──────────────────────────────────────────
	local trimH = 0.22
	local trimNeon = Color3.fromRGB(255, 210, 50)
	local trimTransp = 0.18
	for _, wall in ipairs({ borderTop, borderBottom, backWall, frontWallNorth, frontWallSouth }) do
		local topY = wall.Position.Y + wall.Size.Y / 2 + trimH / 2
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = trimNeon,
			Transparency = trimTransp,
			Size = Vector3.new(wall.Size.X + 0.1, trimH, wall.Size.Z + 0.1),
			CFrame = CFrame.new(wall.Position.X, topY, wall.Position.Z),
		}, model)
	end

	-- ── Gold PointLights on pillar tops (atmospheric glow) ─────────────────────
	local pillarTopY = entrancePillarHeight + layout.PlotSize.Y / 2 + 0.5
	for _, pillarPart in ipairs({ entrancePillarNorth, entrancePillarSouth }) do
		local anchor = make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Transparency = 1, Size = Vector3.new(1, 1, 1),
			CFrame = CFrame.new(pillarPart.Position.X, pillarTopY, pillarPart.Position.Z),
		}, model)
		make("PointLight", {
			Brightness = 1.6,
			Range = 20,
			Color = trimNeon,
		}, anchor)
		-- Neon gold cap on pillar top
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = trimNeon,
			Transparency = 0.12,
			Size = Vector3.new(entrancePillarWidth + 0.3, 0.35, wallThickness + 1.1),
			CFrame = CFrame.new(pillarPart.Position.X, pillarTopY - 0.25, pillarPart.Position.Z),
		}, model)
	end

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

	createFootballPitchDetails(model, baseCFrame)

	local packPad = make("Part", {
		Name = "PackPad",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
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
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(76, 158, 82),
		Transparency = 1,
		Size = Vector3.new(7, 0.3, 7),
		CFrame = baseCFrame * CFrame.new(facingDirection * padOffset, 0.45, 0),
	}, model)

	local spawnCFrame = CFrame.lookAt(
		spawnPad.Position + Vector3.new(0, 3, 0),
		packPad.Position + Vector3.new(0, 3, 0)
	)

	local spawnLocation = make("SpawnLocation", {
		Name = "PlayerSpawn",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Neutral = true,
		AllowTeamChangeOnTouch = false,
		Duration = 0,
		Transparency = 1,
		Size = Vector3.new(7, 0.4, 7),
		CFrame = CFrame.lookAt(
			spawnPad.Position + Vector3.new(0, 0.9, 0),
			packPad.Position + Vector3.new(0, 0.9, 0)
		),
	}, model)

	local entranceBeamY = entrancePillarHeight + layout.PlotSize.Y / 2 - 0.6
	local ownerSignPosition = position + (centerDirection * (layout.PlotSize.X / 2 + 2.1)) + Vector3.new(0, entranceBeamY + 3.1, 0)
	local entranceBeam = createFence(
		model,
		Vector3.new(entrancePillarWidth + 1.6, 2.6, entranceWidth + 1.4),
		baseCFrame * CFrame.new(frontEdgeX + (facingDirection * 0.9), entranceBeamY + 0.6, 0)
	)
	-- Neon gold strip along top and bottom of beam
	local beamTopY  = entranceBeam.Position.Y + 2.6 / 2 + 0.14
	local beamBotY  = entranceBeam.Position.Y - 2.6 / 2 - 0.14
	local beamW     = entrancePillarWidth + 1.6 + 0.2
	local beamD     = entranceWidth + 1.4 + 0.1
	for _, trimY in ipairs({ beamTopY, beamBotY }) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 210, 50),
			Transparency = 0.15,
			Size = Vector3.new(beamW, 0.28, beamD),
			CFrame = CFrame.new(entranceBeam.Position.X, trimY, entranceBeam.Position.Z),
		}, model)
	end
	_ = entranceBeam
	-- ── Owner sign: 3-layer redesign ─────────────────────────────────────────────
	local signW   = 16
	local signH   = 4.6
	local signCF  = CFrame.lookAt(ownerSignPosition, ownerSignPosition + centerDirection)
	local goldCol = Color3.fromRGB(255, 210, 50)

	-- Layer 1 — back plate (dark, larger, 0.35 studs behind)
	make("Part", {
		Name = "SignBackPlate",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(5, 8, 16),
		Size = Vector3.new(signW + 1.6, signH + 1.0, 0.5),
		CFrame = signCF * CFrame.new(0, 0, 0.38),
	}, model)

	-- Layer 2 — main sign panel
	local ownerSign = make("Part", {
		Name = "OwnerSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(9, 13, 24),
		Size = Vector3.new(signW, signH, 0.32),
		CFrame = signCF,
	}, model)

	-- Layer 3 — Neon gold border strips (always visible even when SurfaceGui is off)
	local stripT = 0.32
	local stripD = 0.36
	for _, cfg in ipairs({
		-- top
		{ Vector3.new(signW + stripT * 2, stripT, stripD), signCF * CFrame.new(0,  signH / 2 + stripT / 2, 0) },
		-- bottom
		{ Vector3.new(signW + stripT * 2, stripT, stripD), signCF * CFrame.new(0, -(signH / 2 + stripT / 2), 0) },
		-- left
		{ Vector3.new(stripT, signH, stripD), signCF * CFrame.new(-(signW / 2 + stripT / 2), 0, 0) },
		-- right
		{ Vector3.new(stripT, signH, stripD), signCF * CFrame.new( signW / 2 + stripT / 2, 0, 0) },
	}) do
		make("Part", {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = goldCol,
			Transparency = 0.08,
			Size = cfg[1],
			CFrame = cfg[2],
		}, model)
	end

	-- SurfaceLight: illuminates the entrance area below the sign
	make("SurfaceLight", {
		Face = Enum.NormalId.Front,
		Brightness = 2.2,
		Range = 16,
		Color = Color3.fromRGB(255, 238, 195),
		Angle = 65,
	}, ownerSign)

	-- PointLight above sign for atmosphere
	make("PointLight", {
		Brightness = 0.9,
		Range = 18,
		Color = goldCol,
	}, ownerSign)

	-- ── SurfaceGui content ────────────────────────────────────────────────────
	local ownerGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 160,
		LightInfluence = 0,
		ClipsDescendants = true,
	}, ownerSign)

	local ownerFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(8, 12, 22),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, ownerGui)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromRGB(14, 20, 38)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(9,  13, 24)),
			ColorSequenceKeypoint.new(1,    Color3.fromRGB(6,  9,  18)),
		}),
		Rotation = 100,
	}, ownerFrame)

	-- Thin gold accent bar across the top
	make("Frame", {
		BackgroundColor3 = goldCol,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.fromOffset(0, 0),
	}, ownerFrame)

	-- HOME CLUB — tiny, faint, top of sign
	local ownerTopLabel = createOwnerSignText("AVAILABLE PLOT",
		UDim2.fromScale(0.62, 0.10),
		UDim2.fromScale(0.19, 0.08),
		Color3.fromRGB(210, 170, 55),
		{
			textScaled = true,
			minTextSize = 12,
			maxTextSize = 32,
			textStrokeTransparency = 0.96,
			font = Enum.Font.GothamBold,
		}, ownerFrame)

	-- Thin divider below HOME CLUB label
	make("Frame", {
		BackgroundColor3 = goldCol,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Size = UDim2.new(0.68, 0, 0, 1),
		Position = UDim2.fromScale(0.16, 0.195),
	}, ownerFrame)

	-- Player name — medium weight, white
	local ownerNameLabel = createOwnerSignText("OPEN",
		UDim2.fromScale(0.92, 0.30),
		UDim2.fromScale(0.04, 0.21),
		Color3.fromRGB(255, 255, 255),
		{
			textScaled = true,
			minTextSize = 36,
			maxTextSize = 160,
			textStrokeTransparency = 0.68,
			font = Enum.Font.GothamBlack,
		}, ownerFrame)

	-- Bold gold separator
	make("Frame", {
		BackgroundColor3 = goldCol,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.new(0.72, 0, 0, 4),
		Position = UDim2.fromScale(0.14, 0.525),
	}, ownerFrame)

	-- STADIUM — BIGGEST, boldest, bright gold with glow stroke
	local ownerSubtitleLabel = createOwnerSignText("STADIUM",
		UDim2.fromScale(0.96, 0.40),
		UDim2.fromScale(0.02, 0.55),
		Color3.fromRGB(255, 218, 55),
		{
			textScaled = true,
			minTextSize = 50,
			maxTextSize = 230,
			textStrokeTransparency = 0.42,
			font = Enum.Font.GothamBlack,
		}, ownerFrame)

	local milestoneSignPosition = position
		+ Vector3.new(backEdgeX - (facingDirection * 5), 11, 0)
	local milestoneSign = make("Part", {
		Name = "PackMilestoneBillboard",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(6, 9, 16),
		Size = Vector3.new(17, 8.5, 0.5),
		CFrame = CFrame.lookAt(milestoneSignPosition, milestoneSignPosition + centerDirection),
	}, model)

	-- Neon glow light so the board is visible across the plaza
	make("PointLight", {
		Color = Color3.fromRGB(255, 215, 0),
		Range = 20,
		Brightness = 0.55,
		Shadows = false,
	}, milestoneSign)

	local milestoneGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 90,
		LightInfluence = 0,
	}, milestoneSign)

	local milestoneFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, milestoneGui)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, milestoneFrame)

	-- Gold border
	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 3,
		Transparency = 0.0,
	}, milestoneFrame)

	-- Bright gold accent strip across the top
	local topStrip = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromScale(0, 0),
		ZIndex = 2,
	}, milestoneFrame)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, topStrip)
	_ = topStrip

	-- Layout (fractions of board height = 1.0):
	--   0.03 – 0.14  header title
	--   0.14 – 0.50  large packs counter
	--   0.52         divider
	--   0.54 – 0.63  "NEXT REWARD:" label
	--   0.63 – 0.78  reward text
	--   0.80 – 0.93  progress bar

	-- "★ PACK MILESTONES" header
	local milestoneTitleLabel = createOwnerSignText("\u{2605} PACK MILESTONES", UDim2.fromScale(0.90, 0.11), UDim2.fromScale(0.05, 0.03), Color3.fromRGB(255, 215, 0), {
		textScaled = true,
		minTextSize = 14,
		maxTextSize = 36,
		textStrokeTransparency = 0.65,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)
	_ = milestoneTitleLabel

	-- Large packs-opened counter
	local milestonePacksLabel = createOwnerSignText("0 PACKS OPENED", UDim2.fromScale(0.92, 0.34), UDim2.fromScale(0.04, 0.14), Color3.fromRGB(255, 245, 220), {
		textScaled = true,
		minTextSize = 22,
		maxTextSize = 80,
		textStrokeTransparency = 0.58,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)

	-- Divider
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BackgroundTransparency = 0.50,
		BorderSizePixel = 0,
		Size = UDim2.new(0.84, 0, 0, 2),
		Position = UDim2.fromScale(0.08, 0.52),
	}, milestoneFrame)

	-- "NEXT REWARD:" — small muted label
	createOwnerSignText("NEXT REWARD:", UDim2.fromScale(0.88, 0.09), UDim2.fromScale(0.06, 0.54), Color3.fromRGB(170, 165, 148), {
		textScaled = true,
		minTextSize = 10,
		maxTextSize = 22,
		textStrokeTransparency = 0.88,
		font = Enum.Font.GothamBold,
	}, milestoneFrame)

	-- Reward name — prominent gold, starts clearly below the label above
	local milestoneNextLabel = createOwnerSignText("50 PACKS \u{2192} RARE PACK", UDim2.fromScale(0.88, 0.15), UDim2.fromScale(0.06, 0.63), Color3.fromRGB(255, 210, 80), {
		textScaled = true,
		minTextSize = 12,
		maxTextSize = 38,
		textStrokeTransparency = 0.65,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)

	-- Progress bar track
	local milestoneBarBack = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 28, 44),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.84, 0.082),
		Position = UDim2.fromScale(0.08, 0.81),
	}, milestoneFrame)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarBack)
	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 2,
		Transparency = 0.50,
	}, milestoneBarBack)

	local milestoneBarFill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	}, milestoneBarBack)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarFill)

	-- Shimmer highlight on bar fill
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 200),
		BackgroundTransparency = 0.52,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0.38, 0),
		Position = UDim2.fromScale(0, 0),
	}, milestoneBarFill)

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

	local entranceLightX = frontEdgeX + (facingDirection * 8)
	createLightPost(model, "EntranceLightNorth", position + Vector3.new(entranceLightX, 0, -(entranceWidth / 2 + 6)), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "EntranceLightSouth", position + Vector3.new(entranceLightX, 0,  (entranceWidth / 2 + 6)), packPad.Position + Vector3.new(0, 2, 0))

	-- Decorative side banners flanking the entrance
	local bannerX = frontEdgeX + (facingDirection * 3.5)
	createVerticalBanner(model, "BannerNorth",
		position + Vector3.new(bannerX, 0, -(entranceWidth / 2 + 4.5)),
		packPad.Position,
		"FC")
	createVerticalBanner(model, "BannerSouth",
		position + Vector3.new(bannerX, 0,  (entranceWidth / 2 + 4.5)),
		packPad.Position,
		"FC")
	createLightPost(model, "BackStandLightNorth", position + Vector3.new(backEdgeX - (facingDirection * 8), 0, -(layout.PlotSize.Z / 2 + 5)), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "BackStandLightSouth", position + Vector3.new(backEdgeX - (facingDirection * 8), 0, layout.PlotSize.Z / 2 + 5), packPad.Position + Vector3.new(0, 2, 0))
	local stadiumFloodlightOptions = {
		poleHeight = 27,
		modelHeight = 29,
		range = 68,
		angle = 46,
		brightness = 1.38,
		fillRange = 18,
		fillBrightness = 0.1,
	}
	local floodlightBackX = backEdgeX - (facingDirection * 15)
	local floodlightSideZ = (layout.PlotSize.Z / 2) + 10
	local floodlightTarget = position + Vector3.new(-facingDirection * 4, 3, 0)
	createFloodlightRig(model, "StadiumFloodlightNorth", position + Vector3.new(floodlightBackX, 0, -floodlightSideZ), floodlightTarget, stadiumFloodlightOptions)
	createFloodlightRig(model, "StadiumFloodlightSouth", position + Vector3.new(floodlightBackX, 0, floodlightSideZ), floodlightTarget, stadiumFloodlightOptions)
	createSoftFillLight(model, "StadiumSoftFill", position + Vector3.new(0, 12, 0), 38, 0.22, Color3.fromRGB(255, 232, 184))
	createSoftFillLight(model, "BackStandFill", position + Vector3.new(backEdgeX - (facingDirection * 6), 8, 0), 30, 0.17, Color3.fromRGB(225, 234, 255))
	createSoftFillLight(model, "NorthStandFill", position + Vector3.new(0, 7, -(layout.PlotSize.Z / 2 + 7)), 25, 0.14, Color3.fromRGB(255, 226, 170))
	createSoftFillLight(model, "SouthStandFill", position + Vector3.new(0, 7, layout.PlotSize.Z / 2 + 7), 25, 0.14, Color3.fromRGB(255, 226, 170))

	-- Folder for visuals that change per rebirth tier (seats, lighting, etc.)
	local stadiumExtrasFolder = make("Folder", { Name = "StadiumExtras" }, model)

	local plot = {
		id = plotId,
		side = side,
		laneIndex = laneIndex,
		model = model,
		baseCFrame = baseCFrame,
		facingDirection = facingDirection,
		stadiumExtrasFolder = stadiumExtrasFolder,
		floor = floor,
		packPad = packPad,
		spawnPad = spawnPad,
		spawnLocation = spawnLocation,
		ownerSign = ownerSign,
		ownerTopLabel = ownerTopLabel,
		ownerNameLabel = ownerNameLabel,
		ownerSubtitleLabel = ownerSubtitleLabel,
		milestoneSign = milestoneSign,
		milestonePacksLabel = milestonePacksLabel,
		milestoneNextLabel = milestoneNextLabel,
		milestoneBarFill = milestoneBarFill,
		padTitleLabel = padTitleLabel,
		padSubtitleLabel = padSubtitleLabel,
		padAccent = padAccent,
		padGui = padGui,
		padBarBack = padBarBack,
		padBarFill = padBarFill,
		displaySlots = displaySlots,
		spawnCFrame = spawnCFrame,
	}

	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))

	return plot
end

-- Called when a player is assigned a plot or completes a rebirth.
-- Rebuilds the stadium extras folder to match the given rebirth tier.
--   Tier 0: plain concrete stands (nothing extra)
--   Tier 1+: stadium seat model loaded on all three stand sides
function BaseService.UpdateStadiumTier(plot, tier)
	if not plot or not plot.stadiumExtrasFolder then return end
	tier = tier or 0

	-- Clear whatever was there before
	for _, child in ipairs(plot.stadiumExtrasFolder:GetChildren()) do
		child:Destroy()
	end

	if tier >= 1 then
		task.spawn(function()
			tryAddStadiumSeats(
				plot.stadiumExtrasFolder,
				plot.baseCFrame,
				plot.facingDirection,
				fanZoneConfig.ModelAssets and fanZoneConfig.ModelAssets.StadiumSeats
			)
		end)
	end

	-- Tier 2+ visual upgrades can be added here later
	-- (e.g. coloured glow strips, scoreboard animations, extra lighting)
end

function BaseService.BuildBaseMap()
	plots = {}
	assignedPlots = {}
	animatedTurnstiles = {}
	configureMapLighting()

	-- Remove the Studio-default SpawnLocation (and any leftover ones) so
	-- players don't spawn on the podium at world-origin.  We add our own
	-- SpawnLocation inside createFanZone near the south gate.
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("SpawnLocation") then
			desc:Destroy()
		end
	end

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
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(18, 24, 34),
		Size = Vector3.new(mapWidth, 4, mapLength),
		CFrame = CFrame.new(0, -2.0, 0),
	}, basesFolder)

	make("Part", {
		Name = "LobbyPlaza",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Cobblestone,
		Color = Color3.fromRGB(46, 54, 68),
		Size = Vector3.new(mapWidth - 8, 0.2, mapLength - 8),
		CFrame = CFrame.new(0, 0.1, 0),
	}, basesFolder)

	createFanZone(mapWidth, mapLength)

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

function BaseService.AssignPlot(player, rebirthTier)
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
			if plot.spawnLocation then
				player.RespawnLocation = plot.spawnLocation
			end
			BaseService.UpdateStadiumTier(plot, rebirthTier or 0)
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
	BaseService.UpdatePackMilestone(plot, 0)
	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
	if player.RespawnLocation == plot.spawnLocation then
		player.RespawnLocation = nil
	end
	assignedPlots[player] = nil
end

function BaseService.GetPlot(player)
	return assignedPlots[player]
end

function BaseService.GetDisplaySlots(plot)
	return plot and plot.displaySlots or {}
end

function BaseService.UpdatePackMilestone(plot, totalPacks)
	if not plot or not plot.milestonePacksLabel or not plot.milestoneNextLabel or not plot.milestoneBarFill then
		return
	end

	totalPacks = math.max(0, totalPacks or 0)
	local milestone = getNextPackMilestone(totalPacks)
	local prevAt    = milestone.nextAt - milestone.interval
	plot.milestonePacksLabel.Text = Utils.FormatNumber(totalPacks) .. " PACKS OPENED"
	plot.milestoneNextLabel.Text = string.format(
		"%d / %d PACKS \u{2192} %s",
		totalPacks - prevAt,
		milestone.interval,
		string.upper(milestone.reward)
	)
	plot.milestoneBarFill.Size = UDim2.fromScale(milestone.progress, 1)
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
		Range = 5,
		Brightness = 0.22,
	}, cardPart)

	createDisplayCardFace(Enum.NormalId.Front, card, incomePerSecond, cardPart)
	createDisplayCardFace(Enum.NormalId.Back, card, incomePerSecond, cardPart)

	-- Floating income label above the card
	local income = incomePerSecond or 0
	if income > 0 then
		local incomeGui = make("BillboardGui", {
			Name = "IncomeLabel",
			AlwaysOnTop = false,
			Size = UDim2.fromOffset(170, 36),
			StudsOffset = Vector3.new(0, 5.8, 0),
			MaxDistance = 28,
		}, cardPart)
		local incomeLabel = make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "+" .. Utils.FormatNumber(income) .. " fans/s",
			TextColor3 = Color3.fromRGB(255, 218, 60),
			TextScaled = false,
			TextSize = 20,
			Font = Enum.Font.GothamBlack,
			TextStrokeTransparency = 0.32,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		}, incomeGui)
		_ = incomeLabel
	end

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
		return false
	end

	local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:WaitForChild("HumanoidRootPart", 5)
	if not rootPart then
		warn("[UnboxAFootballer] Could not move player to base; HumanoidRootPart missing for " .. player.Name)
		return false
	end

	targetCharacter:PivotTo(plot.spawnCFrame)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	return true
end

return BaseService
