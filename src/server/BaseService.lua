local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")
local PhysicsService = game:GetService("PhysicsService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local CardFrames = require(ReplicatedStorage.Shared.CardFrames)
local NationFlags = require(ReplicatedStorage.Shared.NationFlags)
local Utils = require(ReplicatedStorage.Shared.Utils)

local BaseService = {}

local layout = Constants.BaseLayout
local fanZoneConfig = Constants.FanZone
local packMilestones = Constants.PackMilestones
local basesFolder
local plots = {}
local assignedPlots = {}
local animatedTurnstiles = {}
local collisionGroupsReady = false
local make

local COLLISION_GROUPS = {
	Players = "Players",
	NPCs = "NPCs",
	StadiumGeometry = "StadiumGeometry",
	Seats = "Seats",
	Props = "Props",
}

local function setupCollisionGroups()
	if collisionGroupsReady then
		return
	end

	for _, groupName in pairs(COLLISION_GROUPS) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(groupName)
		end)
		pcall(function()
			PhysicsService:CreateCollisionGroup(groupName)
		end)
	end

	local function setCollidable(a, b, collidable)
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(a, b, collidable)
		end)
	end

	setCollidable(COLLISION_GROUPS.Players, COLLISION_GROUPS.StadiumGeometry, true)
	setCollidable(COLLISION_GROUPS.Players, COLLISION_GROUPS.Seats, true)
	setCollidable(COLLISION_GROUPS.Players, COLLISION_GROUPS.Props, true)
	setCollidable(COLLISION_GROUPS.NPCs, COLLISION_GROUPS.StadiumGeometry, true)
	setCollidable(COLLISION_GROUPS.NPCs, COLLISION_GROUPS.Seats, true)
	setCollidable(COLLISION_GROUPS.NPCs, COLLISION_GROUPS.Props, true)
	setCollidable(COLLISION_GROUPS.NPCs, COLLISION_GROUPS.NPCs, false)
	setCollidable(COLLISION_GROUPS.Players, COLLISION_GROUPS.NPCs, false)

	collisionGroupsReady = true
end

local function setPartCollisionGroup(part, groupName)
	if not part or not part:IsA("BasePart") or not groupName then
		return
	end

	setupCollisionGroups()
	pcall(function()
		part.CollisionGroup = groupName
	end)
	pcall(function()
		PhysicsService:SetPartCollisionGroup(part, groupName)
	end)
end

local function assignCollisionGroup(root, groupName)
	if not root or not groupName then
		return
	end

	if root:IsA("BasePart") then
		setPartCollisionGroup(root, groupName)
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			setPartCollisionGroup(descendant, groupName)
		end
	end
end

local function configureCollisionPart(part, groupName, canCollide, canTouch, canQuery)
	if not part or not part:IsA("BasePart") then
		return part
	end

	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.CanTouch = canTouch ~= false
	part.CanQuery = canQuery ~= false
	setPartCollisionGroup(part, groupName)
	return part
end

local function createCollisionBlocker(parent, name, size, cframe, groupName)
	local blocker = make("Part", {
		Name = name or "CollisionBlocker",
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Transparency = 1,
		Material = Enum.Material.SmoothPlastic,
		Size = size,
		CFrame = cframe,
	}, parent)
	blocker:SetAttribute("CollisionBlocker", true)
	configureCollisionPart(blocker, groupName or COLLISION_GROUPS.Props, true, true, true)
	return blocker
end

local function createModelBoundsBlocker(parent, name, model, groupName, padding, minHeight, maxHeight)
	if not parent or not model then
		return nil
	end

	local boundsCFrame, boundsSize = model:GetBoundingBox()
	if boundsSize.Magnitude <= 0 then
		return nil
	end

	padding = padding or Vector3.new(1.25, 0.2, 1.25)
	local blockerHeight = math.clamp(boundsSize.Y + padding.Y, minHeight or 2.5, maxHeight or 12)
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	local blockerSize = Vector3.new(
		math.max(2, boundsSize.X + padding.X),
		blockerHeight,
		math.max(2, boundsSize.Z + padding.Z)
	)
	local blockerCFrame = boundsCFrame + Vector3.new(0, (bottomY + blockerHeight / 2) - boundsCFrame.Position.Y, 0)
	return createCollisionBlocker(parent, name, blockerSize, blockerCFrame, groupName or COLLISION_GROUPS.Props)
end

make = function(className, props, parent)
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
	Lighting.Brightness = 2.8
	Lighting.Ambient = Color3.fromRGB(130, 145, 178)
	Lighting.OutdoorAmbient = Color3.fromRGB(96, 110, 145)
	Lighting.EnvironmentDiffuseScale = 0.68
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.FogColor = Color3.fromRGB(42, 51, 68)
	Lighting.FogStart = 380
	Lighting.FogEnd = 820

	replaceLightingEffect("Atmosphere", "UnboxNightAtmosphere", {
		Density = 0.12,
		Offset = 0.04,
		Color = Color3.fromRGB(185, 204, 230),
		Decay = Color3.fromRGB(38, 46, 62),
		Glare = 0.22,
		Haze = 0.72,
	})

	replaceLightingEffect("BloomEffect", "UnboxGoldBloom", {
		Intensity = 0.038,
		Size = 10,
		Threshold = 2.8,
	})

	replaceLightingEffect("ColorCorrectionEffect", "UnboxColorGrade", {
		Brightness = 0.02,
		Contrast = 0.08,
		Saturation = 0.12,
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

local function formatFanMultiplier(multiplier)
	local rounded = math.floor((tonumber(multiplier) or 1) * 100 + 0.5) / 100
	if math.abs(rounded - math.floor(rounded)) < 0.001 then
		return tostring(math.floor(rounded)) .. "x FANS"
	end

	local text = string.format("%.2f", rounded):gsub("0+$", ""):gsub("%.$", "")
	return text .. "x FANS"
end

local function getNextPackMilestone(totalPacks)
	totalPacks = math.max(0, totalPacks or 0)

	local bestMilestone
	local nextAt = math.huge
	local bestRemaining = math.huge
	for _, milestone in ipairs(packMilestones or {}) do
		local threshold = tonumber(milestone.threshold)
		if threshold and threshold > 0 then
			local progressCount = totalPacks % threshold
			local packsRemaining = threshold - progressCount
			local candidateAt = totalPacks + packsRemaining
			if packsRemaining < bestRemaining then
				bestRemaining = packsRemaining
				nextAt = candidateAt
				bestMilestone = milestone
			elseif packsRemaining == bestRemaining and bestMilestone then
				local currentRank = milestone.threshold or 0
				local bestRank = bestMilestone.threshold or 0
				if currentRank > bestRank then
					bestMilestone = milestone
					nextAt = candidateAt
				end
			end
		end
	end

	local firstMs = packMilestones and packMilestones[1]
	bestMilestone = bestMilestone or firstMs or {}
	nextAt = nextAt < math.huge and nextAt or (bestMilestone.threshold or 50)
	local threshold = math.max(1, tonumber(bestMilestone.threshold) or 50)
	local progressCount = totalPacks % threshold
	local progress = math.clamp(progressCount / threshold, 0, 1)

	return {
		nextAt = nextAt,
		progressCount = progressCount,
		progress = progress,
		reward = bestMilestone.reward or "Rare Pack Queued",
		label = bestMilestone.label or "REWARD",
		color = bestMilestone.color or Color3.fromRGB(255, 215, 0),
		threshold = threshold,
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
	plot.padSubtitleLabel.Visible = true
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = false
end

local function updatePadHealth(plot, title, currentValue, maxValue, color)
	local ratio = maxValue > 0 and math.clamp(currentValue / maxValue, 0, 1) or 0
	plot.padTitleLabel.Text = title
	plot.padSubtitleLabel.Text = "Health: " .. tostring(math.ceil(ratio * 100)) .. "%"
	plot.padSubtitleLabel.Visible = true
	plot.padAccent.BackgroundColor3 = color
	plot.padBarBack.Visible = true
	-- Bar colour shifts green → yellow → red as health drops
	local r = math.clamp(2 * (1 - ratio), 0, 1)
	local g = math.clamp(2 * ratio, 0, 1)
	plot.padBarFill.BackgroundColor3 = Color3.new(r, g, 0)
	plot.padBarFill.Size = UDim2.new(ratio, 0, 1, 0)
end

local function createFence(parent, size, cframe)
	return configureCollisionPart(make("Part", {
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(28, 36, 50),
		Size = size,
		CFrame = cframe,
	}, parent), COLLISION_GROUPS.StadiumGeometry, true, true, true)
end

local function createStadiumTier(parent, size, cframe)
	return configureCollisionPart(make("Part", {
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(172, 28, 28),
		Size = size,
		CFrame = cframe,
	}, parent), COLLISION_GROUPS.StadiumGeometry, true, true, true)
end

local function createStadiumWedge(parent, size, cframe)
	return configureCollisionPart(make("WedgePart", {
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(136, 20, 20),
		Size = size,
		CFrame = cframe,
	}, parent), COLLISION_GROUPS.StadiumGeometry, true, true, true)
end

local function setModelVisibleAndSolid(model, visible)
	if not model then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = visible and (descendant:GetAttribute("OriginalTransparency") or 0) or 1
			descendant.CanCollide = visible
			descendant.CanTouch = visible
			descendant.CanQuery = visible
		end
	end
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

	configureCollisionPart(make("Part", {
		Name = "Base",
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 23, 34),
		Size = Vector3.new(4.2, 1.2, 4.2) * scale,
		CFrame = CFrame.new(position + Vector3.new(0, 0.6 * scale, 0)),
	}, model), COLLISION_GROUPS.Props, true, true, true)

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

	createCollisionBlocker(
		model,
		"PlanterCollisionBlocker",
		Vector3.new(4.8, 3.2, 4.8) * scale,
		CFrame.new(position + Vector3.new(0, 1.6 * scale, 0)),
		COLLISION_GROUPS.Props
	)

	return model
end

local function prepareImportedModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			setPartCollisionGroup(descendant, COLLISION_GROUPS.Props)
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
	createModelBoundsBlocker(loaded, name .. "CollisionBlocker", loaded, COLLISION_GROUPS.Props, Vector3.new(1.5, 0.4, 1.5), 4, 12)

	return loaded
end

-- extraYawDeg: optional extra Y-axis rotation applied AFTER lookAt.
-- Useful when a model's long axis is perpendicular to its pivot forward
-- direction (e.g. hedge rows, wall segments) — pass 90 to spin it along
-- the row rather than across it.
local function tryCreateImportedDecor(parent, name, assetId, position, facingPos, targetHeight, extraYawDeg)
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
	local baseCF = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z))
	if extraYawDeg and extraYawDeg ~= 0 then
		baseCF = baseCF * CFrame.Angles(0, math.rad(extraYawDeg), 0)
	end
	loaded:PivotTo(baseCF)

	local boundsCFrame, boundsSize = loaded:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
	loaded:PivotTo(loaded:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))
	createModelBoundsBlocker(loaded, name .. "CollisionBlocker", loaded, COLLISION_GROUPS.Props, Vector3.new(1.4, 0.3, 1.4), 3, 10)

	return loaded
end

local function createCompactStadiumTree(parent, name, position, facingPos)
	local model = make("Model", {
		Name = name,
	}, parent)

	local lookAt = facingPos or (position + Vector3.new(0, 0, -1))
	local baseCF = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z))
	local trunkHeight = 3.4

	configureCollisionPart(make("Part", {
		Name = "Trunk",
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(94, 56, 28),
		Size = Vector3.new(trunkHeight, 0.6, 0.6),
		CFrame = baseCF * CFrame.new(0, trunkHeight / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model), COLLISION_GROUPS.Props, false, false, false)

	local canopyLayers = {
		{ y = 3.8, size = Vector3.new(3.8, 1.7, 3.8), color = Color3.fromRGB(35, 116, 50), yaw = 12 },
		{ y = 4.75, size = Vector3.new(3.0, 1.45, 3.0), color = Color3.fromRGB(45, 138, 58), yaw = 48 },
		{ y = 5.55, size = Vector3.new(2.15, 1.15, 2.15), color = Color3.fromRGB(58, 158, 72), yaw = 22 },
	}

	for index, layer in ipairs(canopyLayers) do
		configureCollisionPart(make("Part", {
			Name = "Canopy" .. tostring(index),
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Material = Enum.Material.Grass,
			Color = layer.color,
			Size = layer.size,
			CFrame = baseCF
				* CFrame.new(0, layer.y, 0)
				* CFrame.Angles(math.rad(index % 2 == 0 and -5 or 5), math.rad(layer.yaw), math.rad(index % 2 == 0 and 3 or -3)),
		}, model), COLLISION_GROUPS.Props, false, false, false)
	end

	return model
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
		assignCollisionGroup(model, COLLISION_GROUPS.Props)
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

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	createCollisionBlocker(
		model,
		"FloodlightCollisionBlocker",
		Vector3.new(3.2, math.min(poleHeight, 12), 3.2),
		CFrame.new(position + Vector3.new(0, math.min(poleHeight, 12) / 2, 0)),
		COLLISION_GROUPS.Props
	)
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

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	createCollisionBlocker(
		model,
		"LightPostCollisionBlocker",
		Vector3.new(2.4, 7, 2.4),
		CFrame.new(position + Vector3.new(0, 3.5, 0)),
		COLLISION_GROUPS.Props
	)
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

	local bannerGold = Color3.fromRGB(255, 210, 50)
	local bannerW    = 4.8
	local bannerH    = 8.5
	local stripW     = 0.14

	-- Metal pole with gold cap
	make("Part", {
		Name = "Post",
		Anchored = true, CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(24, 30, 42),
		Size = Vector3.new(0.55, 10, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, 5, 0)),
	}, model)
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.40,
		Size = Vector3.new(0.55, 0.3, 0.55),
		CFrame = CFrame.new(position + Vector3.new(0, 10.2, 0)),
	}, model)

	local bannerCF = CFrame.lookAt(position + Vector3.new(0, 6.2, 0), lookTarget)

	-- Main banner panel
	local banner = make("Part", {
		Name = "Banner",
		Anchored = true, CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 11, 20),
		Size = Vector3.new(bannerW, bannerH, 0.35),
		CFrame = bannerCF,
	}, model)

	-- Neon gold left + right edge strips
	for _, xSign in ipairs({ -1, 1 }) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.35,
			Size = Vector3.new(stripW, bannerH + stripW * 2, 0.38),
			CFrame = bannerCF * CFrame.new(xSign * (bannerW / 2 + stripW / 2), 0, 0),
		}, model)
	end
	-- Neon gold top strip
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.35,
		Size = Vector3.new(bannerW + stripW * 2, stripW, 0.38),
		CFrame = bannerCF * CFrame.new(0, bannerH / 2 + stripW / 2, 0),
	}, model)
	-- Neon gold bottom strip
	make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = bannerGold, Transparency = 0.35,
		Size = Vector3.new(bannerW + stripW * 2, stripW, 0.38),
		CFrame = bannerCF * CFrame.new(0, -(bannerH / 2 + stripW / 2), 0),
	}, model)

	-- Subtle warm glow from banner face (dimmed — no bloom blast)
	make("PointLight", {
		Brightness = 0.35, Range = 8, Color = bannerGold,
	}, banner)

	createSurfaceText(banner, title, "")

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	createCollisionBlocker(
		model,
		"BannerCollisionBlocker",
		Vector3.new(bannerW + 0.8, bannerH + 1, 1.2),
		bannerCF,
		COLLISION_GROUPS.Props
	)
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

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	return model
end

local function createGroundAccent(parent, name, size, cframe, color, transparency, material)
	return make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Material = material or Enum.Material.SmoothPlastic,
		Color = color,
		Transparency = transparency or 0,
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createGroundChevron(parent, name, position, headingRadians, color, scale)
	scale = scale or 1
	local model = make("Model", {
		Name = name,
	}, parent)
	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, headingRadians, 0)
	local chevronColor = color or Color3.fromRGB(255, 210, 54)

	createGroundAccent(
		model,
		"Stem",
		Vector3.new(0.34 * scale, 0.045, 3.2 * scale),
		baseCFrame * CFrame.new(0, 0, -0.6 * scale),
		chevronColor,
		0.18,
		Enum.Material.Neon
	)
	createGroundAccent(
		model,
		"LeftHead",
		Vector3.new(0.32 * scale, 0.05, 2.0 * scale),
		baseCFrame * CFrame.new(-0.62 * scale, 0.01, 0.92 * scale) * CFrame.Angles(0, math.rad(35), 0),
		chevronColor,
		0.08,
		Enum.Material.Neon
	)
	createGroundAccent(
		model,
		"RightHead",
		Vector3.new(0.32 * scale, 0.05, 2.0 * scale),
		baseCFrame * CFrame.new(0.62 * scale, 0.01, 0.92 * scale) * CFrame.Angles(0, math.rad(-35), 0),
		chevronColor,
		0.08,
		Enum.Material.Neon
	)

	return model
end

local function createFloorLabel(parent, name, position, size, facingRadians, text, textColor)
	local plate = createGroundAccent(
		parent,
		name,
		Vector3.new(size.X, 0.055, size.Z),
		CFrame.new(position) * CFrame.Angles(0, facingRadians or 0, 0),
		Color3.fromRGB(7, 10, 18),
		0.15,
		Enum.Material.SmoothPlastic
	)
	local gui = make("SurfaceGui", {
		Face = Enum.NormalId.Top,
		PixelsPerStud = 60,
		LightInfluence = 0,
	}, plate)
	local label = make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = text,
		TextColor3 = textColor or Color3.fromRGB(255, 219, 72),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, gui)
	make("UITextSizeConstraint", {
		MaxTextSize = 54,
		MinTextSize = 10,
	}, label)
	return plate
end

local function createStandingTable(parent, name, position, accentColor)
	local model = make("Model", {
		Name = name,
	}, parent)
	local tableColor = Color3.fromRGB(18, 24, 38)
	local goldColor = accentColor or Color3.fromRGB(255, 210, 52)

	local cframe = CFrame.new(position)
	make("Part", {
		Name = "Top",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = tableColor,
		Size = Vector3.new(0.32, 4.4, 4.4),
		CFrame = cframe * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)
	make("Part", {
		Name = "GoldRim",
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = goldColor,
		Transparency = 0.28,
		Size = Vector3.new(0.12, 4.65, 4.65),
		CFrame = cframe * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)
	make("Part", {
		Name = "Post",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(28, 32, 42),
		Size = Vector3.new(0.48, 2.1, 0.48),
		CFrame = cframe * CFrame.new(0, 1.1, 0),
	}, model)
	make("Part", {
		Name = "Base",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(28, 32, 42),
		Size = Vector3.new(0.18, 2.6, 2.6),
		CFrame = cframe * CFrame.new(0, 0.14, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)

	for index = 1, 3 do
		local angle = math.rad((index - 1) * 120)
		local stoolPos = Vector3.new(math.cos(angle) * 3.2, 0, math.sin(angle) * 3.2)
		make("Part", {
			Name = "Stool" .. index,
			Anchored = true,
			CanCollide = true,
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.SmoothPlastic,
			Color = goldColor,
			Size = Vector3.new(0.26, 1.8, 1.8),
			CFrame = cframe * CFrame.new(stoolPos + Vector3.new(0, 0.72, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		}, model)
	end

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	createCollisionBlocker(
		model,
		"StandingTableCollisionBlocker",
		Vector3.new(7.2, 2.8, 7.2),
		cframe * CFrame.new(0, 1.4, 0),
		COLLISION_GROUPS.Props
	)
	return model
end

local function createTrashBin(parent, name, position, accentColor)
	local model = make("Model", {
		Name = name,
	}, parent)
	local cframe = CFrame.new(position)
	local binColor = Color3.fromRGB(13, 18, 28)
	local trimColor = accentColor or Color3.fromRGB(80, 190, 96)

	make("Part", {
		Name = "Body",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = binColor,
		Size = Vector3.new(2.4, 2.1, 2.1),
		CFrame = cframe * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)
	make("Part", {
		Name = "Trim",
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = trimColor,
		Transparency = 0.2,
		Size = Vector3.new(0.12, 2.24, 2.24),
		CFrame = cframe * CFrame.new(0, 2.28, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)
	make("Part", {
		Name = "Slot",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(220, 225, 232),
		Size = Vector3.new(1.25, 0.16, 0.18),
		CFrame = cframe * CFrame.new(0, 2.72, -0.95),
	}, model)

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	createCollisionBlocker(
		model,
		"TrashBinCollisionBlocker",
		Vector3.new(2.5, 2.8, 2.5),
		cframe * CFrame.new(0, 1.4, 0),
		COLLISION_GROUPS.Props
	)
	return model
end

local function createPennantString(parent, name, z, colorA, colorB)
	local model = make("Model", {
		Name = name,
	}, parent)
	local postColor = Color3.fromRGB(20, 25, 36)
	local leftX, rightX = -30, 30
	local postHeight = 7.2

	for _, x in ipairs({ leftX, rightX }) do
		make("Part", {
			Name = "Post",
			Anchored = true,
			CanCollide = true,
			Material = Enum.Material.Metal,
			Color = postColor,
			Size = Vector3.new(0.42, postHeight, 0.42),
			CFrame = CFrame.new(x, postHeight / 2, z),
		}, model)
	end
	make("Part", {
		Name = "Cable",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(48, 52, 64),
		Size = Vector3.new((rightX - leftX), 0.08, 0.08),
		CFrame = CFrame.new(0, postHeight, z),
	}, model)

	for index = 1, 11 do
		local t = index / 12
		local x = leftX + ((rightX - leftX) * t)
		make("Part", {
			Name = "Pennant" .. index,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = (index % 2 == 0) and (colorB or Color3.fromRGB(225, 40, 40)) or (colorA or Color3.fromRGB(255, 214, 54)),
			Size = Vector3.new(1.4, 1.05, 0.08),
			CFrame = CFrame.new(x, postHeight - 0.55, z),
		}, model)
	end

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	for _, x in ipairs({ leftX, rightX }) do
		createCollisionBlocker(
			model,
			"PennantPostCollisionBlocker",
			Vector3.new(1.4, postHeight, 1.4),
			CFrame.new(x, postHeight / 2, z),
			COLLISION_GROUPS.Props
		)
	end
	return model
end

local function createLowQueueRail(parent, name, position, length, alongX, accentColor)
	local model = make("Model", {
		Name = name,
	}, parent)
	local railColor = accentColor or Color3.fromRGB(255, 210, 54)
	local railSize = alongX and Vector3.new(length, 0.18, 0.18) or Vector3.new(0.18, 0.18, length)
	local railCFrame = CFrame.new(position + Vector3.new(0, 1.35, 0))

	make("Part", {
		Name = "Rail",
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Material = Enum.Material.Metal,
		Color = railColor,
		Size = railSize,
		CFrame = railCFrame,
	}, model)

	local halfLength = length / 2
	for _, offset in ipairs({ -halfLength, 0, halfLength }) do
		local postOffset = alongX and Vector3.new(offset, 0, 0) or Vector3.new(0, 0, offset)
		make("Part", {
			Name = "Post",
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(18, 23, 34),
			Size = Vector3.new(0.28, 1.35, 0.28),
			CFrame = CFrame.new(position + postOffset + Vector3.new(0, 0.68, 0)),
		}, model)
	end

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	return model
end

local function createFanZoneBoard(parent, name, position, facingPos, title, subtitle)
	local board = make("Part", {
		Name = name,
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(16, 3.2, 0.45),
		CFrame = CFrame.lookAt(position, Vector3.new(facingPos.X, position.Y, facingPos.Z)),
	}, parent)
	configureCollisionPart(board, COLLISION_GROUPS.Props, true, true, true)
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
	local gate = make("Model", { Name = name }, parent)

	local center        = Vector3.new(0, 0, z)
	local columnColor   = Color3.fromRGB(14, 18, 28)    -- near-black pillar base
	local neonGold      = Color3.fromRGB(255, 210, 0)
	local lookDirection = Vector3.new(0, 0, facingDirection)

	-- Columns + neon trim + orb caps
	for _, side in ipairs({ -17, 17 }) do
		local label = side < 0 and "Left" or "Right"

		-- Main column
		make("Part", {
			Name = label .. "Column",
			Anchored = true, CanCollide = true,
			Material = Enum.Material.SmoothPlastic,
			Color = columnColor,
			Size = Vector3.new(4, 13, 4),
			CFrame = CFrame.new(center + Vector3.new(side, 6.5, 0)),
		}, gate)

		-- Neon strip — front face of column
		make("Part", {
			Name = label .. "NeonFront",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = neonGold,
			Size = Vector3.new(0.22, 13.4, 0.22),
			CFrame = CFrame.new(center + Vector3.new(side, 6.5, -2.12)),
		}, gate)

		-- Neon strip — back face of column
		make("Part", {
			Name = label .. "NeonBack",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = neonGold,
			Size = Vector3.new(0.22, 13.4, 0.22),
			CFrame = CFrame.new(center + Vector3.new(side, 6.5, 2.12)),
		}, gate)

		-- Glowing orb at top of each column
		make("Part", {
			Name = label .. "ColumnOrb",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = neonGold,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = CFrame.new(center + Vector3.new(side, 14.2, 0)),
		}, gate)
	end

	-- Top beam
	make("Part", {
		Name = "TopBeam",
		Anchored = true, CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = columnColor,
		Size = Vector3.new(40, 3, 4),
		CFrame = CFrame.new(center + Vector3.new(0, 11.5, 0)),
	}, gate)

	-- LED strip along the bottom-front edge of the beam
	make("Part", {
		Name = "BeamLED",
		Anchored = true, CanCollide = false,
		Material = Enum.Material.Neon,
		Color = neonGold,
		Size = Vector3.new(40.4, 0.20, 0.20),
		CFrame = CFrame.new(center + Vector3.new(0, 10.05, -2.12)),
	}, gate)

	-- 7 small orb lights spaced across the top of the beam
	for i = 1, 7 do
		local bx = -24 + (i - 1) * 8
		make("Part", {
			Name = "BeamOrb" .. i,
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = neonGold,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.1, 1.1, 1.1),
			CFrame = CFrame.new(center + Vector3.new(bx, 13.6, 0)),
		}, gate)
	end

	-- Logo sign — taller than before (9 studs) so 3 stacked lines breathe properly
	local sign = make("Part", {
		Name = "LogoSign",
		Anchored = true, CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(6, 8, 14),
		Size = Vector3.new(30, 9, 0.5),
		CFrame = CFrame.lookAt(
			center + Vector3.new(0, 17.5, -facingDirection * 0.3),
			center + Vector3.new(0, 17.5, -facingDirection * 0.3) + lookDirection
		),
	}, gate)

	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = make("SurfaceGui", {
			Face = face,
			PixelsPerStud = 50,
			LightInfluence = 0,
		}, sign)

		local frame = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(6, 8, 14),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, gui)
		make("UICorner", { CornerRadius = UDim.new(0, 14) }, frame)
		make("UIStroke", { Color = neonGold, Thickness = 5 }, frame)

		-- Gold bar top
		make("Frame", {
			BackgroundColor3 = neonGold,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 9),
		}, frame)

		-- Gold bar bottom
		make("Frame", {
			BackgroundColor3 = neonGold,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 9),
			Position = UDim2.new(0, 0, 1, -9),
		}, frame)

		-- "PACK" — white, top third, matching logo style
		local packLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.88, 0.34),
			Position = UDim2.fromScale(0.06, 0.06),
			Text = "PACK",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, frame)
		make("UITextSizeConstraint", { MaxTextSize = 130, MinTextSize = 24 }, packLabel)
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 3, Transparency = 0.25 }, packLabel)

		-- "THAT" — gold, middle, slightly smaller
		local thatLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.72, 0.26),
			Position = UDim2.fromScale(0.14, 0.37),
			Text = "THAT",
			TextColor3 = neonGold,
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, frame)
		make("UITextSizeConstraint", { MaxTextSize = 100, MinTextSize = 18 }, thatLabel)
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.25 }, thatLabel)

		-- "PLAYER" — white, bottom third
		local playerLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.88, 0.34),
			Position = UDim2.fromScale(0.06, 0.60),
			Text = "PLAYER",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, frame)
		make("UITextSizeConstraint", { MaxTextSize = 130, MinTextSize = 24 }, playerLabel)
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 3, Transparency = 0.25 }, playerLabel)
	end

	-- Turnstiles (unchanged)
	for index = 1, 3 do
		local x = -8 + ((index - 1) * 8)
		createTurnstile(gate, CFrame.new(center + Vector3.new(x, 2.1, -facingDirection * 2)))
	end

	assignCollisionGroup(gate, COLLISION_GROUPS.StadiumGeometry)
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
			descendant.CanTouch = true
			descendant.CanQuery = true
			setPartCollisionGroup(descendant, COLLISION_GROUPS.Props)
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
	createModelBoundsBlocker(model, name .. "CollisionBlocker", model, COLLISION_GROUPS.Props, Vector3.new(1.4, 0.3, 1.4), 3, 9)

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

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
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

	assignCollisionGroup(model, COLLISION_GROUPS.Props)
	createCollisionBlocker(
		model,
		"KioskCollisionBlocker",
		Vector3.new(8.4, 5.2, 4.8),
		boothCF * CFrame.new(0, 0.6, 0.35),
		COLLISION_GROUPS.Props
	)
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

	local dashIndex = 0
	for z = southZ + 26, northZ - 26, 18 do
		if math.abs(z) > 31 then
			dashIndex += 1
			createGroundAccent(
				plaza,
				"MainWalkwayDash" .. dashIndex,
				Vector3.new(0.42, 0.05, 7.4),
				CFrame.new(0, 0.43, z),
				Color3.fromRGB(255, 210, 54),
				0.38,
				Enum.Material.Neon
			)
		end
	end

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
			Transparency = 0.78,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.08),
			CFrame = CFrame.new(0, 0.4, laneZ - 6.8),
		}, plaza)
		make("Part", {
			Name = "StadiumPathGuideB" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(210, 168, 52),
			Transparency = 0.78,
			Size = Vector3.new((layout.SideOffset * 2) - 28, 0.07, 0.08),
			CFrame = CFrame.new(0, 0.4, laneZ + 6.8),
		}, plaza)
		for _, marker in ipairs({
			{ x = -62, angle = -math.pi / 2, label = "WestFar" },
			{ x = -43, angle = -math.pi / 2, label = "WestNear" },
			{ x = 43, angle = math.pi / 2, label = "EastNear" },
			{ x = 62, angle = math.pi / 2, label = "EastFar" },
		}) do
			createGroundChevron(
				plaza,
				"StadiumPathChevron" .. laneIndex .. marker.label,
				Vector3.new(marker.x, 0.48, laneZ),
				marker.angle,
				Color3.fromRGB(255, 210, 54),
				1.05
			)
		end
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
				Range = 48,
				Brightness = 0.72,
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
				Range = 36,
				Brightness = 0.55,
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

	createGroundAccent(
		plaza,
		"FanZoneDeckWestCarpet",
		Vector3.new(9.2, 0.055, 36),
		CFrame.new(-12.5, 0.59, 0),
		Color3.fromRGB(96, 25, 38),
		0.1,
		Enum.Material.SmoothPlastic
	)
	createGroundAccent(
		plaza,
		"FanZoneDeckEastCarpet",
		Vector3.new(9.2, 0.055, 36),
		CFrame.new(12.5, 0.59, 0),
		Color3.fromRGB(19, 58, 96),
		0.1,
		Enum.Material.SmoothPlastic
	)
	for _, z in ipairs({ -19, 19 }) do
		createFloorLabel(
			plaza,
			"FoodCourtFloorLabel" .. tostring(z),
			Vector3.new(0, 0.61, z),
			Vector3.new(15, 0, 3.4),
			0,
			"FAN ZONE",
			Color3.fromRGB(255, 224, 86)
		)
	end
	createPennantString(plaza, "SouthWalkwayPennants", -56, Color3.fromRGB(255, 214, 58), Color3.fromRGB(218, 38, 48))
	createPennantString(plaza, "NorthWalkwayPennants", 56, Color3.fromRGB(72, 185, 245), Color3.fromRGB(255, 214, 58))

	-- ── Centre podium: three stepped tiers with neon rims + dramatic lighting ───
	-- Cylinders have length along X so we rotate 90° on Z to stand them upright.
	local PODIUM_GOLD  = Color3.fromRGB(220, 170, 28)   -- deep warm gold for rims
	local PODIUM_RED   = Color3.fromRGB(220, 40,  20)   -- red glow at base (concept art)

	-- Tier 1 — wide base (bottom at Y=0, top at Y=3.2)
	make("Part", {
		Name = "PedestalTier1",
		Anchored = true, CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 14, 24),
		Size = Vector3.new(3.2, 24, 24),
		CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Gold neon rim ring at top edge of Tier 1 — semi-transparent so it glows, not blinds
	make("Part", {
		Name = "PedestalTier1Rim",
		Anchored = true, CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = PODIUM_GOLD,
		Transparency = 0.88,
		Size = Vector3.new(0.18, 24.6, 24.6),
		CFrame = CFrame.new(0, 3.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Red glow ring at the very base
	make("Part", {
		Name = "PedestalBaseGlow",
		Anchored = true, CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = PODIUM_RED,
		Transparency = 0.82,
		Size = Vector3.new(0.10, 28, 28),
		CFrame = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)

	-- Tier 2 — mid (bottom ≈ Y=3.3, top ≈ Y=5.9)
	make("Part", {
		Name = "PedestalTier2",
		Anchored = true, CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(14, 19, 32),
		Size = Vector3.new(2.6, 16, 16),
		CFrame = CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Gold neon rim ring at top edge of Tier 2
	make("Part", {
		Name = "PedestalTier2Rim",
		Anchored = true, CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = PODIUM_GOLD,
		Transparency = 0.88,
		Size = Vector3.new(0.16, 16.6, 16.6),
		CFrame = CFrame.new(0, 5.85, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)

	-- Tier 3 — top plinth (bottom ≈ Y=6.1, top ≈ Y=8.4)
	make("Part", {
		Name = "PedestalTier3",
		Anchored = true, CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 24, 40),
		Size = Vector3.new(2.3, 10, 10),
		CFrame = CFrame.new(0, 7.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)
	-- Gold neon rim ring at top edge of Tier 3
	make("Part", {
		Name = "PedestalTier3Rim",
		Anchored = true, CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = PODIUM_GOLD,
		Transparency = 0.88,
		Size = Vector3.new(0.14, 10.6, 10.6),
		CFrame = CFrame.new(0, 8.42, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, plaza)

	-- Subtle red uplight at the base — toned down so it accents rather than floods
	local redGlow = make("Part", {
		Name = "PedestalRedLightSource",
		Anchored = true, CanCollide = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(0, 0.5, 0),
	}, plaza)
	make("PointLight", {
		Color = PODIUM_RED,
		Range = 20,
		Brightness = 0.5,
		Shadows = false,
	}, redGlow)

	-- Very subtle gold light from the top plinth — just enough to light the ball
	local goldGlow = make("Part", {
		Name = "PedestalGoldLightSource",
		Anchored = true, CanCollide = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(0, 8.5, 0),
	}, plaza)
	make("PointLight", {
		Color = PODIUM_GOLD,
		Range = 14,
		Brightness = 0.28,
		Shadows = false,
	}, goldGlow)

	createCollisionBlocker(
		plaza,
		"TrophyPodiumCollisionBlocker",
		Vector3.new(32, 9, 32),
		CFrame.new(0, 4.5, 0),
		COLLISION_GROUPS.Props
	)

	-- ── Ring of alternating accent pillars + planters around the podium ──────
	-- Even indices: gold neon accent pillars with uplight cones
	-- Odd indices: planters (unchanged)
	local RING_RADIUS = 17
	local RING_COUNT  = 6
	for ringIndex = 1, RING_COUNT do
		local angle = math.rad((ringIndex - 1) * (360 / RING_COUNT))
		local rx = math.cos(angle) * RING_RADIUS
		local rz = math.sin(angle) * RING_RADIUS
		if ringIndex % 2 == 0 then
			-- Gold neon accent pillar
			make("Part", {
				Name = "RingPillar" .. ringIndex,
				Anchored = true, CanCollide = false,
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(12, 16, 26),
				Size = Vector3.new(1.2, 5, 1.2),
				CFrame = CFrame.new(rx, 2.5, rz),
			}, plaza)
			-- Neon cap
			make("Part", {
				Name = "RingPillarCap" .. ringIndex,
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon,
				Color = PODIUM_GOLD,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.4, 1.4, 1.4),
				CFrame = CFrame.new(rx, 5.7, rz),
			}, plaza)
			-- Uplight cone (thin neon cylinder pointing up)
			make("Part", {
				Name = "RingPillarUplight" .. ringIndex,
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon,
				Color = PODIUM_GOLD,
				Transparency = 0.88,
				Size = Vector3.new(0.5, 0.5, 0.5),
				CFrame = CFrame.new(rx, 0.3, rz),
			}, plaza)
			-- PointLight at pillar cap
			local pillarLight = make("Part", {
				Name = "RingPillarLight" .. ringIndex,
				Anchored = true, CanCollide = false,
				Transparency = 1,
				Size = Vector3.new(0.5, 0.5, 0.5),
				CFrame = CFrame.new(rx, 5.7, rz),
			}, plaza)
			make("PointLight", {
				Color = PODIUM_GOLD,
				Range = 12,
				Brightness = 0.55,
				Shadows = false,
			}, pillarLight)
		else
			createPlanter(plaza, Vector3.new(rx, 0, rz), 0.52)
		end
	end

	-- Try custom soccer ball first, then the statue model, then plain gold sphere
	local statue = tryCreateImportedDecor(plaza, "SoccerBall", modelAssets.SoccerBall, Vector3.new(0, 8.45, 0), Vector3.new(0, 8.45, -12), 5.0)
		or tryCreateImportedDecor(plaza, "FootballStatue", modelAssets.FootballStatue, Vector3.new(0, 8.45, 0), Vector3.new(0, 8.45, -12), 12.0)
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

	createLowQueueRail(plaza, "PopcornQueueRail", Vector3.new(-28, 0, -10), 10, false, Color3.fromRGB(248, 203, 42))
	createLowQueueRail(plaza, "HotDogQueueRail", Vector3.new(28, 0, -10), 10, false, Color3.fromRGB(232, 48, 24))
	createLowQueueRail(plaza, "BurgerQueueRail", Vector3.new(-28, 0, 10), 10, false, Color3.fromRGB(240, 155, 30))
	createLowQueueRail(plaza, "DrinkQueueRail", Vector3.new(28, 0, 10), 10, false, Color3.fromRGB(60, 200, 228))

	createFanZoneBench(plaza, "BenchSouthWest", Vector3.new(-15, 0.35, -25), center0)
	createFanZoneBench(plaza, "BenchSouthEast", Vector3.new(15, 0.35, -25), center0)
	createFanZoneBench(plaza, "BenchNorthWest", Vector3.new(-15, 0.35, 25), center0)
	createFanZoneBench(plaza, "BenchNorthEast", Vector3.new(15, 0.35, 25), center0)

	createStandingTable(plaza, "TableSouthWest", Vector3.new(-42, 0, -58), Color3.fromRGB(255, 210, 54))
	createStandingTable(plaza, "TableSouthEast", Vector3.new(42, 0, -58), Color3.fromRGB(72, 185, 245))
	createStandingTable(plaza, "TableNorthWest", Vector3.new(-42, 0, 58), Color3.fromRGB(218, 38, 48))
	createStandingTable(plaza, "TableNorthEast", Vector3.new(42, 0, 58), Color3.fromRGB(255, 210, 54))
	createStandingTable(plaza, "GateTableSouthWest", Vector3.new(-36, 0, southZ + 48), Color3.fromRGB(72, 185, 245))
	createStandingTable(plaza, "GateTableSouthEast", Vector3.new(36, 0, southZ + 48), Color3.fromRGB(218, 38, 48))
	createStandingTable(plaza, "GateTableNorthWest", Vector3.new(-36, 0, northZ - 48), Color3.fromRGB(255, 210, 54))
	createStandingTable(plaza, "GateTableNorthEast", Vector3.new(36, 0, northZ - 48), Color3.fromRGB(72, 185, 245))

	for index, binPosition in ipairs({
		Vector3.new(-25, 0, -82),
		Vector3.new(25, 0, -82),
		Vector3.new(-25, 0, 82),
		Vector3.new(25, 0, 82),
		Vector3.new(-23, 0, southZ + 30),
		Vector3.new(23, 0, southZ + 30),
		Vector3.new(-23, 0, northZ - 30),
		Vector3.new(23, 0, northZ - 30),
	}) do
		createTrashBin(
			plaza,
			"ConcourseTrashBin" .. index,
			binPosition,
			(index % 2 == 0) and Color3.fromRGB(72, 185, 245) or Color3.fromRGB(80, 190, 96)
		)
	end

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

	-- ── Plaza greenery & border ───────────────────────────────────────────────
	-- Hedge rows line the north/south edges of the central deck.
	-- Bush clusters anchor all four corners.
	-- Low stone walls cap the west/east outer edges of the deck.
	-- Soft green ambient lights wash the greenery so it reads at night.
	do
		local hedgeAsset = modelAssets.Hedge
		local bushAsset  = modelAssets.Bush
		local wallAsset  = modelAssets.StoneWall

		-- ── Hedge rows — built from solid Parts so there are zero gaps and
		-- no model-pivot rotation fights.  Two layers each side:
		--   1. Low stone kerb  (grey SmoothPlastic, slightly wider)
		--   2. Green hedge body on top
		-- Stone walls removed — they sat on the stadium-access paths and
		-- blocked players from reaching their plots.

		-- Hedge rows sit at z=±31, clear of the benches at z=±25.
		-- No neon strip, no PointLights — the surrounding plaza lights
		-- are enough to read them; we don't want them glowing.
		local HEDGE_GREEN = Color3.fromRGB(22, 80, 32)   -- dark natural green
		local KERB_GREY   = Color3.fromRGB(68, 72, 80)

		for _, side in ipairs({ -1, 1 }) do  -- -1 = north, 1 = south
			local rowZ = side * 31
			local label = side == -1 and "North" or "South"

			-- Low stone kerb
			make("Part", {
				Name = "HedgeKerb" .. label,
				Anchored = true, CanCollide = true,
				Material = Enum.Material.SmoothPlastic,
				Color = KERB_GREY,
				Size = Vector3.new(52, 0.4, 3.8),
				CFrame = CFrame.new(0, 0.2, rowZ),
			}, plaza)

			-- Hedge body — solid dark green, no glow
			make("Part", {
				Name = "HedgeRow" .. label,
				Anchored = true, CanCollide = true,
				Material = Enum.Material.SmoothPlastic,
				Color = HEDGE_GREEN,
				Size = Vector3.new(50, 2.6, 3.2),
				CFrame = CFrame.new(0, 1.5, rowZ),
			}, plaza)
		end

		-- Bush corner accents — pushed out to match the new hedge position
		for _, bp in ipairs({
			Vector3.new(-26, 0, -29),
			Vector3.new( 26, 0, -29),
			Vector3.new(-26, 0,  29),
			Vector3.new( 26, 0,  29),
		}) do
			tryCreateImportedDecor(
				plaza, "BushCorner" .. bp.X .. "_" .. bp.Z,
				bushAsset,
				bp,
				Vector3.new(0, 0, 0),
				1.2
			)
		end
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
	createWaypoint(waypointFolder, "WestLoop", Vector3.new(-24, 3.1, 0))
	createWaypoint(waypointFolder, "EastLoop", Vector3.new(24, 3.1, 0))
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

-- ── Card design feature flag ──────────────────────────────────────────────
-- Set to false to instantly revert to the original card layouts.
local USE_NEW_CARD_DESIGN = true
-- Set to false to keep the new code-built layout while disabling uploaded PNG frames.
local USE_CARD_FRAME_ASSETS = true

local CARD_FRAME_ASSETS = CardFrames.Assets
local CARD_FRAME_ACCENTS = CardFrames.Accents

local function addCenterFlag(nation, parent, zIndex)
	local flagId = NationFlags[nation]
	if not flagId then return end
	make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = flagId,
		ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromScale(0.5, 0.375),
		Size = UDim2.fromScale(0.58, 0.22),
		ZIndex = zIndex or 3,
	}, parent)
end

local DISPLAY_CARD_TREATMENTS = {
	["Gold"] = {
		tag = "",
		tier = 0,
		edge = 4,
		patternCount = 5,
		portraitScale = 1,
		template = USE_NEW_CARD_DESIGN and "v2_gold"         or "classic",
	},
	["Rare Gold"] = {
		tag = "RARE",
		tier = 1,
		edge = 5,
		patternCount = 7,
		portraitScale = 1.04,
		template = USE_NEW_CARD_DESIGN and "v2_raregold"     or "diagonal",
	},
	["Premium Gold"] = {
		tag = "PREMIUM",
		tier = 2,
		edge = 6,
		patternCount = 9,
		portraitScale = 1.08,
		template = USE_NEW_CARD_DESIGN and "v2_premium"      or "premium",
	},
	["Talisman"] = {
		tag = "SPECIAL",
		tier = 3,
		edge = 7,
		patternCount = 11,
		portraitScale = 1.12,
		template = USE_NEW_CARD_DESIGN and "v2_talisman"     or "shard",
	},
	["Maestro"] = {
		tag = "ELITE",
		tier = 4,
		edge = 8,
		patternCount = 13,
		portraitScale = 1.16,
		template = USE_NEW_CARD_DESIGN and "v2_maestro"      or "orbit",
	},
	["Immortal"] = {
		tag = "LEGEND",
		tier = 5,
		edge = 9,
		patternCount = 15,
		portraitScale = 1.20,
		template = USE_NEW_CARD_DESIGN and "v2_immortal"     or "prism",
	},
	["Player of the Year"] = {
		tag = "BEST",
		displayLabel = "PLAYER OF THE YEAR",
		tier = 6,
		edge = 10,
		patternCount = 0,
		portraitScale = 1.22,
		template = USE_NEW_CARD_DESIGN and "v2_poty"         or "trophy",
	},
}

local function getDisplayCardTreatment(rarity)
	return DISPLAY_CARD_TREATMENTS[rarity] or DISPLAY_CARD_TREATMENTS["Gold"]
end

local POSITION_ACCENTS = {
	GK = Color3.fromRGB(78, 221, 125),
	CB = Color3.fromRGB(73, 167, 255),
	LB = Color3.fromRGB(73, 167, 255),
	RB = Color3.fromRGB(73, 167, 255),
	CDM = Color3.fromRGB(110, 222, 205),
	CM = Color3.fromRGB(170, 116, 255),
	CAM = Color3.fromRGB(207, 128, 255),
	LM = Color3.fromRGB(186, 114, 255),
	RM = Color3.fromRGB(186, 114, 255),
	LW = Color3.fromRGB(255, 116, 84),
	RW = Color3.fromRGB(255, 116, 84),
	ST = Color3.fromRGB(255, 82, 68),
	CF = Color3.fromRGB(255, 104, 64),
}

local function getCardInitials(name)
	local initials = ""
	for word in string.gmatch(name or "Player", "%w+") do
		initials = initials .. string.sub(word, 1, 1)
		if string.len(initials) >= 2 then
			break
		end
	end

	if initials == "" then
		initials = "P"
	end
	return string.upper(initials)
end

local function getPositionAccent(position, fallback)
	return POSITION_ACCENTS[string.upper(position or "")] or fallback
end

local function addDisplayCardTemplate(frame, treatment, tier, rarityColor, secondaryColor, darkColor, trimColor, textColor)
	local template = treatment.template or "classic"

	-- ════════════════════════════════════════════════════════════════════════
	-- V2 TEMPLATES  (USE_NEW_CARD_DESIGN = true)
	-- Each rarity has a visually distinct background treatment so cards are
	-- instantly recognisable at slot-distance without reading the label.
	-- ════════════════════════════════════════════════════════════════════════

	if template == "v2_gold" then
		-- Clean starter card: two slim gold dividers + small corner diamonds
		for _, y in ipairs({0.27, 0.70}) do
			make("Frame", {
				BackgroundColor3 = trimColor, BackgroundTransparency = 0.52,
				BorderSizePixel = 0, Position = UDim2.fromScale(0.08, y),
				Size = UDim2.new(0.84, 0, 0, 2), ZIndex = 2,
			}, frame)
		end
		for _, pos in ipairs({ UDim2.fromScale(0.08, 0.038), UDim2.fromScale(0.86, 0.038) }) do
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = trimColor,
				BackgroundTransparency = 0.28, BorderSizePixel = 0,
				Position = pos, Rotation = 45, Size = UDim2.fromScale(0.055, 0.030), ZIndex = 2,
			}, frame)
		end
		return
	end

	if template == "v2_raregold" then
		-- Orange-red bold right accent stripe makes it clearly hotter than Gold
		local stripe = make("Frame", {
			AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = secondaryColor,
			BackgroundTransparency = 0.12, BorderSizePixel = 0,
			Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.20, 1), ZIndex = 1,
		}, frame)
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, secondaryColor),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.72),
				NumberSequenceKeypoint.new(1, 0.05),
			}),
		}, stripe)
		for _, y in ipairs({0.27, 0.70}) do
			make("Frame", {
				BackgroundColor3 = trimColor, BackgroundTransparency = 0.42,
				BorderSizePixel = 0, Position = UDim2.fromScale(0.07, y),
				Size = UDim2.new(0.70, 0, 0, 2), ZIndex = 2,
			}, frame)
		end
		return
	end

	if template == "v2_premium" then
		-- Near-black inner plate + precise L-bracket corners = premium credit-card feel
		local plate = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(3, 4, 7),
			BackgroundTransparency = 0.05, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.82, 0.70), ZIndex = 1,
		}, frame)
		local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0.05, 0); pc.Parent = plate
		make("UIStroke", { Color = trimColor, Thickness = 1.6, Transparency = 0.20 }, plate)
		-- L-bracket corners (h-bar + v-bar each)
		for _, s in ipairs({
			{x=0.07, y=0.11}, {x=0.86, y=0.11},
			{x=0.07, y=0.83}, {x=0.86, y=0.83},
		}) do
			make("Frame", { -- horizontal
				BackgroundColor3 = trimColor, BackgroundTransparency = 0.08,
				BorderSizePixel = 0, Position = UDim2.fromScale(s.x, s.y),
				Size = UDim2.fromScale(0.07, 0.013), ZIndex = 3,
			}, frame)
			make("Frame", { -- vertical
				BackgroundColor3 = trimColor, BackgroundTransparency = 0.08,
				BorderSizePixel = 0, Position = UDim2.fromScale(s.x, s.y),
				Size = UDim2.fromScale(0.013, 0.055), ZIndex = 3,
			}, frame)
		end
		return
	end

	if template == "v2_talisman" then
		-- Bold red colour-block in the top ~28% with a sharp diagonal cut
		local topBlock = make("Frame", {
			BackgroundColor3 = rarityColor, BackgroundTransparency = 0.06,
			BorderSizePixel = 0, Position = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(1, 0.28), ZIndex = 1,
		}, frame)
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, rarityColor),
				ColorSequenceKeypoint.new(1, secondaryColor),
			}),
			Rotation = 130,
		}, topBlock)
		-- Sharp diagonal slash at the bottom of the red block
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = rarityColor,
			BackgroundTransparency = 0.18, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.265), Rotation = -3.5,
			Size = UDim2.new(1.1, 0, 0, 5), ZIndex = 2,
		}, frame)
		-- Two small gold diamond accents inside the red block
		for _, x in ipairs({0.10, 0.88}) do
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = trimColor,
				BackgroundTransparency = 0.08, BorderSizePixel = 0,
				Position = UDim2.fromScale(x, 0.14), Rotation = 45,
				Size = UDim2.fromScale(0.042, 0.024), ZIndex = 3,
			}, frame)
		end
		return
	end

	if template == "v2_maestro" then
		-- Wide diagonal gold beam + three thin accent lines = elegant elite card
		make("Frame", { -- fat beam
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.52, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.50), Rotation = -26,
			Size = UDim2.new(1.9, 0, 0, 38), ZIndex = 1,
		}, frame)
		make("Frame", { -- bright core
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.68, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.50), Rotation = -26,
			Size = UDim2.new(1.9, 0, 0, 7), ZIndex = 1,
		}, frame)
		for i = 1, 3 do
			make("Frame", { -- accent lines
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = rarityColor,
				BackgroundTransparency = 0.65, BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.28 + i * 0.15), Rotation = -26,
				Size = UDim2.new(1.7, 0, 0, 2), ZIndex = 1,
			}, frame)
		end
		return
	end

	if template == "v2_immortal" then
		-- Bright ice treatment: light card stands out among all dark ones.
		-- Five vertical shimmer columns + one bold horizontal shimmer bar.
		for i = 1, 5 do
			make("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.65,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.08 + (i - 1) * 0.20, 0),
				Size = UDim2.fromScale(0.07, 1), ZIndex = 1,
			}, frame)
		end
		make("Frame", { -- horizontal shimmer
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.48,
			BorderSizePixel = 0, Position = UDim2.fromScale(0, 0.205),
			Size = UDim2.new(1, 0, 0, 6), ZIndex = 2,
		}, frame)
		-- Central glow circle behind identity zone
		local glow = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.46, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.50), Size = UDim2.fromScale(0.62, 0.50), ZIndex = 1,
		}, frame)
		local gc = Instance.new("UICorner"); gc.CornerRadius = UDim.new(1, 0); gc.Parent = glow
		return
	end

	if template == "v2_poty" then
		-- Jet-black luxury. Five stars across the top. Crown. Gold side bars.
		-- Five stars (two rotated squares each = 8-point star visual)
		for i = 1, 5 do
			local starSize  = i == 3 and 0.082 or 0.062
			local starAlpha = i == 3 and 0.02  or 0.16
			local sx = 0.17 + (i - 1) * 0.165
			local star = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = trimColor,
				BackgroundTransparency = starAlpha, BorderSizePixel = 0,
				Position = UDim2.fromScale(sx, 0.055), Rotation = 0,
				Size = UDim2.fromScale(starSize, starSize * 1.55), ZIndex = 3,
			}, frame)
			make("Frame", { -- rotated 45° overlay = 8-point
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = trimColor,
				BackgroundTransparency = starAlpha, BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5), Rotation = 45,
				Size = UDim2.fromScale(1, 1), ZIndex = 3,
			}, star)
		end
		-- Gold luxury bars on left and right edges
		for _, x in ipairs({0.035, 0.945}) do
			make("Frame", {
				BackgroundColor3 = trimColor, BackgroundTransparency = 0.06,
				BorderSizePixel = 0, Position = UDim2.fromScale(x, 0.18),
				Size = UDim2.fromScale(0.020, 0.66), ZIndex = 2,
			}, frame)
		end
		-- Crown above identity zone: base bar + 5 spikes
		local crownY = 0.255
		make("Frame", { -- crown base
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.10, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, crownY + 0.062), Size = UDim2.fromScale(0.40, 0.022), ZIndex = 3,
		}, frame)
		local spikeH = {0.048, 0.072, 0.100, 0.072, 0.048}
		for index = 1, 5 do
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = trimColor,
				BackgroundTransparency = index == 3 and 0.02 or 0.14, BorderSizePixel = 0,
				Position = UDim2.fromScale(0.30 + (index - 1) * 0.100, crownY + 0.062),
				Size = UDim2.fromScale(0.028, spikeH[index]), ZIndex = 3,
			}, frame)
		end
		-- Bottom gold accent line
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.25, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.725), Size = UDim2.fromScale(0.82, 0.009), ZIndex = 2,
		}, frame)
		return
	end

	-- ════════════════════════════════════════════════════════════════════════
	-- LEGACY TEMPLATES  (USE_NEW_CARD_DESIGN = false)
	-- ════════════════════════════════════════════════════════════════════════

	if template == "classic" then
		for _, y in ipairs({0.24, 0.64}) do
			make("Frame", {
				BackgroundColor3 = trimColor,
				BackgroundTransparency = 0.62,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.12, y),
				Size = UDim2.new(0.76, 0, 0, 2),
				ZIndex = 1,
			}, frame)
		end
		return
	end

	if template == "diagonal" then
		for _, y in ipairs({0.28, 0.62}) do
			make("Frame", {
				BackgroundColor3 = trimColor,
				BackgroundTransparency = 0.72,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.16, y),
				Size = UDim2.new(0.68, 0, 0, 2),
				ZIndex = 1,
			}, frame)
		end
		return
	end

	if template == "premium" then
		local centerPlate = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(3, 4, 7),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.78, 0.72),
			ZIndex = 1,
		}, frame)
		local plateCorner = Instance.new("UICorner")
		plateCorner.CornerRadius = UDim.new(0.08, 0)
		plateCorner.Parent = centerPlate
		make("UIStroke", {
			Color = trimColor,
			Thickness = 1.4,
			Transparency = 0.32,
		}, centerPlate)
		for _, corner in ipairs({
			UDim2.fromScale(0.10, 0.18),
			UDim2.fromScale(0.82, 0.18),
			UDim2.fromScale(0.10, 0.74),
			UDim2.fromScale(0.82, 0.74),
		}) do
			make("Frame", {
				BackgroundColor3 = trimColor,
				BackgroundTransparency = 0.18,
				BorderSizePixel = 0,
				Position = corner,
				Size = UDim2.fromScale(0.08, 0.08),
				ZIndex = 1,
			}, frame)
		end
		return
	end

	if template == "shard" then
		for index, spec in ipairs({
			{ x = 0.08, y = 0.38, rot = 16, h = 0.48 },
			{ x = 0.90, y = 0.42, rot = -18, h = 0.54 },
			{ x = 0.20, y = 0.70, rot = -28, h = 0.30 },
		}) do
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = index == 2 and trimColor or rarityColor,
				BackgroundTransparency = 0.30,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(spec.x, spec.y),
				Rotation = spec.rot,
				Size = UDim2.fromScale(0.18, spec.h),
				ZIndex = 1,
			}, frame)
		end
		return
	end

	if template == "orbit" then
		for index = 1, 6 do
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = index % 2 == 0 and trimColor or rarityColor,
				BackgroundTransparency = 0.54,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.50),
				Rotation = index * 30,
				Size = UDim2.new(1.10, 0, 0, 2),
				ZIndex = 1,
			}, frame)
		end
		return
	end

	if template == "prism" then
		for index = 1, 4 do
			make("Frame", {
				BackgroundColor3 = index % 2 == 0 and Color3.fromRGB(205, 245, 255) or trimColor,
				BackgroundTransparency = 0.46,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.14 + index * 0.15, 0),
				Rotation = 10,
				Size = UDim2.fromScale(0.08, 1),
				ZIndex = 1,
			}, frame)
		end
		make("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.18,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.16),
			Size = UDim2.new(1, 0, 0, 4),
			ZIndex = 1,
		}, frame)
		return
	end

	if template == "trophy" then
		local trophyPanel = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(5, 4, 1),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.18),
			Size = UDim2.fromScale(0.80, 0.58),
			ZIndex = 1,
		}, frame)
		local trophyPanelCorner = Instance.new("UICorner")
		trophyPanelCorner.CornerRadius = UDim.new(0.08, 0)
		trophyPanelCorner.Parent = trophyPanel
		make("UIStroke", { Color = trimColor, Thickness = 2, Transparency = 0.42 }, trophyPanel)
		for _, x in ipairs({0.07, 0.88}) do
			make("Frame", {
				BackgroundColor3 = trimColor, BackgroundTransparency = 0.16,
				BorderSizePixel = 0, Position = UDim2.fromScale(x, 0.22),
				Size = UDim2.fromScale(0.05, 0.54), ZIndex = 1,
			}, frame)
		end
		local halo = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.70, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.56, 0.34), ZIndex = 1,
		}, frame)
		local haloCorner = Instance.new("UICorner")
		haloCorner.CornerRadius = UDim.new(1, 0); haloCorner.Parent = halo
		make("UIStroke", { Color = Color3.fromRGB(255, 247, 164), Thickness = 2, Transparency = 0.70 }, halo)
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.28, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.34, 0.14), ZIndex = 1,
		}, frame)
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.24, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.50), Size = UDim2.fromScale(0.08, 0.16), ZIndex = 1,
		}, frame)
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.20, BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.64), Size = UDim2.fromScale(0.34, 0.05), ZIndex = 1,
		}, frame)
		local crownBaseY = 0.16
		for index = 1, 5 do
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = trimColor,
				BackgroundTransparency = index == 3 and 0.00 or 0.14, BorderSizePixel = 0,
				Position = UDim2.fromScale(0.18 + index * 0.105, crownBaseY),
				Rotation = (index - 3) * 10,
				Size = UDim2.fromScale(0.07, index == 3 and 0.16 or 0.11), ZIndex = 1,
			}, frame)
		end
	end
end

local function createDisplayCardFace(face, card, incomePerSecond, parent)
	local style = Utils.GetRarityStyle(card.rarity)
	local rarityColor = style.primary
	local secondaryColor = style.secondary or rarityColor
	local darkColor = style.dark or Color3.fromRGB(16, 12, 8)
	local trimColor = style.trim or rarityColor
	local textColor = style.text or Constants.UI.Text
	local treatment = getDisplayCardTreatment(card.rarity)
	local tier = treatment.tier or 0
	local displayRarityLabel = string.upper(treatment.displayLabel or style.label or card.rarity or "CARD")
	local positionAccent = getPositionAccent(card.position, trimColor)

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

	-- ── V2 CARD DESIGN ────────────────────────────────────────────────────────
	if USE_NEW_CARD_DESIGN then
		local isPOTY = treatment.template == "v2_poty"
		local assetId = USE_CARD_FRAME_ASSETS and CARD_FRAME_ASSETS[card.rarity]

		if assetId then
			local accent = CARD_FRAME_ACCENTS[card.rarity] or CARD_FRAME_ACCENTS["Gold"]
			frame.BackgroundTransparency = 1
			local assetTextColor = accent.text
			local surname = string.upper((card.name or "Player"):match("(%S+)%s*$") or (card.name or "Player"))

			make("ImageLabel", {
				BackgroundTransparency = 1,
				Image = assetId,
				ScaleType = Enum.ScaleType.Stretch,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 1,
			}, frame)

			local interiorWash = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = accent.wash,
				BackgroundTransparency = accent.washTransparency,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.190),
				Size = UDim2.fromScale(0.82, 0.515),
				ZIndex = 2,
			}, frame)
			make("UICorner", { CornerRadius = UDim.new(0.08, 0) }, interiorWash)
			make("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, accent.glow),
					ColorSequenceKeypoint.new(0.50, accent.wash),
					ColorSequenceKeypoint.new(1, accent.wash:Lerp(Color3.fromRGB(0, 0, 0), 0.35)),
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.72),
					NumberSequenceKeypoint.new(0.44, 0.00),
					NumberSequenceKeypoint.new(1, 0.18),
				}),
				Rotation = 90,
			}, interiorWash)

			local softGlow = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = accent.glow,
				BackgroundTransparency = accent.glowTransparency,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.420),
				Size = UDim2.fromScale(0.56, 0.26),
				ZIndex = 2,
			}, frame)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, softGlow)
			make("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.82),
					NumberSequenceKeypoint.new(0.50, 0.00),
					NumberSequenceKeypoint.new(1, 0.88),
				}),
			}, softGlow)

			local rarityText = createSignLabel(displayRarityLabel, UDim2.fromScale(0.78, 0.055), UDim2.fromScale(0.11, 0.043), assetTextColor, frame)
			rarityText.ZIndex = 4
			rarityText.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = isPOTY and 5 or 6, MaxTextSize = isPOTY and 12 or 15 }, rarityText)
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.4, Transparency = 0.18 }, rarityText)

			-- FIFA-style left column for asset branch
			local assetLeftCol = make("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.42,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.05, 0.06),
				Size = UDim2.fromScale(0.27, 0.22),
				ZIndex = 3,
			}, frame)
			make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, assetLeftCol)

			if card.rating then
				local ratingNum = createSignLabel(tostring(card.rating), UDim2.fromScale(0.90, 0.58), UDim2.fromScale(0.05, 0.06), assetTextColor, assetLeftCol)
				ratingNum.TextXAlignment = Enum.TextXAlignment.Center
				ratingNum.ZIndex = 5
				make("UITextSizeConstraint", { MinTextSize = 16, MaxTextSize = 50 }, ratingNum)
				make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2.2, Transparency = 0.08 }, ratingNum)
			end

			local assetPosText = createSignLabel(string.upper(card.position or "--"), UDim2.fromScale(0.88, 0.36), UDim2.fromScale(0.06, 0.64), assetTextColor, assetLeftCol)
			assetPosText.TextXAlignment = Enum.TextXAlignment.Center
			assetPosText.ZIndex = 5
			make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 18 }, assetPosText)

			local nationLabel = createSignLabel(card.nation or "Unknown", UDim2.fromScale(0.40, 0.06), UDim2.fromScale(0.53, 0.126), assetTextColor, frame)
			nationLabel.ZIndex = 4
			nationLabel.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = 6, MaxTextSize = 13 }, nationLabel)
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.1, Transparency = 0.24 }, nationLabel)
			addCenterFlag(card.nation, frame, 3)

			local heroLabel = createSignLabel(surname, UDim2.fromScale(0.82, 0.09), UDim2.fromScale(0.09, 0.515), assetTextColor, frame)
			heroLabel.ZIndex = 4
			heroLabel.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = isPOTY and 26 or 30 }, heroLabel)
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.08 }, heroLabel)

			local nameLabel = createSignLabel(string.upper(card.name or "Player"), UDim2.fromScale(0.86, 0.07), UDim2.fromScale(0.07, 0.742), Color3.fromRGB(255, 255, 245), frame)
			nameLabel.ZIndex = 4
			nameLabel.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 16 }, nameLabel)
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.3, Transparency = 0.20 }, nameLabel)

			local incomeLabel = createSignLabel("+" .. tostring(incomePerSecond) .. " fans/s", UDim2.fromScale(0.82, 0.075), UDim2.fromScale(0.09, 0.858), Color3.fromRGB(184, 255, 196), frame)
			incomeLabel.ZIndex = 4
			incomeLabel.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 16 }, incomeLabel)
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.4, Transparency = 0.18 }, incomeLabel)

			return
		end

		-- Per-rarity background gradient (each rarity has a distinct palette)
		local gradRotation = 145
		local gradColors
		if tier == 6 then           -- POTY: jet black / deep charcoal — luxury
			gradColors = {
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(6,  4,  2)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(18, 12, 4)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(8,  6,  2)),
			}
		elseif tier == 5 then       -- Immortal: bright ice blue-white — glowing
			gradColors = {
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(225, 242, 255)),
				ColorSequenceKeypoint.new(0.40, Color3.fromRGB(192, 218, 248)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(158, 188, 228)),
			}
		elseif tier == 4 then       -- Maestro: deep navy-charcoal — powerful
			gradColors = {
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(10,  8, 24)),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(16, 12, 32)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(6,   5, 14)),
			}
		elseif tier == 3 then       -- Talisman: bold red top → near-black — fierce
			gradColors = {
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(115, 8,  8)),
				ColorSequenceKeypoint.new(0.38, Color3.fromRGB(58,  6,  6)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(12,  8,  8)),
			}
			gradRotation = 160
		elseif tier == 2 then       -- Premium: cool dark slate — refined
			gradColors = {
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(12, 16, 28)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(20, 24, 40)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(8,  10, 18)),
			}
		elseif tier == 1 then       -- Rare Gold: vivid orange-amber (clearly different from base Gold)
			gradColors = {
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(210, 110, 20)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(170, 72,  10)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(80,  28,  4)),
			}
		else                        -- Gold: bright warm yellow-gold (light, readable, classic)
			gradColors = {
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(220, 175, 30)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(180, 130, 10)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(90,  55,  4)),
			}
		end
		make("UIGradient", { Color = ColorSequence.new(gradColors), Rotation = gradRotation }, frame)

		-- Decorative overlays: stripes / beams / stars / shimmer (per-rarity)
		addDisplayCardTemplate(frame, treatment, tier, rarityColor, secondaryColor, darkColor, trimColor, textColor)

		-- Outer border
		make("UIStroke", { Color = trimColor, Thickness = treatment.edge or 4 }, frame)

		-- Inner border (tier 1+)
		if tier >= 1 then
			local ib = make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -(16 + tier * 2), 1, -(16 + tier * 2)),
				Position = UDim2.fromOffset(8 + tier, 8 + tier),
			}, frame)
			make("UIStroke", {
				Color = tier >= 4 and trimColor or Color3.fromRGB(24, 16, 4),
				Thickness = tier >= 4 and 2 or 1.5,
				Transparency = tier >= 4 and 0.20 or 0.50,
			}, ib)
		end

		-- Rarity band — full-width pill for POTY, scaled pill for others
		local bandW = isPOTY and 0.88 or math.min(0.72 + tier * 0.03, 0.88)
		local bandH = isPOTY and 0.115 or 0.088
		local rarityBand = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = isPOTY and Color3.fromRGB(4, 2, 0) or Color3.fromRGB(6, 7, 10),
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.038),
			Size = UDim2.fromScale(bandW, bandH),
		}, frame)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, rarityBand)
		make("UIStroke", { Color = trimColor, Thickness = isPOTY and 1.8 or 1.3, Transparency = 0.15 }, rarityBand)
		local rarityText = createSignLabel(displayRarityLabel, UDim2.fromScale(0.92, 0.80), UDim2.fromScale(0.04, 0.10), textColor, rarityBand)
		make("UITextSizeConstraint", { MinTextSize = isPOTY and 5 or 6, MaxTextSize = isPOTY and 12 or 16 }, rarityText)

		-- FIFA-style left column: big rating number + position stacked
		local leftCol = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.42,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.05, 0.13),
			Size = UDim2.fromScale(0.27, 0.24),
			ZIndex = 3,
		}, frame)
		make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, leftCol)
		make("UIStroke", { Color = trimColor, Thickness = 1.4, Transparency = 0.28 }, leftCol)

		if card.rating then
			local ratingNum = createSignLabel(tostring(card.rating), UDim2.fromScale(0.90, 0.58), UDim2.fromScale(0.05, 0.06), textColor, leftCol)
			ratingNum.TextXAlignment = Enum.TextXAlignment.Center
			ratingNum.ZIndex = 5
			make("UITextSizeConstraint", { MinTextSize = 16, MaxTextSize = 50 }, ratingNum)
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2.2, Transparency = 0.08 }, ratingNum)
		end

		local posText = createSignLabel(string.upper(card.position or "--"), UDim2.fromScale(0.88, 0.36), UDim2.fromScale(0.06, 0.64), positionAccent, leftCol)
		posText.TextXAlignment = Enum.TextXAlignment.Center
		posText.ZIndex = 5
		make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 18 }, posText)
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.4, Transparency = 0.18 }, posText)

		-- Nation label (top-right, right-aligned)
		local nationLabel = createSignLabel(card.nation or "Unknown", UDim2.new(0.46, 0, 0.09, 0), UDim2.new(0.46, 0, 0.17, 0), textColor, frame)
		nationLabel.TextXAlignment = Enum.TextXAlignment.Right
		make("UITextSizeConstraint", { MinTextSize = 6, MaxTextSize = 13 }, nationLabel)
		addCenterFlag(card.nation, frame, 3)

		-- Surname for big identity text (last word of name, e.g. "Haaland" from "Erling Haaland")
		local surname = string.upper((card.name or "Player"):match("(%S+)%s*$") or (card.name or "Player"))

		-- Identity panel — big SURNAME so you can tell who the card is from across the pitch
		local identityPanel = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = isPOTY and Color3.fromRGB(6, 4, 0) or Color3.fromRGB(4, 6, 12),
			BackgroundTransparency = isPOTY and 0.08 or (tier == 5 and 0.52 or (tier >= 3 and 0.22 or 0.38)),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.385),
			Size = UDim2.fromScale(0.80, 0.25),
			ZIndex = 3,
		}, frame)
		make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, identityPanel)
		make("UIStroke", {
			Color = isPOTY and trimColor or trimColor,
			Thickness = isPOTY and 2.2 or (tier >= 3 and 1.8 or 1.2),
			Transparency = isPOTY and 0.08 or (tier >= 3 and 0.20 or 0.40),
		}, identityPanel)

		if isPOTY then
			-- "PLAYER OF THE YEAR" top line, then surname below it
			local potyLabel = createSignLabel("PLAYER OF THE YEAR", UDim2.fromScale(0.90, 0.46), UDim2.fromScale(0.05, 0.06), trimColor, identityPanel)
			potyLabel.ZIndex = 5
			potyLabel.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = 6, MaxTextSize = 13 }, potyLabel)
			local potySurname = createSignLabel(surname, UDim2.fromScale(0.90, 0.82), UDim2.fromScale(0.05, 0.52), textColor, identityPanel)
			potySurname.ZIndex = 5
			potySurname.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 28 }, potySurname)
		else
			-- Surname fills the panel — this is what you read from distance
			local bigName = createSignLabel(surname, UDim2.fromScale(0.92, 0.84), UDim2.fromScale(0.04, 0.08), textColor, identityPanel)
			bigName.ZIndex = 5
			bigName.TextXAlignment = Enum.TextXAlignment.Center
			make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 36 }, bigName)
		end

		-- Divider line
		make("Frame", {
			BackgroundColor3 = trimColor,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			Size = UDim2.new(0.76, 0, 0, 2),
			Position = UDim2.new(0.12, 0, 0.685, 0),
		}, frame)

		-- Full name beneath panel
		local nameLabel = createSignLabel(string.upper(card.name or "Player"), UDim2.new(0.86, 0, 0.10, 0), UDim2.new(0.07, 0, 0.705, 0), textColor, frame)
		make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 22 }, nameLabel)
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.2, Transparency = 0.30 }, nameLabel)

		-- Income pill
		local incomePill = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(22, 52, 28),
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			Position = UDim2.new(0.14, 0, 0.865, 0),
			Size = UDim2.new(0.72, 0, 0.10, 0),
		}, frame)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, incomePill)
		make("UIStroke", { Color = Color3.fromRGB(120, 210, 136), Thickness = 1.4, Transparency = 0.28 }, incomePill)
		createSignLabel("+" .. tostring(incomePerSecond) .. " fans/s", UDim2.fromScale(0.90, 0.72), UDim2.fromScale(0.05, 0.14), Color3.fromRGB(226, 255, 218), incomePill)

		return  -- V2 done — skip legacy code below
	end
	-- ── END V2 ────────────────────────────────────────────────────────────────

	-- LEGACY BRANCH  (USE_NEW_CARD_DESIGN = false) ─────────────────────────────
	local isTrophyCard = treatment.template == "trophy"
	local initials = getCardInitials(card.name)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, tier >= 4 and trimColor or rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12)),
			ColorSequenceKeypoint.new(0.30, secondaryColor),
			ColorSequenceKeypoint.new(0.64, tier >= 3 and rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.22) or secondaryColor),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 138,
	}, frame)
	addDisplayCardTemplate(frame, treatment, tier, rarityColor, secondaryColor, darkColor, trimColor, textColor)

	make("UIStroke", {
		Color = trimColor,
		Thickness = treatment.edge or 4,
	}, frame)

	local innerBorder = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(14 + tier), 1, -(14 + tier)),
		Position = UDim2.fromOffset(7 + tier / 2, 7 + tier / 2),
	}, frame)
	make("UIStroke", {
		Color = tier >= 4 and trimColor or Color3.fromRGB(24, 16, 4),
		Thickness = tier >= 3 and 2.2 or 1.5,
		Transparency = tier >= 4 and 0.24 or 0.55,
	}, innerBorder)

	local railWidth = 0.035 + math.min(tier, 6) * 0.006
	for _, rail in ipairs({
		{ anchor = Vector2.new(0, 0), position = UDim2.fromScale(0, 0) },
		{ anchor = Vector2.new(1, 0), position = UDim2.fromScale(1, 0) },
	}) do
		local railFrame = make("Frame", {
			AnchorPoint = rail.anchor,
			BackgroundColor3 = trimColor,
			BackgroundTransparency = tier >= 3 and 0.08 or 0.20,
			BorderSizePixel = 0,
			Position = rail.position,
			Size = UDim2.new(railWidth, 0, 1, 0),
		}, frame)
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, trimColor),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, trimColor),
			}),
			Rotation = 90,
		}, railFrame)
	end

	for index = 1, treatment.patternCount or 5 do
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = tier >= 4 and 0.80 or (tier >= 2 and 0.87 or 0.93),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, index / ((treatment.patternCount or 5) + 1)),
			Rotation = tier >= 4 and -31 or -22,
			Size = UDim2.new(tier >= 3 and 1.45 or 1.25, 0, 0, tier >= 4 and 2 or 1),
		}, frame)
	end

	if isTrophyCard then
		for index = 1, 5 do
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = index % 2 == 0 and Color3.fromRGB(255, 244, 143) or trimColor,
				BackgroundTransparency = 0.78,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.49),
				Rotation = index * 36,
				Size = UDim2.new(0.96, 0, 0, 2),
				ZIndex = 1,
			}, frame)
		end
	end

	if tier >= 2 and not isTrophyCard then
		local tag = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(6, 7, 10),
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.018, 0),
			Size = UDim2.new(0.46, 0, 0.07, 0),
		}, frame)
		local tagCorner = Instance.new("UICorner")
		tagCorner.CornerRadius = UDim.new(1, 0)
		tagCorner.Parent = tag
		make("UIStroke", {
			Color = trimColor,
			Thickness = 1.2,
			Transparency = 0.12,
		}, tag)
		local tagLabel = createSignLabel(treatment.tag or "", UDim2.fromScale(0.88, 0.74), UDim2.fromScale(0.06, 0.13), textColor, tag)
		make("UITextSizeConstraint", { MinTextSize = 6, MaxTextSize = 12 }, tagLabel)
	end

	local rarityBand = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(6, 7, 10),
		BackgroundTransparency = tier >= 4 and 0.02 or 0.12,
		BorderSizePixel = 0,
		Size = isTrophyCard and UDim2.new(0.90, 0, 0.13, 0) or UDim2.new(tier >= 3 and 0.82 or 0.76, 0, tier >= 3 and 0.11 or 0.1, 0),
		Position = isTrophyCard and UDim2.new(0.05, 0, 0.045, 0) or UDim2.new(tier >= 3 and 0.09 or 0.12, 0, tier >= 2 and 0.095 or 0.06, 0),
	}, frame)
	local rarityCorner = Instance.new("UICorner")
	rarityCorner.CornerRadius = UDim.new(1, 0)
	rarityCorner.Parent = rarityBand
	make("UIStroke", {
		Color = trimColor,
		Thickness = 1.4,
		Transparency = 0.2,
	}, rarityBand)
	local rarityText = createSignLabel(displayRarityLabel, UDim2.fromScale(0.92, 0.82), UDim2.fromScale(0.04, 0.09), textColor, rarityBand)
	make("UITextSizeConstraint", { MinTextSize = isTrophyCard and 6 or 7, MaxTextSize = isTrophyCard and 15 or 18 }, rarityText)

	-- FIFA-style left column: big rating + position
	local legacyLeftCol = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		Position = UDim2.new(0.06, 0, 0.195, 0),
		Size = UDim2.new(0.27, 0, 0.24, 0),
		ZIndex = 3,
	}, frame)
	make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, legacyLeftCol)
	make("UIStroke", { Color = trimColor, Thickness = 1.4, Transparency = 0.28 }, legacyLeftCol)

	if card.rating then
		local ratingNum = createSignLabel(tostring(card.rating), UDim2.fromScale(0.90, 0.58), UDim2.fromScale(0.05, 0.06), textColor, legacyLeftCol)
		ratingNum.TextXAlignment = Enum.TextXAlignment.Center
		ratingNum.ZIndex = 5
		make("UITextSizeConstraint", { MinTextSize = 16, MaxTextSize = 50 }, ratingNum)
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2.2, Transparency = 0.08 }, ratingNum)
	end

	local legacyPosText = createSignLabel(string.upper(card.position or "--"), UDim2.fromScale(0.88, 0.36), UDim2.fromScale(0.06, 0.64), textColor, legacyLeftCol)
	legacyPosText.TextXAlignment = Enum.TextXAlignment.Center
	legacyPosText.ZIndex = 5
	make("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 18 }, legacyPosText)

	local nationLabel = createSignLabel(card.nation or "Unknown", UDim2.new(0.48, 0, 0.08, 0), UDim2.new(0.41, 0, 0.295, 0), textColor, frame)
	nationLabel.TextXAlignment = Enum.TextXAlignment.Right
	make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 14 }, nationLabel)
	addCenterFlag(card.nation, frame, 3)

	local identityPanel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = isTrophyCard and Color3.fromRGB(8, 5, 0) or Color3.fromRGB(4, 6, 11),
		BackgroundTransparency = isTrophyCard and 0.16 or (tier >= 3 and 0.30 or 0.46),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.405, 0),
		Size = UDim2.new(0.68, 0, 0.26, 0),
		ZIndex = 3,
	}, frame)
	local identityCorner = Instance.new("UICorner")
	identityCorner.CornerRadius = UDim.new(0.18, 0)
	identityCorner.Parent = identityPanel
	make("UIStroke", {
		Color = isTrophyCard and trimColor or positionAccent,
		Thickness = isTrophyCard and 2 or (tier >= 3 and 1.6 or 1),
		Transparency = isTrophyCard and 0.14 or (tier >= 3 and 0.28 or 0.48),
	}, identityPanel)

	if isTrophyCard then
		local potyStamp = createSignLabel("POTY", UDim2.fromScale(0.9, 0.28), UDim2.fromScale(0.05, 0.05), Color3.fromRGB(255, 232, 82), identityPanel)
		potyStamp.ZIndex = 4
		potyStamp.TextXAlignment = Enum.TextXAlignment.Center
		make("UITextSizeConstraint", { MinTextSize = 6, MaxTextSize = 14 }, potyStamp)
	end

	local initialsLabel = createSignLabel(initials, isTrophyCard and UDim2.fromScale(0.78, 0.54) or UDim2.fromScale(0.78, 0.76), isTrophyCard and UDim2.fromScale(0.11, 0.30) or UDim2.fromScale(0.11, 0.06), textColor, identityPanel)
	initialsLabel.ZIndex = 5
	initialsLabel.TextXAlignment = Enum.TextXAlignment.Center
	make("UITextSizeConstraint", { MinTextSize = 22, MaxTextSize = tier >= 4 and 54 or 46 }, initialsLabel)

	local positionMark = createSignLabel(string.upper(card.position or "--"), UDim2.fromScale(0.34, 0.24), UDim2.fromScale(0.33, isTrophyCard and 0.72 or 0.70), positionAccent, identityPanel)
	positionMark.ZIndex = 5
	positionMark.TextXAlignment = Enum.TextXAlignment.Center
	make("UITextSizeConstraint", { MinTextSize = 6, MaxTextSize = 14 }, positionMark)

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

local SLOT_HALO_EMPTY    = Color3.fromRGB(60, 230, 110)
local SLOT_HALO_OCCUPIED = Color3.fromRGB(218, 168, 40)

local function setSlotHalo(slot, color)
	if not slot or not slot.halo then
		return
	end
	slot.halo.Color = color
	local light = slot.halo:FindFirstChild("HaloLight")
	if light then
		light.Color = color
	end
end

local function clearDisplayCard(slot)
	if slot.cardModel and slot.cardModel.Parent then
		slot.cardModel:Destroy()
	end
	slot.cardModel = nil
	slot.model:SetAttribute("Occupied", false)
	setSlotHalo(slot, SLOT_HALO_EMPTY)
end

local function setSlotPrompt(slot, actionText, objectText, enabled)
	slot.prompt.ActionText = actionText
	slot.prompt.ObjectText = objectText
	slot.prompt.Enabled = enabled
end

-- pedestalSizeZ: optional override for the pedestal's Z (depth) dimension.
-- Rebirth gallery slots pass 3 here so the pedestal is slender enough to leave
-- clean walkable space between adjacent slots.
local function createDisplaySlot(parent, index, cframe, lookDirection, pedestalSizeZ)
	local model = make("Model", {
		Name = "DisplaySlot" .. index,
	}, parent)

	local slotW = layout.DisplaySlotSize.X
	local slotH = layout.DisplaySlotSize.Y
	local slotD = pedestalSizeZ or layout.DisplaySlotSize.Z
	local topY  = slotH / 2

	-- Pedestal body — dark polished concrete.
	local base = make("Part", {
		Name = "Base",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(14, 19, 30),
		Size = Vector3.new(slotW, slotH, slotD),
		CFrame = cframe,
	}, model)

	-- Green glow halo on the floor under the pedestal — marks the slot as
	-- available. When a card is placed it will be colour-shifted to gold.
	local haloColorEmpty = Color3.fromRGB(60, 230, 110)
	local halo = make("Part", {
		Name = "GlowHalo",
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon,
		Color = haloColorEmpty,
		Transparency = 0.30,
		Size = Vector3.new(slotW + 1.4, 0.08, slotD + 1.4),
		CFrame = cframe + Vector3.new(0, -(slotH / 2) + 0.04, 0),
	}, model)
	make("PointLight", {
		Name = "HaloLight",
		Color = haloColorEmpty,
		Brightness = 1.4, Range = 9, Shadows = false,
	}, halo)

	-- Slim refined gold rim around the top edge (4 strips, more subtle now)
	local rimThickness = 0.18
	local rimHeight    = 0.22
	local rimY         = topY + rimHeight / 2
	local rimColor     = Color3.fromRGB(218, 168, 40)
	local rimTransp    = 0.42
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

	-- Soft top glow plate (toned down, no longer screaming gold)
	local top = make("Part", {
		Name = "Top",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(218, 168, 40),
		Transparency = 0.62,
		Size = Vector3.new(slotW - 1.6, 0.12, slotD - 1.6),
		CFrame = base.CFrame + Vector3.new(0, topY + 0.07, 0),
	}, model)

	-- Slot number on the player-facing face. Ground slots face across Z; rebirth
	-- gallery slots face across X toward the pitch.
	local numFace
	if math.abs(lookDirection.X) > math.abs(lookDirection.Z) then
		numFace = lookDirection.X > 0 and Enum.NormalId.Right or Enum.NormalId.Left
	else
		numFace = lookDirection.Z > 0 and Enum.NormalId.Back or Enum.NormalId.Front
	end
	local function attachSlotNumber(face)
		local numGui = make("SurfaceGui", {
			Name = "SlotNum_" .. tostring(face),
			Face = face,
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
	end
	attachSlotNumber(numFace)
	if numFace == Enum.NormalId.Front then
		attachSlotNumber(Enum.NormalId.Back)
	elseif numFace == Enum.NormalId.Back then
		attachSlotNumber(Enum.NormalId.Front)
	elseif numFace == Enum.NormalId.Left then
		attachSlotNumber(Enum.NormalId.Right)
	else
		attachSlotNumber(Enum.NormalId.Left)
	end

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
		halo = halo,
		prompt = prompt,
		slotIndex = index,
		lookDirection = lookDirection,
		cardModel = nil,
	}
end

-- ── Display-slot world offsets (local space, X scaled by facingDirection) ─────
-- Slots 1-6  : base layout (every player starts with these)
-- Slots 7-18 : unlocked one-per-rebirth on the back-wall Rebirth Gallery.
-- Slot X values are multiplied by facingDirection later, so negative X means
-- "toward the back wall" for both left- and right-side plots.
local ALL_SLOT_OFFSETS = {
	-- Ground floor (always present) — 2 rows of 3 across the pitch
	Vector3.new(-21.3, 2.75, -21),  -- 1
	Vector3.new(  0.0, 2.75, -21),  -- 2
	Vector3.new( 21.3, 2.75, -21),  -- 3
	Vector3.new(-21.3, 2.75,  21),  -- 4
	Vector3.new(  0.0, 2.75,  21),  -- 5
	Vector3.new( 21.3, 2.75,  21),  -- 6
	-- Rebirth Gallery row 1 — 4 slots spread evenly across the deck (more breathing room).
	Vector3.new(-36, 3.2, -18), -- 7
	Vector3.new(-36, 3.2,  -6), -- 8
	Vector3.new(-36, 3.2,   6), -- 9
	Vector3.new(-36, 3.2,  18), -- 10
	-- Rebirth Terrace (slots 11-18) — elevated deck unlocked at rebirth 5+.
	-- Y=17.75 matches the terrace deck surface built in UpdateStadiumTier.
	Vector3.new(-36, 17.75, -21), -- 11
	Vector3.new(-36, 17.75, -15), -- 12
	Vector3.new(-36, 17.75,  -9), -- 13
	Vector3.new(-36, 17.75,  -3), -- 14
	Vector3.new(-36, 17.75,   3), -- 15
	Vector3.new(-36, 17.75,   9), -- 16
	Vector3.new(-36, 17.75,  15), -- 17
	Vector3.new(-36, 17.75,  21), -- 18
}

local function slotLookDir(localOffset, facingDirection, slotIndex)
	if slotIndex and slotIndex > layout.DisplaySlotCount then
		-- Rebirth gallery cards face inward toward the pitch.
		return Vector3.new(facingDirection, 0, 0)
	end

	-- Ground-floor slots use Z-based facing:
	-- back row (Z < 0) faces south (+Z); front row (Z > 0) faces north (-Z).
	return localOffset.Z < 0 and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1)
end

local function resolveDisplaySlotOffset(localOffset, facingDirection, slotIndex)
	return Vector3.new(localOffset.X * facingDirection, localOffset.Y, localOffset.Z)
end


local createConceptTestStadium

local function createPlot(plotId, side, laneIndex, position)
	local model = make("Model", {
		Name = "Base" .. plotId,
	}, basesFolder)

	local facingDirection = side == "Left" and 1 or -1
	local baseCFrame = CFrame.new(position)
	local centerDirection = Vector3.new(facingDirection, 0, 0)
	local wallHeight = layout.FenceHeight or 4.5
	local entranceWidth = layout.EntranceWidth or 16
	local entrancePillarWidth = layout.EntrancePillarWidth or 2.2
	local padInfoMaxDistance = layout.PadInfoMaxDistance or 22
	local frontEdgeX = facingDirection * (layout.PlotSize.X / 2)
	local backEdgeX = -frontEdgeX
	local entrancePillarHeight = wallHeight + 5.6

	local floor = make("Part", {
		Name = "Floor",
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Transparency = 1,
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	createConceptTestStadium(model, position, {
		name = "LiveStadiumShell",
		facingDirection = facingDirection,
		includeCenterPad = false,
		includeDisplaySlots = false,
		includeEntranceSign = false,
	})

	local starterStadiumFolder = make("Folder", {
		Name = "StarterStadium",
	}, model)

	-- ── Pack Pad: layered octagonal-feel podium with red glow halo ──────────────
	local packPadCenter = baseCFrame * CFrame.new(0, 1.5, 0)
	local packPadW = layout.PackPadSize.X
	local packPadD = layout.PackPadSize.Z

	-- Outer red glow ring on the floor (the "halo" under the podium)
	make("Part", {
		Name = "PackPadHalo",
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 60, 60),
		Transparency = 0.22,
		Size = Vector3.new(0.18, packPadW + 5.5, packPadD + 5.5),
		CFrame = (packPadCenter - Vector3.new(0, 0.36, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)
	make("PointLight", {
		Name = "PackPadHaloLight",
		Color = Color3.fromRGB(255, 80, 80),
		Brightness = 2.4, Range = 18, Shadows = false,
	}, model:FindFirstChild("PackPadHalo"))

	-- Dark base ring sitting on top of the halo (gives the podium depth)
	make("Part", {
		Name = "PackPadBaseRing",
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 14, 22),
		Size = Vector3.new(0.32, packPadW + 4, packPadD + 4),
		CFrame = (packPadCenter - Vector3.new(0, 0.20, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)

	-- Octagonal corner-cut wedges turn the square pad into an octagon-feel.
	-- 4 wedges shave the corners; viewed from above the result is an octagon.
	local cornerCut = 1.6
	for _, corner in ipairs({
		{ x =  packPadW / 2, z =  packPadD / 2, yaw =   0 },
		{ x = -packPadW / 2, z =  packPadD / 2, yaw =  90 },
		{ x = -packPadW / 2, z = -packPadD / 2, yaw = 180 },
		{ x =  packPadW / 2, z = -packPadD / 2, yaw = 270 },
	}) do
		make("WedgePart", {
			Name = "PackPadCorner",
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(10, 14, 22),
			Size = Vector3.new(cornerCut, layout.PackPadSize.Y + 0.05, cornerCut),
			CFrame = packPadCenter
				* CFrame.new(corner.x - cornerCut / 2 * math.sign(corner.x),
				             0,
				             corner.z - cornerCut / 2 * math.sign(corner.z))
				* CFrame.Angles(0, math.rad(corner.yaw), 0),
		}, model)
	end

	-- Main interactive pack pad (kept rectangular for clean prompt geometry,
	-- but visually trimmed by the octagon corner wedges above + neon edges).
	local packPad = make("Part", {
		Name = "PackPad",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(176, 28, 28),
		Size = layout.PackPadSize,
		CFrame = packPadCenter,
	}, model)

	-- Bright red neon top accent — a thinner glow strip running just above
	-- the pad surface (gives the "lit pack pedestal" look).
	make("Part", {
		Name = "PackPadTopGlow",
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 70, 70),
		Transparency = 0.45,
		Size = Vector3.new(packPadW - 1.6, 0.14, packPadD - 1.6),
		CFrame = packPadCenter + Vector3.new(0, layout.PackPadSize.Y / 2 + 0.07, 0),
	}, model)


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
		CFrame = baseCFrame * CFrame.new(facingDirection * 39, 1.5, 0),
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
	local ownerSignPosition = position + (centerDirection * (layout.PlotSize.X / 2 + 9.8)) + Vector3.new(0, entranceBeamY + 5.0, 0)
	createFence(
		model,
		Vector3.new(entrancePillarWidth + 1.6, 2.6, entranceWidth + 1.4),
		baseCFrame * CFrame.new(frontEdgeX + (facingDirection * 8.6), entranceBeamY + 0.6, 0)
	)
	-- Neon gold strips top and bottom of beam (positions computed from known values)
	local beamLocalX   = frontEdgeX + (facingDirection * 8.6)
	local beamCenterY  = entranceBeamY + 0.6
	local beamW        = entrancePillarWidth + 1.6 + 0.2
	local beamD        = entranceWidth + 1.4 + 0.1
	for _, ySign in ipairs({1, -1}) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 210, 50),
			Transparency = 0.88,
			Size = Vector3.new(beamW, 0.16, beamD),
			CFrame = baseCFrame * CFrame.new(beamLocalX, beamCenterY + ySign * (2.6 / 2 + 0.14), 0),
		}, model)
	end
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
			Transparency = 0.32,
			Size = cfg[1],
			CFrame = cfg[2],
		}, model)
	end

	-- SurfaceLight: illuminates the entrance area below the sign
	make("SurfaceLight", {
		Face = Enum.NormalId.Front,
		Brightness = 1.4,
		Range = 14,
		Color = Color3.fromRGB(255, 238, 195),
		Angle = 60,
	}, ownerSign)

	-- Backlight: warms the area behind the sign so it reads as a 3D object, not a flat panel
	make("SurfaceLight", {
		Face = Enum.NormalId.Back,
		Brightness = 0.7,
		Range = 10,
		Color = Color3.fromRGB(255, 225, 140),
		Angle = 80,
	}, ownerSign)

	-- PointLight above sign for atmosphere
	make("PointLight", {
		Brightness = 0.5,
		Range = 16,
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

	-- ── Close-range rebirth multiplier badge near the entrance ─────────────────
	local multiplierAnchor = make("Part", {
		Name = "RebirthMultiplierAnchor",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = baseCFrame * CFrame.new(frontEdgeX + (facingDirection * 4.4), 6.3, 0),
	}, model)

	local multiplierGui = make("BillboardGui", {
		Name = "RebirthMultiplierGui",
		Adornee = multiplierAnchor,
		AlwaysOnTop = true,
		Enabled = false,
		MaxDistance = 38,
		Size = UDim2.fromOffset(190, 58),
		StudsOffset = Vector3.new(0, 0, 0),
	}, multiplierAnchor)

	local multiplierFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, multiplierGui)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, multiplierFrame)
	make("UIStroke", {
		Color = Color3.fromRGB(255, 210, 50),
		Thickness = 2,
		Transparency = 0.15,
	}, multiplierFrame)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 27, 46)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 18)),
		}),
		Rotation = 90,
	}, multiplierFrame)

	createOwnerSignText("REBIRTH BOOST", UDim2.fromScale(0.84, 0.28),
		UDim2.fromScale(0.08, 0.08), Color3.fromRGB(190, 170, 110), {
		textScaled = true, minTextSize = 9, maxTextSize = 16,
		textStrokeTransparency = 0.92, font = Enum.Font.GothamBold,
	}, multiplierFrame)

	local rebirthMultiplierLabel = createOwnerSignText("1x FANS", UDim2.fromScale(0.88, 0.48),
		UDim2.fromScale(0.06, 0.40), Color3.fromRGB(255, 232, 110), {
		textScaled = true, minTextSize = 18, maxTextSize = 42,
		textStrokeTransparency = 0.45, font = Enum.Font.GothamBlack,
	}, multiplierFrame)

	-- ── Pack Milestone Board ─────────────────────────────────────────────────────
	-- Raised behind the stadium shell so it stays readable above the back wall.
	local msW, msH = 28, 14
	local milestoneSignPosition = position
		+ Vector3.new(backEdgeX - (facingDirection * 18), 27, 0)
	local milestoneSign = make("Part", {
		Name = "PackMilestoneBillboard",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(6, 9, 16),
		Size = Vector3.new(msW, msH, 0.6),
		CFrame = CFrame.lookAt(milestoneSignPosition, milestoneSignPosition + centerDirection),
	}, model)

	local boardGold = Color3.fromRGB(255, 210, 50)
	for _, cfg in ipairs({
		{ Vector3.new(msW + 0.3, 0.18, 0.65), Vector3.new(0,  msH / 2 + 0.09, 0) },
		{ Vector3.new(msW + 0.3, 0.18, 0.65), Vector3.new(0, -msH / 2 - 0.09, 0) },
		{ Vector3.new(0.18, msH + 0.3, 0.65), Vector3.new(-msW / 2 - 0.09, 0,  0) },
		{ Vector3.new(0.18, msH + 0.3, 0.65), Vector3.new( msW / 2 + 0.09, 0,  0) },
	}) do
		make("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			Material = Enum.Material.Neon,
			Color = boardGold,
			Transparency = 0.28,
			Size = cfg[1],
			CFrame = CFrame.lookAt(milestoneSignPosition, milestoneSignPosition + centerDirection)
				* CFrame.new(cfg[2]),
		}, model)
	end

		local milestoneLight = make("PointLight", {
			Color = boardGold, Range = 22, Brightness = 0.5, Shadows = false,
		}, milestoneSign)

	local milestoneGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 90,
		LightInfluence = 0,
	}, milestoneSign)

	-- ── Root frame ───────────────────────────────────────────────
	local mf = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, milestoneGui)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, mf)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 20, 36)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(7,  10, 18)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(4,  6,  12)),
		}),
		Rotation = 90,
	}, mf)

	-- ── Header: "★ PACK MILESTONES" (0 – 0.10) ───────────────────
	createOwnerSignText("\u{2605} PACK MILESTONES", UDim2.fromScale(0.80, 0.07),
		UDim2.fromScale(0.10, 0.015), Color3.fromRGB(255, 215, 0), {
		textScaled = true, minTextSize = 12, maxTextSize = 28,
		textStrokeTransparency = 0.60, font = Enum.Font.GothamBlack,
	}, mf)

	-- Thin gold divider below header
	make("Frame", {
		BackgroundColor3 = boardGold, BackgroundTransparency = 0.40,
		BorderSizePixel = 0,
		Size = UDim2.new(0.80, 0, 0, 2),
		Position = UDim2.fromScale(0.10, 0.095),
	}, mf)

	-- ── Hero counter: "X PACKS OPENED" (0.10 – 0.40) ─────────────
	local milestonePacksLabel = createOwnerSignText("0 PACKS OPENED",
		UDim2.fromScale(0.90, 0.27), UDim2.fromScale(0.05, 0.105),
		Color3.fromRGB(255, 250, 230), {
		textScaled = true, minTextSize = 28, maxTextSize = 90,
		textStrokeTransparency = 0.50, font = Enum.Font.GothamBlack,
	}, mf)

	-- ── Divider (0.39) ─────────────────────────────────────────────
	make("Frame", {
		BackgroundColor3 = boardGold, BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(0.84, 0, 0, 2),
		Position = UDim2.fromScale(0.08, 0.39),
	}, mf)

	-- ── "NEXT REWARD:" label (0.40 – 0.46) ────────────────────────
	createOwnerSignText("NEXT REWARD:", UDim2.fromScale(0.60, 0.055),
		UDim2.fromScale(0.20, 0.40), Color3.fromRGB(170, 160, 140), {
		textScaled = true, minTextSize = 10, maxTextSize = 22,
		textStrokeTransparency = 0.90, font = Enum.Font.GothamBold,
	}, mf)

	-- ── Next reward text: "X / Y PACKS → GUARANTEE" (0.46 – 0.58) ─
		local milestoneNextLabel = createOwnerSignText("NEXT: RARE PACK",
			UDim2.fromScale(0.82, 0.10), UDim2.fromScale(0.09, 0.46),
			Color3.fromRGB(255, 215, 0), {
		textScaled = true, minTextSize = 12, maxTextSize = 36,
		textStrokeTransparency = 0.55, font = Enum.Font.GothamBlack,
	}, mf)

	-- ── Progress bar track (0.60 – 0.72) ──────────────────────────
	local milestoneBarBack = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 24, 40),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.84, 0.085),
		Position = UDim2.fromScale(0.08, 0.60),
	}, mf)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarBack)
	make("UIStroke", {
		Color = boardGold, Thickness = 2, Transparency = 0.45,
	}, milestoneBarBack)

	local milestoneBarFill = make("Frame", {
		BackgroundColor3 = boardGold,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	}, milestoneBarBack)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, milestoneBarFill)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 230, 80)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 170, 0)),
		}),
		Rotation = 0,
	}, milestoneBarFill)
	-- Shimmer stripe
	make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 210),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0.40, 0),
	}, milestoneBarFill)

	-- % label centred on bar
	local milestoneBarPct = createOwnerSignText("0%",
		UDim2.fromScale(1, 1), UDim2.fromScale(0, 0),
		Color3.fromRGB(255, 255, 255), {
		textScaled = true, minTextSize = 8, maxTextSize = 20,
		textStrokeTransparency = 0.50, font = Enum.Font.GothamBlack,
	}, milestoneBarBack)
	milestoneBarPct.TextXAlignment = Enum.TextXAlignment.Center

	-- ── Divider before rewards row ─────────────────────────────────
	make("Frame", {
		BackgroundColor3 = boardGold, BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.new(0.84, 0, 0, 2),
		Position = UDim2.fromScale(0.08, 0.725),
	}, mf)

	-- ── "MILESTONE REWARDS" label ──────────────────────────────────
	createOwnerSignText("MILESTONE REWARDS", UDim2.fromScale(0.70, 0.05),
		UDim2.fromScale(0.15, 0.735), Color3.fromRGB(255, 215, 0), {
		textScaled = true, minTextSize = 8, maxTextSize = 18,
		textStrokeTransparency = 0.65, font = Enum.Font.GothamBlack,
	}, mf)

	-- ── Milestone icons row (0.78 – 1.00) ─────────────────────────
	-- Evenly-spaced cards showing each repeating pity milestone.
	local iconY    = 0.785
	local iconH    = 0.195
		local iconW    = 0.118
	local iconGap  = (1 - 0.10 * 2 - iconW * #packMilestones) / (#packMilestones - 1)
	local milestoneIconFrames = {}

	for i, ms in ipairs(packMilestones) do
		local iconX = 0.10 + (i - 1) * (iconW + iconGap)
		local col   = ms.color or boardGold

		-- Card backing
		local card = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 16, 28),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(iconW, iconH),
			Position = UDim2.fromScale(iconX, iconY),
		}, mf)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
		make("UIStroke", { Color = col, Thickness = 2, Transparency = 0.30 }, card)

		-- Coloured top band
		local band = make("Frame", {
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0.38, 0),
		}, card)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, band)

		-- Star icon on band
		createOwnerSignText("\u{2605}", UDim2.fromScale(0.70, 0.38),
			UDim2.fromScale(0.15, 0), Color3.fromRGB(255, 255, 255), {
			textScaled = true, minTextSize = 8, maxTextSize = 22,
			textStrokeTransparency = 0.70, font = Enum.Font.GothamBlack,
		}, card)

		-- Threshold number
		createOwnerSignText(tostring(ms.threshold),
			UDim2.fromScale(0.80, 0.28), UDim2.fromScale(0.10, 0.38),
			Color3.fromRGB(255, 248, 220), {
			textScaled = true, minTextSize = 7, maxTextSize = 18,
			textStrokeTransparency = 0.60, font = Enum.Font.GothamBlack,
		}, card)

		-- Label at bottom
		createOwnerSignText(ms.label or "",
			UDim2.fromScale(0.90, 0.22), UDim2.fromScale(0.05, 0.72),
			col, {
			textScaled = true, minTextSize = 5, maxTextSize = 12,
			textStrokeTransparency = 0.80, font = Enum.Font.GothamBold,
		}, card)

		-- Tick overlay — hidden until claimed
		local tick = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 220, 80),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
		}, card)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, tick)
		tick.BackgroundTransparency = 0.35
		createOwnerSignText("\u{2713}", UDim2.fromScale(0.80, 0.60),
			UDim2.fromScale(0.10, 0.15), Color3.fromRGB(255, 255, 255), {
			textScaled = true, minTextSize = 10, maxTextSize = 32,
			textStrokeTransparency = 0.50, font = Enum.Font.GothamBlack,
		}, tick)

			milestoneIconFrames[i] = { card = card, tick = tick, threshold = ms.threshold, color = col }
		end

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

	local displaySlots = {}
	for slotIndex = 1, layout.DisplaySlotCount do
		local localOffset = ALL_SLOT_OFFSETS[slotIndex]
		local worldOffset = resolveDisplaySlotOffset(localOffset, facingDirection, slotIndex)
		-- Rebirth slots (7+) use a narrower pedestal (3 studs in Z instead of 5)
		-- so the gallery rows stay clean and walkable.
		local pedestalSizeZ = slotIndex > 6 and 3 or nil
		displaySlots[slotIndex] = createDisplaySlot(
			displayFolder, slotIndex,
			baseCFrame * CFrame.new(worldOffset),
			slotLookDir(localOffset, facingDirection, slotIndex),
			pedestalSizeZ
		)
	end

	-- Pathway lamps: pulled further out so the long approach is properly lit.
	-- Two pairs along the path (closer + further) instead of one pair near the gate.
	local pathLightX1 = frontEdgeX + (facingDirection * 38)
	createLightPost(model, "PathLightNorth1", position + Vector3.new(pathLightX1, 0, -6.8), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "PathLightSouth1", position + Vector3.new(pathLightX1, 0,  6.8), packPad.Position + Vector3.new(0, 2, 0))
	local pathLightX2 = frontEdgeX + (facingDirection * 64)
	createLightPost(model, "PathLightNorth2", position + Vector3.new(pathLightX2, 0, -6.8), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "PathLightSouth2", position + Vector3.new(pathLightX2, 0,  6.8), packPad.Position + Vector3.new(0, 2, 0))
	createSoftFillLight(model, "EntrancePathFill1", position + Vector3.new(pathLightX1 + (facingDirection * 2.5), 5.2, 0), 24, 0.08, Color3.fromRGB(255, 232, 180))
	createSoftFillLight(model, "EntrancePathFill2", position + Vector3.new(pathLightX2 + (facingDirection * 2.5), 5.2, 0), 24, 0.07, Color3.fromRGB(255, 232, 180))

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
	createSoftFillLight(model, "StadiumSoftFill", position + Vector3.new(0, 12, 0), 38, 0.22, Color3.fromRGB(255, 232, 184))
	createSoftFillLight(model, "BackStandFill", position + Vector3.new(backEdgeX - (facingDirection * 6), 8, 0), 30, 0.17, Color3.fromRGB(225, 234, 255))
	createSoftFillLight(model, "NorthStandFill", position + Vector3.new(0, 7, -(layout.PlotSize.Z / 2 + 7)), 25, 0.14, Color3.fromRGB(255, 226, 170))
	createSoftFillLight(model, "SouthStandFill", position + Vector3.new(0, 7, layout.PlotSize.Z / 2 + 7), 25, 0.14, Color3.fromRGB(255, 226, 170))

	-- Compact entrance trees.  The imported tree asset was too wide for the
	-- plot footprint and clipped through stands, roofs, and paths.
	local treeSpots = {
		{ x = frontEdgeX + facingDirection * 12.5, z = -(layout.PlotSize.Z / 2 + 7) },
		{ x = frontEdgeX + facingDirection * 12.5, z =  (layout.PlotSize.Z / 2 + 7) },
	}
	for index, spot in ipairs(treeSpots) do
		createCompactStadiumTree(
			model,
			"PlotEntranceTree" .. tostring(index),
			position + Vector3.new(spot.x, 0, spot.z),
			position
		)
	end

	-- ── Rebirth Machine ─────────────────────────────────────────────────────────
	-- Tucked flush against the LEFT-side wall near the entrance so it reads as
	-- planted on the wall rather than floating off to one side.
	-- (Was on the right at z=35.5; now on the opposite side, closer to the wall.)
	-- Y offsets are from baseCFrame (floor centre = local Y 0; floor top = local Y 0.5).
	local leftSideSign  = facingDirection
	local machineLocalX = facingDirection * 39
	local machineLocalZ = leftSideSign * 43
	local machineCF     = baseCFrame * CFrame.new(machineLocalX, 0.4, machineLocalZ)
	local machinePos = machineCF.Position
	local machineFacingCF = CFrame.lookAt(machinePos, Vector3.new(position.X, machinePos.Y, position.Z))
	local rebirthMachine = make("Model", {
		Name = "RebirthMachine",
	}, model)

	make("Part", {
		Name = "RebirthMachinePad",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(120, 45, 230),
		Transparency = 0.48,
		Size = Vector3.new(0.18, 11.5, 11.5),
		CFrame = CFrame.new(machinePos + Vector3.new(0, 0.62, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	}, rebirthMachine)

	make("Part", {
		Name = "RebirthBase",
		Anchored = true,
		CanCollide = true,
		CanQuery = true,
		CanTouch = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(9, 12, 24),
		Size = Vector3.new(7.4, 1.05, 7.4),
		CFrame = machineFacingCF * CFrame.new(0, 1.05, 0),
	}, rebirthMachine)

	make("Part", {
		Name = "RebirthBaseGoldLip",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 210, 58),
		Transparency = 0.34,
		Size = Vector3.new(8.0, 0.18, 8.0),
		CFrame = machineFacingCF * CFrame.new(0, 1.64, 0),
	}, rebirthMachine)

	make("Part", {
		Name = "RebirthCore",
		Anchored = true,
		CanCollide = true,
		CanQuery = true,
		CanTouch = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(16, 14, 34),
		Size = Vector3.new(3.0, 4.8, 3.0),
		CFrame = machineFacingCF * CFrame.new(0, 3.95, 0.75),
	}, rebirthMachine)

	for _, x in ipairs({ -4.05, 4.05 }) do
		make("Part", {
			Name = "RebirthSidePylon",
			Anchored = true,
			CanCollide = true,
			CanQuery = true,
			CanTouch = true,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(12, 15, 30),
			Size = Vector3.new(0.85, 6.8, 1.2),
			CFrame = machineFacingCF * CFrame.new(x, 4.35, 0),
		}, rebirthMachine)
		make("Part", {
			Name = "RebirthPylonGlow",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(176, 70, 255),
			Transparency = 0.18,
			Size = Vector3.new(0.18, 5.6, 1.34),
			CFrame = machineFacingCF * CFrame.new(x, 4.55, -0.08),
		}, rebirthMachine)
	end

	make("Part", {
		Name = "RebirthCoreCrown",
		Anchored = true,
		CanCollide = true,
		CanQuery = true,
		CanTouch = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(24, 21, 48),
		Size = Vector3.new(4.3, 0.62, 4.3),
		CFrame = machineFacingCF * CFrame.new(0, 6.68, 0.75),
	}, rebirthMachine)

	make("Part", {
		Name = "RebirthCrownGlow",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 208, 50),
		Transparency = 0.22,
		Size = Vector3.new(4.7, 0.18, 4.7),
		CFrame = machineFacingCF * CFrame.new(0, 7.08, 0.75),
	}, rebirthMachine)

	local portalCF = machineFacingCF * CFrame.new(0, 6.45, -0.62)
	local portalParts = {
		{ "RebirthPortalLeft", Vector3.new(0.34, 7.1, 0.5), CFrame.new(-3.55, 0, 0) },
		{ "RebirthPortalRight", Vector3.new(0.34, 7.1, 0.5), CFrame.new(3.55, 0, 0) },
		{ "RebirthPortalTop", Vector3.new(7.45, 0.34, 0.5), CFrame.new(0, 3.38, 0) },
		{ "RebirthPortalBottom", Vector3.new(7.45, 0.34, 0.5), CFrame.new(0, -3.38, 0) },
	}
	for _, spec in ipairs(portalParts) do
		make("Part", {
			Name = spec[1],
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(156, 70, 255),
			Transparency = 0.08,
			Size = spec[2],
			CFrame = portalCF * spec[3],
		}, rebirthMachine)
	end

	make("Part", {
		Name = "RebirthPortalWindow",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(118, 35, 255),
		Transparency = 0.72,
		Size = Vector3.new(6.45, 6.45, 0.08),
		CFrame = portalCF,
	}, rebirthMachine)

	local console = make("Part", {
		Name = "RebirthConsole",
		Anchored = true,
		CanCollide = true,
		CanQuery = true,
		CanTouch = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 14, 26),
		Size = Vector3.new(4.6, 1.35, 1.4),
		CFrame = machineFacingCF * CFrame.new(0, 2.45, -3.1) * CFrame.Angles(math.rad(-10), 0, 0),
	}, rebirthMachine)

	make("Part", {
		Name = "RebirthConsoleScreen",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 218, 70),
		Transparency = 0.18,
		Size = Vector3.new(3.65, 0.16, 0.88),
		CFrame = console.CFrame * CFrame.new(0, 0.72, -0.18),
	}, rebirthMachine)

	local machineSign = make("Part", {
		Name = "RebirthMachineSign",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 10, 20),
		Size = Vector3.new(5.2, 1.35, 0.22),
		CFrame = machineFacingCF * CFrame.new(0, 7.58, -3.0),
	}, rebirthMachine)
	local machineSignGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 90,
		LightInfluence = 0,
	}, machineSign)
	local machineSignFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(8, 10, 20),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, machineSignGui)
	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 70),
		Thickness = 2,
		Transparency = 0.1,
	}, machineSignFrame)
	createOwnerSignText("REBIRTH", UDim2.fromScale(0.9, 0.66), UDim2.fromScale(0.05, 0.06), Color3.fromRGB(255, 225, 86), {
		textScaled = true,
		minTextSize = 16,
		maxTextSize = 68,
		textStrokeTransparency = 0.45,
		font = Enum.Font.GothamBlack,
	}, machineSignFrame)
	createOwnerSignText("RESET FOR MULTIPLIER", UDim2.fromScale(0.82, 0.25), UDim2.fromScale(0.09, 0.68), Color3.fromRGB(218, 188, 255), {
		textScaled = true,
		minTextSize = 8,
		maxTextSize = 26,
		textStrokeTransparency = 0.7,
		font = Enum.Font.GothamBold,
	}, machineSignFrame)

	local rebirthOrb = make("Part", {
		Name = "RebirthOrb",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(198, 128, 255),
		Transparency = 0.04,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.15, 2.15, 2.15),
		CFrame = portalCF * CFrame.new(0, 0, -0.12),
	}, rebirthMachine)

	make("PointLight", {
		Brightness = 3.5,
		Range = 28,
		Color = Color3.fromRGB(160, 76, 255),
	}, rebirthOrb)

	local orbAttachment = make("Attachment", {
		Name = "RebirthOrbAttachment",
	}, rebirthOrb)
	local orbParticles = make("ParticleEmitter", {
		Name = "RebirthEnergy",
		Enabled = true,
		Rate = 16,
		Lifetime = NumberRange.new(0.6, 1.15),
		Speed = NumberRange.new(0.35, 1.2),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 1.5,
		LightEmission = 1,
		LightInfluence = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 160)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(180, 86, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(108, 220, 255)),
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.16),
			NumberSequenceKeypoint.new(0.55, 0.38),
			NumberSequenceKeypoint.new(1, 0.02),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.7, 0.28),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, orbAttachment)
	_ = orbParticles

	local spinBandA = make("Part", {
		Name = "RebirthSpinBandA",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 218, 70),
		Transparency = 0.18,
		Size = Vector3.new(4.4, 0.16, 0.16),
		CFrame = rebirthOrb.CFrame,
	}, rebirthMachine)
	local spinBandB = make("Part", {
		Name = "RebirthSpinBandB",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(108, 220, 255),
		Transparency = 0.18,
		Size = Vector3.new(0.16, 4.4, 0.16),
		CFrame = rebirthOrb.CFrame,
	}, rebirthMachine)

	task.spawn(function()
		local spin = 0
		while rebirthMachine.Parent do
			spin += math.rad(2.3)
			local orbCF = portalCF * CFrame.new(0, math.sin(os.clock() * 1.15) * 0.15, -0.12)
			rebirthOrb.CFrame = orbCF
			spinBandA.CFrame = orbCF * CFrame.Angles(0, spin, math.rad(18))
			spinBandB.CFrame = orbCF * CFrame.Angles(spin * 0.85, 0, math.rad(90))
			task.wait(0.04)
		end
	end)

	assignCollisionGroup(rebirthMachine, COLLISION_GROUPS.Props)
	createCollisionBlocker(
		rebirthMachine,
		"RebirthMachineCollisionBlocker",
		Vector3.new(8.6, 8.6, 4.2),
		machineFacingCF * CFrame.new(0, 4.3, -0.25),
		COLLISION_GROUPS.Props
	)

	local rebirthPrompt = make("ProximityPrompt", {
		ActionText            = "Rebirth",
		ObjectText            = "Rebirth Machine",
		KeyboardKeyCode       = Enum.KeyCode.E,
		HoldDuration          = 0.6,
		MaxActivationDistance = 12,
		RequiresLineOfSight   = false,
		Style                 = Enum.ProximityPromptStyle.Default,
	}, rebirthOrb)

	-- ── Rebirth Vault ──────────────────────────────────────────────────────────
	local vaultCF = machineFacingCF * CFrame.new(7.6, 0, -0.35)
	local vaultModel = make("Model", {
		Name = "RebirthVault",
	}, model)

	make("Part", {
		Name = "RebirthVaultPad",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(75, 190, 255),
		Transparency = 0.52,
		Size = Vector3.new(5.6, 0.16, 5.6),
		CFrame = vaultCF * CFrame.new(0, 0.66, 0),
	}, vaultModel)

	make("Part", {
		Name = "RebirthVaultBase",
		Anchored = true,
		CanCollide = true,
		CanQuery = true,
		CanTouch = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 14, 28),
		Size = Vector3.new(4.6, 1.15, 4.6),
		CFrame = vaultCF * CFrame.new(0, 1.08, 0),
	}, vaultModel)

	local vaultCore = make("Part", {
		Name = "RebirthVaultCore",
		Anchored = true,
		CanCollide = true,
		CanQuery = true,
		CanTouch = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(10, 20, 42),
		Size = Vector3.new(3.2, 3.8, 2.0),
		CFrame = vaultCF * CFrame.new(0, 3.12, 0),
	}, vaultModel)

	make("Part", {
		Name = "RebirthVaultDoorGlow",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(80, 220, 255),
		Transparency = 0.12,
		Size = Vector3.new(2.45, 2.95, 0.12),
		CFrame = vaultCF * CFrame.new(0, 3.16, -1.04),
	}, vaultModel)

	local vaultSign = make("Part", {
		Name = "RebirthVaultSign",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(6, 9, 18),
		Size = Vector3.new(4.8, 1.15, 0.18),
		CFrame = vaultCF * CFrame.new(0, 5.72, -1.35),
	}, vaultModel)
	local vaultSignGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 90,
		LightInfluence = 0,
	}, vaultSign)
	local vaultSignFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(6, 9, 18),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, vaultSignGui)
	make("UIStroke", {
		Color = Color3.fromRGB(98, 220, 255),
		Thickness = 2,
		Transparency = 0.08,
	}, vaultSignFrame)
	createOwnerSignText("VAULT", UDim2.fromScale(0.9, 0.58), UDim2.fromScale(0.05, 0.07), Color3.fromRGB(170, 245, 255), {
		textScaled = true,
		minTextSize = 16,
		maxTextSize = 62,
		textStrokeTransparency = 0.45,
		font = Enum.Font.GothamBlack,
	}, vaultSignFrame)
	createOwnerSignText("KEEP PLAYERS", UDim2.fromScale(0.82, 0.25), UDim2.fromScale(0.09, 0.66), Color3.fromRGB(230, 245, 255), {
		textScaled = true,
		minTextSize = 8,
		maxTextSize = 24,
		textStrokeTransparency = 0.7,
		font = Enum.Font.GothamBold,
	}, vaultSignFrame)

	make("PointLight", {
		Brightness = 1.9,
		Range = 20,
		Color = Color3.fromRGB(80, 220, 255),
	}, vaultCore)

	assignCollisionGroup(vaultModel, COLLISION_GROUPS.Props)

	local rebirthVaultPrompt = make("ProximityPrompt", {
		ActionText            = "Open Vault",
		ObjectText            = "Rebirth Vault",
		KeyboardKeyCode       = Enum.KeyCode.E,
		HoldDuration          = 0.35,
		MaxActivationDistance = 11,
		RequiresLineOfSight   = false,
		Style                 = Enum.ProximityPromptStyle.Default,
	}, vaultCore)

	-- Folder for visuals that change per rebirth tier (seats, lighting, etc.)
	local stadiumExtrasFolder = make("Folder", { Name = "StadiumExtras" }, model)

	-- ── Stadium floodlight towers (4 corners) ─────────────────────────────────
	local floodlightFolder = make("Folder", { Name = "Floodlights" }, model)
	for _, offset in ipairs({ Vector3.new(44, 0, 44), Vector3.new(44, 0, -44), Vector3.new(-44, 0, 44), Vector3.new(-44, 0, -44) }) do
		local towerBase = position + offset
		make("Part", {
			Name = "FloodlightBase",
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(24, 30, 42),
			Size = Vector3.new(1.8, 0.6, 1.8),
			CFrame = CFrame.new(towerBase + Vector3.new(0, 0.3, 0)),
		}, floodlightFolder)
		local pole = make("Part", {
			Name = "FloodlightPole",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(32, 38, 52),
			Size = Vector3.new(0.9, 22, 0.9),
			CFrame = CFrame.new(towerBase + Vector3.new(0, 11.6, 0)),
		}, floodlightFolder)
		make("Part", {
			Name = "FloodlightHead",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(18, 22, 32),
			Size = Vector3.new(4.2, 1.0, 2.2),
			CFrame = CFrame.new(towerBase + Vector3.new(0, 23.1, 0)),
		}, floodlightFolder)
		make("Part", {
			Name = "FloodlightLens",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 242, 210),
			Transparency = 0.28,
			Size = Vector3.new(3.6, 0.4, 1.6),
			CFrame = CFrame.new(towerBase + Vector3.new(0, 22.7, 0)),
		}, floodlightFolder)
		make("SpotLight", {
			Brightness = 7,
			Range = 80,
			Angle = 58,
			Face = Enum.NormalId.Bottom,
			Color = Color3.fromRGB(255, 248, 224),
			Shadows = false,
		}, pole)
		make("PointLight", {
			Brightness = 1.4,
			Range = 32,
			Color = Color3.fromRGB(255, 240, 200),
			Shadows = false,
		}, pole)
	end

	local plot = {
		id = plotId,
		side = side,
		laneIndex = laneIndex,
		model = model,
		baseCFrame = baseCFrame,
		facingDirection = facingDirection,
		starterStadiumFolder = starterStadiumFolder,
		stadiumExtrasFolder = stadiumExtrasFolder,
		floor = floor,
		packPad = packPad,
		spawnPad = spawnPad,
		spawnLocation = spawnLocation,
		ownerSign = ownerSign,
		ownerTopLabel = ownerTopLabel,
		ownerNameLabel = ownerNameLabel,
		ownerSubtitleLabel = ownerSubtitleLabel,
		rebirthMultiplierGui = multiplierGui,
		rebirthMultiplierLabel = rebirthMultiplierLabel,
		milestoneSign = milestoneSign,
		milestonePacksLabel = milestonePacksLabel,
			milestoneNextLabel = milestoneNextLabel,
			milestoneBarFill = milestoneBarFill,
			milestoneBarPct = milestoneBarPct,
			milestoneLight = milestoneLight,
			milestoneIconFrames = milestoneIconFrames,
		padTitleLabel = padTitleLabel,
		padSubtitleLabel = padSubtitleLabel,
		padAccent = padAccent,
		padGui = padGui,
		padBarBack = padBarBack,
		padBarFill = padBarFill,
		displaySlots = displaySlots,
		spawnCFrame = spawnCFrame,
		rebirthPrompt = rebirthPrompt,
		rebirthVaultPrompt = rebirthVaultPrompt,
	}

	updateOwnerSign(plot, nil, "")
	updatePadLabel(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))

	return plot
end

-- Called when a player is assigned a plot or completes a rebirth.
-- Rebuilds the lightweight extras that sit around the concept stadium shell:
-- crowd route points for the built-in red stands, and the back-wall rebirth
-- gallery that supports slots 7-18 without cluttering the pitch.
function BaseService.UpdateStadiumTier(plot, tier)
	if not plot or not plot.stadiumExtrasFolder then return end
	tier = tier or 0

	-- Clear whatever was there before
	for _, child in ipairs(plot.stadiumExtrasFolder:GetChildren()) do
		child:Destroy()
	end
	plot.crowdSeatPoints = {}
	plot.crowdPathHelpers = {}
	setModelVisibleAndSolid(plot.starterStadiumFolder, tier < 1)

	if tier < 1 then
		return
	end

	local parent = plot.stadiumExtrasFolder
	local pitchPos = plot.baseCFrame.Position
	local fd = plot.facingDirection
	local floorY = pitchPos.Y + layout.PlotSize.Y / 2
	local conceptPitchX = 64
	local conceptPitchZ = 48
	local seatRowWidth = 50
	local seatRowDepth = 2.6
	local seatRowRise = 1.5
	local pitchSeatGap = 3.2
	local crowdPivotY = 3.1
	local seatPointsFolder = make("Folder", { Name = "CrowdSeatPoints" }, parent)
	local frontAisleX = pitchPos.X + fd * 34
	local northAisleZ = pitchPos.Z - (conceptPitchZ / 2 + 5.2)
	local southAisleZ = pitchPos.Z + (conceptPitchZ / 2 + 5.2)

	local function createFanAisle(name, size, cframe)
		make("Part", {
			Name = name,
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(44, 52, 68),
			Transparency = 1,
			Size = size,
			CFrame = cframe,
		}, parent)
	end

	createFanAisle(
		"FanAisleNorth",
		Vector3.new(conceptPitchX + 8, 0.14, 4.2),
		CFrame.new(pitchPos.X, floorY + 0.07, northAisleZ)
	)
	createFanAisle(
		"FanAisleSouth",
		Vector3.new(conceptPitchX + 8, 0.14, 4.2),
		CFrame.new(pitchPos.X, floorY + 0.07, southAisleZ)
	)

	local function makeSeatRoutePoints(standName, seatX, seatIndex, row)
		local sideAisleZ = standName == "North" and northAisleZ or southAisleZ
		local gateLaneZ = pitchPos.Z + (standName == "North" and -5.5 or 5.5)
			+ (((seatIndex or 1) - 3.5) * 0.55)
			+ (((row or 1) - 1) * 0.18)
		return {
			Vector3.new(frontAisleX, crowdPivotY, gateLaneZ),
			Vector3.new(frontAisleX, crowdPivotY, sideAisleZ),
			Vector3.new(seatX, crowdPivotY, sideAisleZ),
		}
	end

	local function createCrowdSeatPoint(standName, row, seatIndex, sitPosition, lookDirection, approachPosition, routePoints)
		local flatLook = Vector3.new(lookDirection.X, 0, lookDirection.Z)
		if flatLook.Magnitude < 0.05 then
			flatLook = Vector3.new(fd, 0, 0)
		else
			flatLook = flatLook.Unit
		end

		local sitCFrame = CFrame.lookAt(sitPosition, sitPosition + flatLook)
		local point = make("Part", {
			Name = string.format("SeatPoint_%s_%02d_%02d", standName, row, seatIndex),
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Transparency = 1,
			Size = Vector3.new(1, 1, 1),
			CFrame = sitCFrame,
		}, seatPointsFolder)

		point:SetAttribute("Occupied", false)
		point:SetAttribute("SitPosition", sitPosition)
		point:SetAttribute("LookDirection", flatLook)
		point:SetAttribute("ApproachPosition", approachPosition)
		point:SetAttribute("StandName", standName)
		point:SetAttribute("SeatRow", row)

		table.insert(plot.crowdSeatPoints, {
			point = point,
			sitCFrame = sitCFrame,
			approachPosition = approachPosition,
			lookAt = pitchPos,
			standName = standName,
			row = row,
			seatIndex = seatIndex,
			routePoints = routePoints,
		})
	end

	local function addConceptStandSeats(standName, zSign, lookDirection)
		local rowCount = math.min(1 + tier, 5)
		local seatsInRow = 6
		for row = 1, rowCount do
			local topLocalY = 1 + 0.6 + ((row - 1) * seatRowRise) + seatRowRise
			local localZ = zSign * ((conceptPitchZ / 2 + pitchSeatGap) + ((row - 0.5) * seatRowDepth))
			for seatIndex = 1, seatsInRow do
				local localX = -seatRowWidth / 2 + (seatRowWidth / (seatsInRow + 1)) * seatIndex
				local seatWorld = (plot.baseCFrame * CFrame.new(localX, topLocalY + 1.05, localZ)).Position
				local approachZ = standName == "North" and northAisleZ or southAisleZ
				local approachPosition = Vector3.new(seatWorld.X, crowdPivotY, approachZ)
					createCrowdSeatPoint(
						standName,
						row,
						seatIndex,
						seatWorld,
						lookDirection,
						approachPosition,
						makeSeatRoutePoints(standName, seatWorld.X, seatIndex, row)
					)
			end
		end
	end

	addConceptStandSeats("North", -1, Vector3.new(0, 0, 1))
	addConceptStandSeats("South", 1, Vector3.new(0, 0, -1))

	local wing = make("Model", { Name = "RebirthGallery" }, parent)
	local gold = Color3.fromRGB(255, 210, 58)
	local wingColor = Color3.fromRGB(12, 17, 28)
	local railColor = Color3.fromRGB(25, 32, 48)
	local galleryCFrame = plot.baseCFrame * CFrame.new(-40.5 * fd, 1.18, 0)

	configureCollisionPart(make("Part", {
		Name = "RebirthGalleryDeck",
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Material = Enum.Material.SmoothPlastic,
		Color = wingColor,
		Size = Vector3.new(17, 0.5, 62),
		CFrame = galleryCFrame,
	}, wing), COLLISION_GROUPS.StadiumGeometry, true, true, true)

	for _, xOffset in ipairs({ -8.8, 8.8 }) do
		make("Part", {
			Name = "RebirthGalleryGoldEdge",
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Material = Enum.Material.Neon,
			Color = gold,
			Transparency = 0.28,
			Size = Vector3.new(0.16, 0.12, 62.4),
			CFrame = galleryCFrame * CFrame.new(xOffset, 0.33, 0),
		}, wing)
	end

	for _, zOffset in ipairs({ -31.2, 31.2 }) do
		make("Part", {
			Name = "RebirthGallerySideRail",
			Anchored = true,
			CanCollide = true,
			CanTouch = true,
			CanQuery = true,
			Material = Enum.Material.SmoothPlastic,
			Color = railColor,
			Size = Vector3.new(17.4, 1.6, 0.55),
			CFrame = galleryCFrame * CFrame.new(0, 1.0, zOffset),
		}, wing)
	end

	make("Part", {
		Name = "RebirthGalleryBackRail",
		Anchored = true,
		CanCollide = true,
		CanTouch = true,
		CanQuery = true,
		Material = Enum.Material.SmoothPlastic,
		Color = railColor,
		Size = Vector3.new(0.55, 1.8, 62.4),
		CFrame = galleryCFrame * CFrame.new(-8.8 * fd, 1.1, 0),
	}, wing)

	local signPosition = (plot.baseCFrame * CFrame.new(-49.6 * fd, 4.1, 0)).Position
	local signLook = Vector3.new(pitchPos.X, signPosition.Y, pitchPos.Z)
	local wingSign = make("Part", {
		Name = "RebirthGallerySign",
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(7, 10, 18),
		Size = Vector3.new(12, 1.9, 0.24),
		CFrame = CFrame.lookAt(signPosition, signLook),
	}, wing)
	local signGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 70,
		LightInfluence = 0,
	}, wingSign)
	local signFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, signGui)
	make("UIStroke", { Color = gold, Thickness = 2, Transparency = 0.15 }, signFrame)
	createOwnerSignText("REBIRTH", UDim2.fromScale(0.9, 0.43), UDim2.fromScale(0.05, 0.08), gold, {
		textScaled = true,
		minTextSize = 14,
		maxTextSize = 56,
		textStrokeTransparency = 0.45,
		font = Enum.Font.GothamBlack,
	}, signFrame)
	createOwnerSignText("GALLERY SLOTS", UDim2.fromScale(0.86, 0.32), UDim2.fromScale(0.07, 0.56), Color3.fromRGB(235, 228, 210), {
		textScaled = true,
		minTextSize = 8,
		maxTextSize = 24,
		textStrokeTransparency = 0.7,
		font = Enum.Font.GothamBold,
	}, signFrame)

	assignCollisionGroup(wing, COLLISION_GROUPS.StadiumGeometry)

	-- ── Rebirth Terrace — appears at tier 5 (rebirth 5 = slot 11 unlocks) ──────
	-- Elevated deck above the ground gallery at the same X centre.
	-- Slots 11-18 in ALL_SLOT_OFFSETS are at Y=17.75 to sit on this surface.
	if tier >= 5 then
		local terrace   = make("Model", { Name = "RebirthTerrace" }, parent)
		local tGold     = Color3.fromRGB(255, 210, 58)
		local tDeckCol  = Color3.fromRGB(12, 17, 28)
		local tRailCol  = Color3.fromRGB(25, 32, 48)
		local tStepCol  = Color3.fromRGB(18, 24, 35)

		local deckCenterLocalY = 15.72   -- deck centre Y offset from baseCFrame
		local deckSizeX        = 17
		local deckSizeZ        = 54
		local deckHalfX        = deckSizeX / 2   -- 8.5
		local deckHalfZ        = deckSizeZ / 2   -- 27

		local terraceCFrame = plot.baseCFrame * CFrame.new(-40.5 * fd, deckCenterLocalY, 0)

		-- Walking surface
		configureCollisionPart(make("Part", {
			Name = "RebirthTerraceDeck",
			Anchored = true, CanCollide = true, CanTouch = true, CanQuery = true,
			Material = Enum.Material.SmoothPlastic, Color = tDeckCol,
			Size = Vector3.new(deckSizeX, 0.5, deckSizeZ),
			CFrame = terraceCFrame,
		}, terrace), COLLISION_GROUPS.StadiumGeometry, true, true, true)

		-- Neon gold trim along the pitch-facing front edge
		make("Part", {
			Name = "RebirthTerraceFrontGlow",
			Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
			Material = Enum.Material.Neon, Color = tGold, Transparency = 0.35,
			Size = Vector3.new(0.18, 0.1, deckSizeZ - 2),
			CFrame = terraceCFrame * CFrame.new(deckHalfX * fd, 0.33, 0),
		}, terrace)

		-- Back rail (away from pitch)
		configureCollisionPart(make("Part", {
			Name = "RebirthTerraceBackRail",
			Anchored = true, CanCollide = true, CanTouch = true, CanQuery = true,
			Material = Enum.Material.SmoothPlastic, Color = tRailCol,
			Size = Vector3.new(0.55, 1.8, deckSizeZ + 0.6),
			CFrame = terraceCFrame * CFrame.new(-deckHalfX * fd, 1.1, 0),
		}, terrace), COLLISION_GROUPS.StadiumGeometry, true, true, true)

		-- North and south side rails
		for _, zSign in ipairs({-1, 1}) do
			configureCollisionPart(make("Part", {
				Name = "RebirthTerraceSideRail",
				Anchored = true, CanCollide = true, CanTouch = true, CanQuery = true,
				Material = Enum.Material.SmoothPlastic, Color = tRailCol,
				Size = Vector3.new(deckSizeX + 0.6, 1.6, 0.55),
				CFrame = terraceCFrame * CFrame.new(0, 1.05, zSign * (deckHalfZ + 0.3)),
			}, terrace), COLLISION_GROUPS.StadiumGeometry, true, true, true)
		end

		-- ── Teleporter pads — step on to travel between ground and terrace ──────
		-- Ground pad: 5 studs in front of the terrace deck face, centre of Z.
		-- Terrace pad: centre of the terrace deck surface.
		local deckTopLocalY   = deckCenterLocalY + 0.25   -- 15.97
		local deckFrontLocalX = fd * (-40.5 + deckHalfX)  -- -32*fd

		-- Player HumanoidRootPart lands ~3.5 studs above the destination floor surface.
		-- Gallery deck top = 1.43; terrace deck top = deckTopLocalY (15.97).
		local galleryDeckTop = 1.43
		local groundArrivalCFrame  = plot.baseCFrame * CFrame.new(deckFrontLocalX - fd * 2, galleryDeckTop + 3.5, 0)
		local terraceArrivalCFrame = plot.baseCFrame * CFrame.new(-40.5 * fd, deckTopLocalY + 3.5, 0)

		local padSize = Vector3.new(5, 0.4, 5)
		local padCol  = Color3.fromRGB(10, 14, 24)

		local function makePad(name, localX, localY, localZ, labelText)
			local padCFrame = plot.baseCFrame * CFrame.new(localX, localY, localZ)
			local pad = make("Part", {
				Name = name,
				Anchored = true, CanCollide = true, CanTouch = true, CanQuery = true,
				Material = Enum.Material.SmoothPlastic, Color = padCol,
				Size = padSize,
				CFrame = padCFrame,
			}, terrace)
			-- Gold neon border strip around the top edge
			for _, edge in ipairs({
				{ sz = Vector3.new(padSize.X, 0.12, 0.18), dz =  padSize.Z / 2 },
				{ sz = Vector3.new(padSize.X, 0.12, 0.18), dz = -padSize.Z / 2 },
				{ sz = Vector3.new(0.18, 0.12, padSize.Z), dx =  padSize.X / 2 },
				{ sz = Vector3.new(0.18, 0.12, padSize.Z), dx = -padSize.X / 2 },
			}) do
				make("Part", {
					Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
					Material = Enum.Material.Neon, Color = tGold, Transparency = 0.2,
					Size = edge.sz,
					CFrame = padCFrame * CFrame.new(edge.dx or 0, padSize.Y / 2 + 0.06, edge.dz or 0),
				}, terrace)
			end
			-- Label on the top face
			local gui = make("SurfaceGui", {
				Name = "TeleportLabel",
				Face = Enum.NormalId.Top,
				LightInfluence = 0,
				SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
				PixelsPerStud = 50,
			}, pad)
			make("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = labelText,
				TextColor3 = tGold,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
				TextStrokeTransparency = 0.4,
			}, gui)
			return pad
		end

		-- Ground pad sits ON the gallery deck surface (deck top = 1.43 above baseCFrame).
		-- Place it 2 studs inside the front edge so players encounter it while browsing slots.
		local galleryDeckTopLocalY = 1.43   -- galleryCFrame Y (1.18) + deck halfThick (0.25)
		local groundPadLocalX = deckFrontLocalX - fd * 2   -- 2 studs inside front edge
		local groundPadLocalY = galleryDeckTopLocalY + 0.2  -- pad centre on gallery deck surface
		local groundPad  = makePad("TerraceLiftGround",  groundPadLocalX, groundPadLocalY, 0, "▲ TERRACE")
		local terracePad = makePad("TerraceLiftUp",       -40.5 * fd,     deckTopLocalY + 0.2, 0, "▼ GROUND")

		-- Beacon pole above the ground pad so players can spot it from across the stadium
		local beaconHeight = 8
		local beaconCFrame = plot.baseCFrame * CFrame.new(groundPadLocalX, groundPadLocalY + beaconHeight / 2 + 0.2, 0)
		make("Part", {
			Name = "TerraceLiftBeacon",
			Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
			Material = Enum.Material.Neon, Color = tGold, Transparency = 0.15,
			Size = Vector3.new(0.3, beaconHeight, 0.3),
			CFrame = beaconCFrame,
		}, terrace)
		-- Arrow billboard at the top of the beacon
		local arrowPart = make("Part", {
			Name = "TerraceLiftArrowBase",
			Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
			Transparency = 1, Size = Vector3.new(1, 1, 1),
			CFrame = plot.baseCFrame * CFrame.new(groundPadLocalX, groundPadLocalY + beaconHeight + 1.5, 0),
		}, terrace)
		local bb = make("BillboardGui", {
			Name = "TerraceLiftBB",
			Size = UDim2.fromOffset(80, 80),
			StudsOffset = Vector3.new(0, 0, 0),
			AlwaysOnTop = false,
			LightInfluence = 0,
		}, arrowPart)
		make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "▲",
			TextColor3 = tGold,
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, bb)

		-- Debounce table: prevents repeated teleports from a single step.
		local Players = game:GetService("Players")
		local debounce = {}

		local function doTeleport(hit, destination)
			local char = hit.Parent
			if not char or debounce[char] then return end
			local player = Players:GetPlayerFromCharacter(char)
			if not player then return end
			local hum  = char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			debounce[char] = true
			root.CFrame = destination
			task.delay(2, function() debounce[char] = nil end)
		end

		groundPad.Touched:Connect(function(hit)  doTeleport(hit, terraceArrivalCFrame) end)
		terracePad.Touched:Connect(function(hit) doTeleport(hit, groundArrivalCFrame)  end)

		assignCollisionGroup(terrace, COLLISION_GROUPS.StadiumGeometry)
	end
end

function BaseService.SetupCollisionGroups()
	setupCollisionGroups()
end

function BaseService.SetCollisionGroup(root, groupName)
	assignCollisionGroup(root, groupName)
end

function BaseService.GetCollisionGroupName(key)
	return COLLISION_GROUPS[key]
end

function BaseService.ConfigurePlayerCharacterCollision(character)
	if not character then
		return
	end

	assignCollisionGroup(character, COLLISION_GROUPS.Players)
	if character:GetAttribute("CollisionGroupWired") then
		return
	end

	character:SetAttribute("CollisionGroupWired", true)
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			setPartCollisionGroup(descendant, COLLISION_GROUPS.Players)
		end
	end)
end

function BaseService.ReserveCrowdSeat(plot)
	if not plot or not plot.crowdSeatPoints or #plot.crowdSeatPoints == 0 then
		return nil
	end

	local available = {}
	for _, seat in ipairs(plot.crowdSeatPoints) do
		local point = seat.point
		if point and point.Parent and not seat.reserved and point:GetAttribute("Occupied") ~= true then
			table.insert(available, seat)
		end
	end

	if #available == 0 then
		return nil
	end

	local seat = available[math.random(1, #available)]
	seat.reserved = true
	if seat.point and seat.point.Parent then
		seat.point:SetAttribute("Occupied", true)
	end
	return seat
end

function BaseService.ReleaseCrowdSeat(seat)
	if not seat then
		return
	end

	seat.reserved = nil
	if seat.point and seat.point.Parent then
		seat.point:SetAttribute("Occupied", false)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Concept Test Stadium: premium standalone visual sandbox.
-- Iterates on layered walls, tunnel entrance, tiled flooring, raised podium,
-- premium lighting and decorative props without touching gameplay.
-- ─────────────────────────────────────────────────────────────────────────────
createConceptTestStadium = function(parent, position, options)
	options = options or {}
	local model = make("Model", { Name = options.name or "ConceptTestStadium" }, parent)
	local facingDirection = options.facingDirection or 1
	local baseCFrame = CFrame.new(position)
	if facingDirection < 0 then
		baseCFrame = baseCFrame * CFrame.Angles(0, math.rad(180), 0)
	end
	local includeCenterPad = options.includeCenterPad ~= false
	local includeDisplaySlots = options.includeDisplaySlots ~= false
	local includeEntranceSign = options.includeEntranceSign ~= false

	-- ── Constants ───────────────────────────────────────────────────────────
	local size      = 100         -- overall outer footprint (octagon bounding)
	local pitchW    = 64          -- fills more of the open interior between walls
	local pitchD    = 48          -- fills the blank apron between the stands
	local pitchSeatGap = 3.2      -- small apron before the first bleacher row
	local wallH     = 14
	local wallT     = 3.0         -- thicker premium walls
	local floorH    = 1
	local stoneDark = Color3.fromRGB(32, 36, 46)
	local stoneMid  = Color3.fromRGB(42, 48, 58)
	local stoneLite = Color3.fromRGB(64, 72, 86)
	local goldCol   = Color3.fromRGB(255, 210, 0)
	local pitchCol  = Color3.fromRGB(56, 132, 60)
	local pitchEdge = Color3.fromRGB(72, 156, 76)
	local redSeat   = Color3.fromRGB(190, 38, 38)
	local redSeatLo = Color3.fromRGB(145, 28, 28)
	local redAccent = Color3.fromRGB(255, 58, 42)
	local lineCol   = Color3.fromRGB(246, 246, 236)

	-- ── Tiered tile floor with neon edge strips ─────────────────────────────
	make("Part", {
		Name = "OuterFloor", Anchored = true,
		Material = Enum.Material.Slate, Color = stoneDark,
		Size = Vector3.new(size + 6, floorH, size + 6),
		CFrame = baseCFrame * CFrame.new(0, floorH / 2 - 0.05, 0),
	}, model)
	make("Part", {
		Name = "InnerFloor", Anchored = true,
		Material = Enum.Material.SmoothPlastic, Color = stoneMid,
		Size = Vector3.new(size - 6, floorH * 0.9, size - 6),
		CFrame = baseCFrame * CFrame.new(0, floorH / 2 + 0.04, 0),
	}, model)
	-- Subtle gold edge strip along inner floor border (toned down)
	for _, dz in ipairs({-1, 1}) do
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.22,
			Size = Vector3.new(size - 6, 0.04, 0.3),
			CFrame = baseCFrame * CFrame.new(0, floorH + 0.06, dz * (size / 2 - 4)),
		}, model)
	end
	for _, dx in ipairs({-1, 1}) do
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.22,
			Size = Vector3.new(0.3, 0.04, size - 6),
			CFrame = baseCFrame * CFrame.new(dx * (size / 2 - 4), floorH + 0.06, 0),
		}, model)
	end
	-- Pathway from entrance to podium (lighter tile, no neon glow)
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.SmoothPlastic, Color = stoneLite,
		Size = Vector3.new(8, 0.05, size - 12),
		CFrame = baseCFrame * CFrame.new(0, floorH + 0.06, 0),
	}, model)
	for _, dz in ipairs({-1, 1}) do
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.25,
			Size = Vector3.new(0.18, 0.04, size - 12),
			CFrame = baseCFrame * CFrame.new(dz * 4, floorH + 0.07, 0),
		}, model)
	end

	-- ── Concrete walkways forming a perimeter ring inside the arena ─────────
	-- Raised slightly so they read as a walkway level, with subtle gold edge trim
	local walkwayY = floorH + 0.12
	local walkwayWidth = 2
	local walkwayInset = pitchW / 2 + 2.4
	-- North walkway (in front of north bleachers)
	make("Part", {
		Name = "WalkwayNorth", Anchored = true, CanCollide = false,
		Material = Enum.Material.Concrete, Color = stoneLite,
		Size = Vector3.new(pitchW + 4, 0.18, walkwayWidth),
		CFrame = baseCFrame * CFrame.new(0, walkwayY, -pitchD / 2 - walkwayWidth / 2 - 0.7),
	}, model)
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.28,
		Size = Vector3.new(pitchW + 4, 0.06, 0.22),
		CFrame = baseCFrame * CFrame.new(0, walkwayY + 0.13, -pitchD / 2 - walkwayWidth - 0.7),
	}, model)
	-- South walkway
	make("Part", {
		Name = "WalkwaySouth", Anchored = true, CanCollide = false,
		Material = Enum.Material.Concrete, Color = stoneLite,
		Size = Vector3.new(pitchW + 4, 0.18, walkwayWidth),
		CFrame = baseCFrame * CFrame.new(0, walkwayY, pitchD / 2 + walkwayWidth / 2 + 0.7),
	}, model)
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.28,
		Size = Vector3.new(pitchW + 4, 0.06, 0.22),
		CFrame = baseCFrame * CFrame.new(0, walkwayY + 0.13, pitchD / 2 + walkwayWidth + 0.7),
	}, model)
	-- West walkway (back of stadium)
	make("Part", {
		Name = "WalkwayWest", Anchored = true, CanCollide = false,
		Material = Enum.Material.Concrete, Color = stoneLite,
		Size = Vector3.new(walkwayWidth, 0.18, pitchD + walkwayWidth * 2 + 2),
		CFrame = baseCFrame * CFrame.new(-walkwayInset, walkwayY, 0),
	}, model)
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.28,
		Size = Vector3.new(0.22, 0.06, pitchD + walkwayWidth * 2 + 2),
		CFrame = baseCFrame * CFrame.new(-walkwayInset - walkwayWidth / 2, walkwayY + 0.13, 0),
	}, model)
	-- East entry apron: this is the future NPC/player split point after the main gate.
	make("Part", {
		Name = "WalkwayEastEntry", Anchored = true, CanCollide = false,
		Material = Enum.Material.Concrete, Color = stoneLite,
		Size = Vector3.new(walkwayWidth, 0.18, pitchD + walkwayWidth * 2 + 2),
		CFrame = baseCFrame * CFrame.new(walkwayInset, walkwayY, 0),
	}, model)
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.28,
		Size = Vector3.new(0.22, 0.06, pitchD + walkwayWidth * 2 + 2),
		CFrame = baseCFrame * CFrame.new(walkwayInset + walkwayWidth / 2, walkwayY + 0.13, 0),
	}, model)
	for _, zSign in ipairs({-1, 1}) do
		make("Part", {
			Name = "FanRouteArrow", Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.25,
			Size = Vector3.new(2.1, 0.08, 0.28),
			CFrame = baseCFrame * CFrame.new(walkwayInset, walkwayY + 0.17, zSign * 12) * CFrame.Angles(0, math.rad(zSign > 0 and 45 or -45), 0),
		}, model)
		make("Part", {
			Name = "FanRouteArrowHead", Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.25,
			Size = Vector3.new(1.1, 0.08, 0.28),
			CFrame = baseCFrame * CFrame.new(walkwayInset - 0.9, walkwayY + 0.18, zSign * (12 + 0.9)) * CFrame.Angles(0, math.rad(zSign > 0 and 135 or -135), 0),
		}, model)
	end
	-- Pitch-side barrier railings (low metal posts every few studs)
	for _, dz in ipairs({-1, 1}) do
		for railX = -pitchW / 2 + 2, pitchW / 2 - 2, 4 do
			-- Railing posts
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 65, 75),
				Size = Vector3.new(0.3, 1.2, 0.3),
				CFrame = baseCFrame * CFrame.new(railX, floorH + 0.6, dz * (pitchD / 2 + 1)),
			}, model)
		end
		-- Horizontal rail
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 75, 85),
			Size = Vector3.new(pitchW - 2, 0.18, 0.18),
			CFrame = baseCFrame * CFrame.new(0, floorH + 1.1, dz * (pitchD / 2 + 1)),
		}, model)
	end

	-- ── Central pitch with full markings ────────────────────────────────────
	local pitchY = floorH + 0.05
	-- Pitch border (slightly raised, slightly darker green)
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.Grass, Color = pitchEdge,
		Size = Vector3.new(pitchW + 1.4, 0.08, pitchD + 1.4),
		CFrame = baseCFrame * CFrame.new(0, pitchY, 0),
	}, model)
	make("Part", {
		Name = "Pitch", Anchored = true, CanCollide = false,
		Material = Enum.Material.Grass, Color = pitchCol,
		Size = Vector3.new(pitchW, 0.1, pitchD),
		CFrame = baseCFrame * CFrame.new(0, pitchY + 0.02, 0),
	}, model)
	local pitchFillAnchor = make("Part", {
		Name = "PitchFillLightAnchor",
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CFrame = baseCFrame * CFrame.new(0, floorH + 8, 0),
	}, model)
	make("PointLight", {
		Brightness = 0.42,
		Range = 44,
		Color = Color3.fromRGB(238, 246, 220),
		Shadows = false,
	}, pitchFillAnchor)
	-- Helper for pitch lines
	local function pitchLine(sz, lx, lz)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = lineCol,
			Size = sz,
			CFrame = baseCFrame * CFrame.new(lx, pitchY + 0.08, lz),
		}, model)
	end
	-- Touch lines and goal lines
	pitchLine(Vector3.new(pitchW + 0.4, 0.05, 0.3), 0, -pitchD / 2)
	pitchLine(Vector3.new(pitchW + 0.4, 0.05, 0.3), 0,  pitchD / 2)
	pitchLine(Vector3.new(0.3, 0.05, pitchD + 0.4), -pitchW / 2, 0)
	pitchLine(Vector3.new(0.3, 0.05, pitchD + 0.4),  pitchW / 2, 0)
	-- Halfway line
	pitchLine(Vector3.new(0.3, 0.05, pitchD), 0, 0)
	-- Center circle (8 segments)
	for i = 0, 23 do
		local a1 = (i / 24) * math.pi * 2
		local r = 4
		local segLen = 2 * r * math.sin(math.pi / 24)
		local cf = baseCFrame
			* CFrame.new(math.cos(a1) * r, pitchY + 0.08, math.sin(a1) * r)
			* CFrame.Angles(0, -a1 + math.pi / 2, 0)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = lineCol,
			Size = Vector3.new(0.2, 0.05, segLen),
			CFrame = cf,
		}, model)
	end
	-- Center spot
	make("Part", {
		Anchored = true, CanCollide = false, Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic, Color = lineCol,
		Size = Vector3.new(0.05, 0.6, 0.6),
		CFrame = baseCFrame * CFrame.new(0, pitchY + 0.09, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)
	-- Penalty boxes
	for _, sign in ipairs({-1, 1}) do
		local bx = sign * (pitchW / 2 - 4.5)
		pitchLine(Vector3.new(0.25, 0.05, 12), bx, 0)
		pitchLine(Vector3.new(9, 0.05, 0.25), bx + sign * -4.5, -6)
		pitchLine(Vector3.new(9, 0.05, 0.25), bx + sign * -4.5,  6)
	end
	-- Copy the old base's four small angled corner nets onto the raised concept pitch.
	local conceptGoalX = pitchW / 2 - 1.7
	local conceptGoalZ = pitchD / 2 - 1.5
	local function createConceptCornerGoal(name, localX, localZ)
		local worldPosition = (baseCFrame * CFrame.new(localX, pitchY + 0.13, localZ)).Position
		local lookPosition = (baseCFrame * CFrame.new(0, pitchY + 0.13, 0)).Position
		createCornerGoal(model, name, CFrame.lookAt(worldPosition, lookPosition))
	end
	createConceptCornerGoal("NorthEastCornerGoal", conceptGoalX, -conceptGoalZ)
	createConceptCornerGoal("SouthEastCornerGoal", conceptGoalX, conceptGoalZ)
	createConceptCornerGoal("NorthWestCornerGoal", -conceptGoalX, -conceptGoalZ)
	createConceptCornerGoal("SouthWestCornerGoal", -conceptGoalX, conceptGoalZ)

	-- ── Layered octagonal walls with support pillars + neon strips ──────────
	local wallY = floorH + wallH / 2
	local octRadius = size / 2 - 2
	-- Rotate octagon by π/8 so a FLAT side faces the entrance (+X), and pillars
	-- sit at the corners flanking the entrance opening.
	local angleOffset = math.pi / 8
	local pillarW = 3.6
	local pillarH = wallH + 3.4
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2 + angleOffset
		local px = math.cos(angle) * octRadius
		local pz = math.sin(angle) * octRadius
		make("Part", {
			Name = "WallPillar" .. i, Anchored = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(pillarW, pillarH, pillarW),
			CFrame = baseCFrame * CFrame.new(px, floorH + pillarH / 2, pz),
		}, model)
		-- Stone cap on top of pillar (architectural, not neon)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneLite,
			Size = Vector3.new(pillarW + 0.6, 0.6, pillarW + 0.6),
			CFrame = baseCFrame * CFrame.new(px, floorH + pillarH + 0.3, pz),
		}, model)
		-- Subtle gold accent line just below cap (much dimmer)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.28,
			Size = Vector3.new(pillarW + 0.3, 0.1, pillarW + 0.3),
			CFrame = baseCFrame * CFrame.new(px, floorH + pillarH - 0.1, pz),
		}, model)
		-- Pillar architectural base (chunky concrete plinth)
		make("Part", {
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Concrete, Color = stoneMid,
			Size = Vector3.new(pillarW + 1, 1.6, pillarW + 1),
			CFrame = baseCFrame * CFrame.new(px, floorH + 0.8, pz),
		}, model)
		-- Decorative trim ring at base
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneLite,
			Size = Vector3.new(pillarW + 1.2, 0.18, pillarW + 1.2),
			CFrame = baseCFrame * CFrame.new(px, floorH + 1.7, pz),
		}, model)
		-- Mid-height architectural trim band on pillar
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneLite,
			Size = Vector3.new(pillarW + 0.5, 0.3, pillarW + 0.5),
			CFrame = baseCFrame * CFrame.new(px, floorH + pillarH * 0.4, pz),
		}, model)
		-- Vertical inset gold accent line on outward face of pillar
		local outwardAngle = (i / 8) * math.pi * 2 + angleOffset
		local outX = math.cos(outwardAngle)
		local outZ = math.sin(outwardAngle)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.3,
			Size = Vector3.new(0.18, pillarH * 0.7, 0.18),
			CFrame = baseCFrame * CFrame.new(px + outX * (pillarW / 2 + 0.05), floorH + pillarH * 0.55, pz + outZ * (pillarW / 2 + 0.05)),
		}, model)
		-- Pillar uplight glow (subtle warm)
		local lightAnchor = make("Part", {
			Anchored = true, CanCollide = false, Transparency = 1,
			Size = Vector3.new(1, 1, 1),
			CFrame = baseCFrame * CFrame.new(px, floorH + pillarH + 1, pz),
		}, model)
		make("PointLight", { Brightness = 0.8, Range = 14, Color = goldCol }, lightAnchor)
	end
	-- Helper that builds one wall segment with structural depth (recessed layers,
	-- inner ledge, support beam, embedded glow strip — but neon trim toned down)
	local function buildWallPiece(centerX, centerZ, length, yawAngle, nameSuffix)
		local cf = baseCFrame * CFrame.new(centerX, wallY, centerZ) * CFrame.Angles(0, -yawAngle, 0)
		-- Outer thick wall (main shell)
		make("Part", {
			Name = "Wall" .. nameSuffix, Anchored = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(length, wallH, wallT),
			CFrame = cf,
		}, model)
		-- Inner recessed panel (slightly lighter mid-stone)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneMid,
			Size = Vector3.new(length - 1.2, wallH - 5.5, wallT * 0.3),
			CFrame = cf * CFrame.new(0, 0, -wallT * 0.4 - 0.05),
		}, model)
		-- Inner ledge / horizontal trim band at mid-height (architectural depth)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneLite,
			Size = Vector3.new(length - 0.6, 0.4, wallT * 0.5 + 0.2),
			CFrame = cf * CFrame.new(0, -1, -wallT * 0.5 - 0.05),
		}, model)
		-- Subtle embedded gold glow strip (much dimmer)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.32,
			Size = Vector3.new(math.max(0.2, length - 2), 0.18, 0.12),
			CFrame = cf * CFrame.new(0, -0.7, -wallT * 0.5 - 0.12),
		}, model)
		-- Top ledge cap (architectural, NOT glowing)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneLite,
			Size = Vector3.new(length + 0.4, 0.5, wallT + 0.5),
			CFrame = cf * CFrame.new(0, wallH / 2 + 0.25, 0),
		}, model)
		-- Subtle gold trim line just below top cap (dimmer)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.28,
			Size = Vector3.new(length + 0.1, 0.12, wallT + 0.15),
			CFrame = cf * CFrame.new(0, wallH / 2 - 0.1, 0),
		}, model)
		-- Subtle bottom floor glow (dim warm)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.42,
			Size = Vector3.new(length + 0.1, 0.1, wallT + 0.1),
			CFrame = cf * CFrame.new(0, -wallH / 2 + 0.05, 0),
		}, model)
	end
	-- Wall segments between pillars; the front-facing wall (i=7 wraparound)
	-- builds two shoulder pieces flanking a centered entrance opening.
	local entranceOpeningW = 18
	for i = 0, 7 do
		local a1 = (i / 8) * math.pi * 2 + angleOffset
		local a2 = ((i + 1) / 8) * math.pi * 2 + angleOffset
		local x1, z1 = math.cos(a1) * octRadius, math.sin(a1) * octRadius
		local x2, z2 = math.cos(a2) * octRadius, math.sin(a2) * octRadius
		local fullLen = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
		local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
		local segAngle = math.atan2(z2 - z1, x2 - x1)
		if i == 7 then
			-- Front: split into two shoulder walls leaving entranceOpeningW gap in centre
			local shoulderLen = (fullLen - entranceOpeningW - pillarW) / 2
			if shoulderLen > 1 then
				local dx = (x2 - x1) / fullLen
				local dz = (z2 - z1) / fullLen
				-- Left shoulder (between pillar 7 and entrance opening)
				local lcx = x1 + dx * (pillarW / 2 + shoulderLen / 2)
				local lcz = z1 + dz * (pillarW / 2 + shoulderLen / 2)
				buildWallPiece(lcx, lcz, shoulderLen, segAngle, "FrontL")
				-- Right shoulder (between entrance opening and pillar 0)
				local rcx = x2 - dx * (pillarW / 2 + shoulderLen / 2)
				local rcz = z2 - dz * (pillarW / 2 + shoulderLen / 2)
				buildWallPiece(rcx, rcz, shoulderLen, segAngle, "FrontR")
			end
		else
			local segLen = fullLen - pillarW + 0.1
			buildWallPiece(cx, cz, segLen, segAngle, tostring(i))
		end
	end

	-- ── Detailed red bleachers (5 tiers, structural depth, backing walls) ───
	local function buildBleacherSide(zSignParam)
		local bleacherFolder = make("Folder", { Name = "Bleachers" .. (zSignParam > 0 and "South" or "North") }, model)
		local rows = 5
		local rowDepth = 2.6
		local rowRise = 1.5
		local rowWidth = math.min(pitchW - 8, 50)   -- wide, but still clear of octagon corners
		local startZ = zSignParam * (pitchD / 2 + pitchSeatGap)
		-- Dark underside support structure (extends across the full bleacher footprint)
		make("Part", {
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Concrete, Color = Color3.fromRGB(18, 22, 30),
			Size = Vector3.new(rowWidth + 0.4, 0.6, rowDepth * rows + 1),
			CFrame = baseCFrame * CFrame.new(0, floorH + 0.3, startZ + zSignParam * (rowDepth * rows / 2 - rowDepth / 2)),
		}, bleacherFolder)
		-- Vertical structural support beams under the bleachers (every 6 studs)
		for beamX = -rowWidth / 2 + 3, rowWidth / 2 - 3, 6 do
			for r = 1, rows - 1 do
				local beamY = floorH + 0.6 + r * rowRise / 2
				local beamH = r * rowRise * 0.8
				make("Part", {
					Anchored = true, CanCollide = false,
					Material = Enum.Material.Concrete, Color = Color3.fromRGB(28, 32, 40),
					Size = Vector3.new(0.6, beamH, 0.8),
					CFrame = baseCFrame * CFrame.new(beamX, beamY, startZ + zSignParam * ((r - 0.5) * rowDepth)),
				}, bleacherFolder)
			end
		end
		-- Backing wall pushed RIGHT against the top row (no gap, no falling through)
		local topRowZ = startZ + zSignParam * ((rows - 1) * rowDepth + rowDepth / 2)
		local backWallZ = topRowZ + zSignParam * (rowDepth / 2 + 0.4)
		local backWallY = floorH + 0.6 + rows * rowRise / 2 + 2
		local backWallH = rows * rowRise + 4
		make("Part", {
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(rowWidth + 1, backWallH, 0.8),
			CFrame = baseCFrame * CFrame.new(0, backWallY, backWallZ),
		}, bleacherFolder)
		-- Solid filler block: covers the entire space from the top of the top row
		-- to the back wall AND seals downward so nothing can drop through.
		local fillerDepth = rowDepth + 1.4
		local fillerY = floorH + 0.6 + rows * rowRise / 2  -- mid-height of bleacher stack
		local fillerH = rows * rowRise                       -- full bleacher height
		make("Part", {
			Anchored = true, CanCollide = true,
			Material = Enum.Material.SmoothPlastic, Color = stoneDark,
			Size = Vector3.new(rowWidth, fillerH, fillerDepth),
			CFrame = baseCFrame * CFrame.new(0, fillerY, topRowZ + zSignParam * (fillerDepth / 2)),
		}, bleacherFolder)
		-- Subtle gold cap on the backing wall
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.24,
			Size = Vector3.new(rowWidth + 1, 0.18, 0.9),
			CFrame = baseCFrame * CFrame.new(0, backWallY + backWallH / 2 + 0.1, backWallZ),
		}, bleacherFolder)
		-- Side end-caps (dark slate walls at each end of the bleachers)
		for _, sx in ipairs({-rowWidth / 2 - 0.5, rowWidth / 2 + 0.5}) do
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Slate, Color = stoneDark,
				Size = Vector3.new(0.8, rows * rowRise + 1, rowDepth * rows + 1),
				CFrame = baseCFrame * CFrame.new(sx, floorH + 0.3 + (rows * rowRise + 1) / 2, startZ + zSignParam * (rowDepth * rows / 2 - rowDepth / 2)),
			}, bleacherFolder)
		end
		for r = 1, rows do
			local h = rowRise
			local y = floorH + 0.6 + (r - 1) * rowRise + h / 2
			local zPos = startZ + zSignParam * ((r - 1) * rowDepth + rowDepth / 2)
			local color = (r % 2 == 0) and redSeatLo or redSeat
			-- Main seat row block (now dark — premium feel)
			make("Part", {
				Anchored = true, CanCollide = true,
				Material = Enum.Material.SmoothPlastic, Color = color,
				Size = Vector3.new(rowWidth, h, rowDepth),
				CFrame = baseCFrame * CFrame.new(0, y, zPos),
			}, bleacherFolder)
			-- Thin RED ACCENT strip on the front edge of each row (the only red highlight)
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.SmoothPlastic, Color = redAccent,
				Size = Vector3.new(rowWidth, 0.18, 0.16),
				CFrame = baseCFrame * CFrame.new(0, y + h / 2 + 0.05, zPos - zSignParam * rowDepth / 2),
			}, bleacherFolder)
			-- Seat back: thin vertical lip at the back of each row (gives visible 3D depth)
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.SmoothPlastic, Color = redSeatLo,
				Size = Vector3.new(rowWidth, 0.6, 0.2),
				CFrame = baseCFrame * CFrame.new(0, y + h / 2 + 0.3, zPos + zSignParam * (rowDepth / 2 - 0.1)),
			}, bleacherFolder)
			-- Individual seat dividers along the row (every 2.4 studs) — black tone
			local divCount = math.floor(rowWidth / 2.4)
			local divSpacing = rowWidth / divCount
			for d = 0, divCount do
				local divX = -rowWidth / 2 + d * divSpacing
				make("Part", {
					Anchored = true, CanCollide = false,
					Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(20, 22, 28),
					Size = Vector3.new(0.18, 0.7, rowDepth - 0.2),
					CFrame = baseCFrame * CFrame.new(divX, y + h / 2 - 0.05, zPos),
				}, bleacherFolder)
			end
			-- Subtle gold trim along front edge of seat row (toned down)
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.18,
				Size = Vector3.new(rowWidth + 0.1, 0.1, 0.1),
				CFrame = baseCFrame * CFrame.new(0, y + h / 2 + 0.18, zPos - zSignParam * rowDepth / 2),
			}, bleacherFolder)
		end
		-- Side staircase access (light-coloured stair blocks at each end)
		for _, sx in ipairs({-rowWidth / 2 + 1, rowWidth / 2 - 1}) do
			for r = 1, rows do
				local h = rowRise
				local y = floorH + 0.6 + (r - 1) * rowRise + h / 2
				local zPos = startZ + zSignParam * ((r - 1) * rowDepth + rowDepth / 2)
				make("Part", {
					Anchored = true, CanCollide = false,
					Material = Enum.Material.SmoothPlastic, Color = stoneLite,
					Size = Vector3.new(1.6, h, rowDepth - 0.2),
					CFrame = baseCFrame * CFrame.new(sx, y, zPos),
				}, bleacherFolder)
				-- Gold rail along stairs
				make("Part", {
					Anchored = true, CanCollide = false,
					Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.16,
					Size = Vector3.new(0.16, 0.16, rowDepth - 0.2),
					CFrame = baseCFrame * CFrame.new(sx, y + h / 2 + 0.1, zPos),
				}, bleacherFolder)
			end
		end
		-- Visible fan access aisles at the ends of each stand. These mirror the
		-- hidden route points the live NPC system will use once this becomes a plot.
		local accessLaneDepth = rowDepth * rows + 1.4
		local accessLaneZ = startZ + zSignParam * (rowDepth * rows / 2 - rowDepth / 2)
		for _, sx in ipairs({-rowWidth / 2 - 2.1, rowWidth / 2 + 2.1}) do
			make("Part", {
				Name = "FanAccessAisle", Anchored = true, CanCollide = false,
				Material = Enum.Material.Concrete, Color = stoneLite,
				Size = Vector3.new(2.2, 0.16, accessLaneDepth),
				CFrame = baseCFrame * CFrame.new(sx, floorH + 0.16, accessLaneZ),
			}, bleacherFolder)
			for _, edgeX in ipairs({-1, 1}) do
				make("Part", {
					Name = "FanAccessAisleGoldEdge", Anchored = true, CanCollide = false,
					Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.22,
					Size = Vector3.new(0.12, 0.06, accessLaneDepth),
					CFrame = baseCFrame * CFrame.new(sx + edgeX * 1.13, floorH + 0.28, accessLaneZ),
				}, bleacherFolder)
			end
			make("Part", {
				Name = "FanAccessLanding", Anchored = true, CanCollide = false,
				Material = Enum.Material.Concrete, Color = stoneLite,
				Size = Vector3.new(3.2, 0.17, 2.4),
				CFrame = baseCFrame * CFrame.new(sx, floorH + 0.18, zSignParam * (pitchD / 2 + 1.2)),
			}, bleacherFolder)
		end
	end
	buildBleacherSide(-1) -- North
	buildBleacherSide( 1) -- South

	if includeCenterPad then
		-- ── Central pack-opening pad (flat, simple, like the original base) ────
		-- Keep this as an architectural landing spot for the real pack slot later.
		local podiumY = floorH + 0.2
		local function octRing(radius, height, yCenter, color, mat, transparency)
			for i = 0, 7 do
				local a1 = (i / 8) * math.pi * 2
				local a2 = ((i + 1) / 8) * math.pi * 2
				local x1, z1 = math.cos(a1) * radius, math.sin(a1) * radius
				local x2, z2 = math.cos(a2) * radius, math.sin(a2) * radius
				local segLen = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
				local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
				local segAngle = math.atan2(z2 - z1, x2 - x1)
				make("Part", {
					Anchored = true, CanCollide = (transparency or 0) < 0.5,
					Material = mat, Color = color,
					Transparency = transparency or 0,
					Size = Vector3.new(segLen, height, radius * 0.5),
					CFrame = baseCFrame * CFrame.new(cx * 0.78, yCenter, cz * 0.78) * CFrame.Angles(0, -segAngle, 0),
				}, model)
			end
		end
		-- Single small flat octagonal pad — dark stone, no glow
		octRing(5.5, 0.6, podiumY + 0.3, stoneDark, Enum.Material.Slate)
		-- Low-contrast bronze trim only. The live pack slot can own the dramatic glow later.
		octRing(5.6, 0.08, podiumY + 0.65, Color3.fromRGB(96, 68, 22), Enum.Material.SmoothPlastic)
	end

	if includeDisplaySlots then
		-- ── Card display slots — real display-slot helper, laid out like the concept ──
		local slotPositions = {
			-- North side (z negative); player approaches from +Z (the pitch side)
			{ x = -pitchW / 3, z = -pitchD / 2 + 3, dir = Vector3.new(0, 0, 1) },
			{ x = 0,           z = -pitchD / 2 + 3, dir = Vector3.new(0, 0, 1) },
			{ x =  pitchW / 3, z = -pitchD / 2 + 3, dir = Vector3.new(0, 0, 1) },
			-- South side (z positive); player approaches from -Z (the pitch side)
			{ x = -pitchW / 3, z =  pitchD / 2 - 3, dir = Vector3.new(0, 0, -1) },
			{ x = 0,           z =  pitchD / 2 - 3, dir = Vector3.new(0, 0, -1) },
			{ x =  pitchW / 3, z =  pitchD / 2 - 3, dir = Vector3.new(0, 0, -1) },
		}
		local conceptSlotFolder = make("Folder", { Name = "DisplaySlots" }, model)
		for slotI, _slot in ipairs(slotPositions) do
			createDisplaySlot(
				conceptSlotFolder,
				slotI,
				baseCFrame * CFrame.new(_slot.x, floorH + layout.DisplaySlotSize.Y / 2, _slot.z),
				_slot.dir
			)
		end
	end

	-- ── Tunnel-style entrance: thicker frame, side columns, recessed depth ──
	local archX = size / 2 + 6
	local archHeight = 13
	local archWidth = 16
	local frameW = 3
	-- Deep tunnel frame: outer columns
	for _, sz in ipairs({-archWidth / 2, archWidth / 2}) do
		make("Part", {
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(frameW * 2, archHeight + 2, frameW),
			CFrame = baseCFrame * CFrame.new(archX, (archHeight + 2) / 2, sz),
		}, model)
		-- Gold pillar accent strip (vertical)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.62,
			Size = Vector3.new(0.3, archHeight - 1, 0.3),
			CFrame = baseCFrame * CFrame.new(archX - frameW + 0.1, archHeight / 2, sz - frameW / 2 + 0.1),
		}, model)
		-- Pillar top cap
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 138, 24),
			Size = Vector3.new(frameW * 2.4, 0.18, frameW + 0.4),
			CFrame = baseCFrame * CFrame.new(archX, archHeight + 2.3, sz),
		}, model)
	end
	-- Inner tunnel side columns (recessed)
	for _, sz in ipairs({-archWidth / 2 + 2.6, archWidth / 2 - 2.6}) do
		make("Part", {
			Anchored = true, CanCollide = true,
			Material = Enum.Material.SmoothPlastic, Color = stoneMid,
			Size = Vector3.new(frameW, archHeight, 1),
			CFrame = baseCFrame * CFrame.new(archX - 1.5, archHeight / 2, sz),
		}, model)
	end
	-- Massive horizontal arch beam
	local archBeam = make("Part", {
		Name = "ArchBeam", Anchored = true,
		Material = Enum.Material.Slate, Color = stoneDark,
		Size = Vector3.new(frameW * 2, 4.6, archWidth + frameW * 2),
		CFrame = baseCFrame * CFrame.new(archX, archHeight + 2.3, 0),
	}, model)
	-- Gold trim under beam
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 138, 24),
		Size = Vector3.new(frameW * 2 + 0.3, 0.12, archWidth + frameW * 2 + 0.3),
		CFrame = baseCFrame * CFrame.new(archX, archHeight + 2.3 - 2.5, 0),
	}, model)
	-- Gold trim above beam
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 138, 24),
		Size = Vector3.new(frameW * 2 + 0.3, 0.12, archWidth + frameW * 2 + 0.3),
		CFrame = baseCFrame * CFrame.new(archX, archHeight + 2.3 + 2.55, 0),
	}, model)
	if includeEntranceSign then
		-- ── "ZAID'S STADIUM" sign — thinner, sharper, less neon-overpowering ───
		-- A slim signboard that reads as architectural trim, not a giant glowing slab.
		local signPlate = make("Part", {
			Name = "ArchStadiumSignPlate",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(10, 12, 18),
			Size = Vector3.new(0.5, 2.9, 12.8),
			CFrame = baseCFrame * CFrame.new(archX + frameW + 0.85, archHeight + 2.3, 0),
		}, model)
		-- Thin matte-gold trim line above and below (sharper, not a glowing backplate)
		for _, sy in ipairs({-1, 1}) do
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(206, 154, 34),
				Size = Vector3.new(0.52, 0.1, 13.1),
				CFrame = baseCFrame * CFrame.new(archX + frameW + 0.86, archHeight + 2.3 + sy * 1.55, 0),
			}, model)
		end
		-- Sign text on the OUTWARD-facing side (+X = Right face)
		local signGuiOutward = make("SurfaceGui", {
			Name = "StadiumSignFront",
			Face = Enum.NormalId.Right,
			LightInfluence = 0, PixelsPerStud = 80,
		}, signPlate)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.94, 0.78),
			Position = UDim2.fromScale(0.03, 0.11),
			Text = "ZAID'S STADIUM",
			TextColor3 = Color3.fromRGB(255, 232, 96),
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0.18,
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, signGuiOutward)
		-- Inward face (visible when leaving stadium)
		local signGuiInward = make("SurfaceGui", {
			Name = "StadiumSignBack",
			Face = Enum.NormalId.Left,
			LightInfluence = 0, PixelsPerStud = 80,
		}, signPlate)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.94, 0.78),
			Position = UDim2.fromScale(0.03, 0.11),
			Text = "ZAID'S STADIUM",
			TextColor3 = Color3.fromRGB(255, 232, 96),
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0.18,
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, signGuiInward)
		-- Gold ball ornaments flanking the sign
		for _, sz in ipairs({-archWidth / 2 + 1.8, archWidth / 2 - 1.8}) do
			make("Part", {
				Anchored = true, CanCollide = false, Shape = Enum.PartType.Ball,
				Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(180, 128, 28),
				Size = Vector3.new(1.8, 1.8, 1.8),
				CFrame = baseCFrame * CFrame.new(archX - 0.6, archHeight + 2.3, sz),
			}, model)
		end
	end
	-- Floor strip lights running through the entrance tunnel
	for _, dz in ipairs({-1, 1}) do
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.2,
			Size = Vector3.new(frameW * 4, 0.06, 0.3),
			CFrame = baseCFrame * CFrame.new(archX, floorH + 0.07, dz * (archWidth / 2 - 1)),
		}, model)
	end
	-- Tunnel ceiling glow strip
	make("Part", {
		Anchored = true, CanCollide = false,
		Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.72,
		Size = Vector3.new(frameW * 4, 0.12, 0.45),
		CFrame = baseCFrame * CFrame.new(archX, archHeight - 0.3, 0),
	}, model)

	-- Close the side gaps between the octagon wall shoulders and the entrance tunnel.
	-- These are structural infill pieces, leaving only the central gate open.
	local entranceClosureZ = archWidth / 2 + frameW / 2 + 1.25
	local entranceClosureX = size / 2 + 2.8
	local entranceClosureLength = 10.6
	local entranceClosureHeight = 10.2
	for _, dz in ipairs({-1, 1}) do
		make("Part", {
			Name = "EntranceSideClosure" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(entranceClosureLength, entranceClosureHeight, 2.3),
			CFrame = baseCFrame * CFrame.new(entranceClosureX, floorH + entranceClosureHeight / 2, dz * entranceClosureZ),
		}, model)
		make("Part", {
			Name = "EntranceSideClosureInset" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneMid,
			Size = Vector3.new(entranceClosureLength - 1.4, entranceClosureHeight - 3.2, 0.24),
			CFrame = baseCFrame * CFrame.new(entranceClosureX, floorH + entranceClosureHeight / 2 - 0.2, dz * (entranceClosureZ - 1.18)),
		}, model)
		make("Part", {
			Name = "EntranceSideClosureCap" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneLite,
			Size = Vector3.new(entranceClosureLength + 0.6, 0.42, 2.7),
			CFrame = baseCFrame * CFrame.new(entranceClosureX, floorH + entranceClosureHeight + 0.2, dz * entranceClosureZ),
		}, model)
		make("Part", {
			Name = "EntranceSideClosureTrim" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 138, 24),
			Size = Vector3.new(entranceClosureLength - 0.7, 0.12, 0.16),
			CFrame = baseCFrame * CFrame.new(entranceClosureX, floorH + entranceClosureHeight - 1.2, dz * (entranceClosureZ - 1.28)),
		}, model)
	end

	-- Wider side wings cover the remaining sliver between the entrance tunnel
	-- and the octagon shoulders when viewed from player height.
	local entranceWingX = size / 2 + 1.3
	local entranceWingZ = archWidth / 2 + frameW + 5.0
	local entranceWingLength = 14.8
	local entranceWingDepth = 7.0
	local entranceWingHeight = 9.6
	for _, dz in ipairs({-1, 1}) do
		make("Part", {
			Name = "EntranceSideWing" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(entranceWingLength, entranceWingHeight, entranceWingDepth),
			CFrame = baseCFrame * CFrame.new(entranceWingX, floorH + entranceWingHeight / 2, dz * entranceWingZ),
		}, model)
		make("Part", {
			Name = "EntranceSideWingInset" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneMid,
			Size = Vector3.new(entranceWingLength - 1.4, entranceWingHeight - 3.1, 0.22),
			CFrame = baseCFrame * CFrame.new(entranceWingX, floorH + entranceWingHeight / 2 - 0.2, dz * (entranceWingZ - entranceWingDepth / 2 - 0.12)),
		}, model)
		make("Part", {
			Name = "EntranceSideWingCap" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = stoneLite,
			Size = Vector3.new(entranceWingLength + 0.5, 0.42, entranceWingDepth + 0.4),
			CFrame = baseCFrame * CFrame.new(entranceWingX, floorH + entranceWingHeight + 0.2, dz * entranceWingZ),
		}, model)
		make("Part", {
			Name = "EntranceSideWingGoldLine" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 138, 24),
			Size = Vector3.new(entranceWingLength - 1.0, 0.12, 0.16),
			CFrame = baseCFrame * CFrame.new(entranceWingX, floorH + entranceWingHeight - 1.2, dz * (entranceWingZ - entranceWingDepth / 2 - 0.24)),
		}, model)
		make("Part", {
			Name = "EntranceSideGapFloorSkirt" .. (dz > 0 and "South" or "North"),
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = Color3.fromRGB(12, 15, 22),
			Size = Vector3.new(entranceWingLength + 1.2, 0.55, 2.8),
			CFrame = baseCFrame * CFrame.new(entranceWingX, floorH + 0.28, dz * (archWidth / 2 + frameW + 1.3)),
		}, model)
	end

	-- ── 4 corner stadium floodlights — proper multi-bulb panel arrays ───────
	-- These are real stadium floodlights: tall pole + truss bracket + big rectangular
	-- panel housing with a 4×2 grid of individual bulbs, all aimed inward.
	local floodPoleHeight = 38
	for _, dx in ipairs({-1, 1}) do
		for _, dz in ipairs({-1, 1}) do
			local px = dx * (size / 2 + 4)
			local pz = dz * (size / 2 + 4)
			-- Concrete pole base (chunky)
			make("Part", {
				Anchored = true, CanCollide = true,
				Material = Enum.Material.Concrete, Color = stoneDark,
				Size = Vector3.new(4.4, 1.8, 4.4),
				CFrame = baseCFrame * CFrame.new(px, floorH + 0.9, pz),
			}, model)
			-- Concrete pole base trim (slightly raised)
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Concrete, Color = stoneMid,
				Size = Vector3.new(4.6, 0.3, 4.6),
				CFrame = baseCFrame * CFrame.new(px, floorH + 1.95, pz),
			}, model)
			-- Tall metal pole (matte dark)
			make("Part", {
				Name = "FloodlightPole_" .. (dx > 0 and "E" or "W") .. (dz > 0 and "S" or "N"),
				Anchored = true, CanCollide = true,
				Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(36, 40, 48),
				Size = Vector3.new(1.5, floodPoleHeight, 1.5),
				CFrame = baseCFrame * CFrame.new(px, floorH + 2.1 + floodPoleHeight / 2, pz),
			}, model)
			-- Pole reinforcing collar near top
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Metal, Color = Color3.fromRGB(50, 55, 65),
				Size = Vector3.new(2, 0.5, 2),
				CFrame = baseCFrame * CFrame.new(px, floorH + 2.1 + floodPoleHeight - 1.5, pz),
			}, model)
			-- Bracket arm extending toward the stadium center (truss feel)
			local armDX = -dx * 2.6
			local armDZ = -dz * 2.6
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Metal, Color = Color3.fromRGB(50, 55, 65),
				Size = Vector3.new(3, 1, 3),
				CFrame = baseCFrame * CFrame.new(px + armDX / 2, floorH + 2.1 + floodPoleHeight + 0.5, pz + armDZ / 2),
			}, model)
			-- Big rectangular floodlight panel housing (the wide stadium-style head)
			-- Use CFrame.lookAt to GUARANTEE it points toward the centre, then tilt down.
			local headWorldPos = (baseCFrame * CFrame.new(px + armDX, floorH + 2.1 + floodPoleHeight + 0.3, pz + armDZ)).Position
			local centerWorldPos = (baseCFrame * CFrame.new(0, floorH + 6, 0)).Position
			local headCFrame = CFrame.lookAt(headWorldPos, centerWorldPos) * CFrame.Angles(math.rad(15), 0, 0)
			-- Housing frame (wide rectangle)
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(46, 50, 60),
				Size = Vector3.new(7, 4.2, 1.4),
				CFrame = headCFrame,
			}, model)
			-- Inner darker housing recess
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(14, 16, 22),
				Size = Vector3.new(6.4, 3.6, 0.6),
				CFrame = headCFrame * CFrame.new(0, 0, -0.5),
			}, model)
			-- 4×2 grid of individual bulbs (8 total per floodlight)
			for bulbCol = 1, 4 do
				for bulbRow = 1, 2 do
					local bulbX = -2.4 + (bulbCol - 1) * 1.6
					local bulbY = -0.85 + (bulbRow - 1) * 1.7
					-- Bulb housing (small dark ring)
					make("Part", {
						Anchored = true, CanCollide = false,
						Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 65, 75),
						Size = Vector3.new(1.3, 1.3, 0.4),
						CFrame = headCFrame * CFrame.new(bulbX, bulbY, -0.55),
					}, model)
					-- Bulb itself (neon)
					make("Part", {
						Anchored = true, CanCollide = false, Shape = Enum.PartType.Cylinder,
						Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 245, 220),
						Size = Vector3.new(0.3, 1.05, 1.05),
						CFrame = headCFrame * CFrame.new(bulbX, bulbY, -0.7) * CFrame.Angles(0, 0, math.rad(90)),
					}, model)
				end
			end
			-- Top frame trim
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 65, 75),
				Size = Vector3.new(7.2, 0.4, 1.6),
				CFrame = headCFrame * CFrame.new(0, 2.05, 0),
			}, model)
			-- Bottom frame trim
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 65, 75),
				Size = Vector3.new(7.2, 0.4, 1.6),
				CFrame = headCFrame * CFrame.new(0, -2.05, 0),
			}, model)
			-- Aimed SpotLight from the panel
			local lightAnchor = make("Part", {
				Anchored = true, CanCollide = false, Transparency = 1,
				Size = Vector3.new(1, 1, 1),
				CFrame = headCFrame * CFrame.new(0, 0, -1),
			}, model)
			make("SpotLight", {
				Brightness = 3.2, Range = 115, Angle = 78,
				Face = Enum.NormalId.Front,
				Color = Color3.fromRGB(255, 245, 220),
			}, lightAnchor)
		end
	end

	-- (Removed ground spotlights aimed at podium — were over-illuminating the slots)

	-- ── Decorative props: landscaped entrance frontage, banners, benches ───
	local function makeConceptBush(name, localX, localZ, scale)
		scale = scale or 1
		local bush = make("Model", { Name = name }, model)
		for index, layer in ipairs({
			{ offset = Vector3.new(0, 0, 0), size = Vector3.new(3.0, 2.0, 3.0), color = Color3.fromRGB(32, 92, 38) },
			{ offset = Vector3.new(0.55, 0.22, -0.35), size = Vector3.new(2.25, 1.45, 2.25), color = Color3.fromRGB(45, 120, 48) },
			{ offset = Vector3.new(-0.55, 0.15, 0.45), size = Vector3.new(2.1, 1.35, 2.1), color = Color3.fromRGB(36, 104, 42) },
		}) do
			make("Part", {
				Name = "LeafMass" .. tostring(index),
				Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Grass, Color = layer.color,
				Size = layer.size * scale,
				CFrame = baseCFrame * CFrame.new(
					localX + layer.offset.X * scale,
					floorH + 0.75 * scale + layer.offset.Y * scale,
					localZ + layer.offset.Z * scale
				),
			}, bush)
		end
		return bush
	end

	local function makeFrontPlanter(name, localX, localZ, planterWidth, planterDepth)
		local planter = make("Model", { Name = name }, model)
		make("Part", {
			Name = "PlanterBase",
			Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(planterWidth, 0.8, planterDepth),
			CFrame = baseCFrame * CFrame.new(localX, floorH + 0.4, localZ),
		}, planter)
		make("Part", {
			Name = "PlanterSoil",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Ground, Color = Color3.fromRGB(42, 31, 22),
			Size = Vector3.new(planterWidth - 0.55, 0.18, planterDepth - 0.55),
			CFrame = baseCFrame * CFrame.new(localX, floorH + 0.88, localZ),
		}, planter)
		for _, edgeZ in ipairs({-1, 1}) do
			make("Part", {
				Name = "PlanterGoldEdge",
				Anchored = true, CanCollide = false,
				Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 138, 24),
				Size = Vector3.new(planterWidth, 0.12, 0.12),
				CFrame = baseCFrame * CFrame.new(localX, floorH + 0.98, localZ + edgeZ * planterDepth / 2),
			}, planter)
		end
		for offsetX = -planterWidth / 2 + 1.5, planterWidth / 2 - 1.5, 3 do
			makeConceptBush(name .. "Bush" .. tostring(math.floor((offsetX + planterWidth) * 10)), localX + offsetX, localZ, 0.72)
		end
		return planter
	end

	for _, dz in ipairs({-1, 1}) do
		makeFrontPlanter("FrontSidePlanter" .. (dz > 0 and "South" or "North"), archX + 14.5, dz * 15.2, 10.5, 4.2)
		makeFrontPlanter("OuterCornerPlanter" .. (dz > 0 and "South" or "North"), archX + 25.5, dz * 22.5, 8.4, 4.0)
		createCompactStadiumTree(
			model,
			"ConceptEntranceTree" .. (dz > 0 and "SouthA" or "NorthA"),
			(baseCFrame * CFrame.new(archX + 13.5, floorH, dz * 21.2)).Position,
			(baseCFrame * CFrame.new(0, floorH, 0)).Position
		)
		createCompactStadiumTree(
			model,
			"ConceptEntranceTree" .. (dz > 0 and "SouthB" or "NorthB"),
			(baseCFrame * CFrame.new(archX + 27.5, floorH, dz * 13.8)).Position,
			(baseCFrame * CFrame.new(0, floorH, 0)).Position
		)
		makeConceptBush("FrontRoundBush" .. (dz > 0 and "SouthInner" or "NorthInner"), archX + 9.5, dz * 12.4, 0.9)
		makeConceptBush("FrontRoundBush" .. (dz > 0 and "SouthOuter" or "NorthOuter"), archX + 31, dz * 18.4, 1.05)
	end
	-- ── Improved banners on inner side walls (now dark navy, gold trim) ────
	for _, dz in ipairs({-1, 1}) do
		for bIdx, bx in ipairs({-size / 4, 0, size / 4}) do
			local bannerCol = (bIdx % 2 == 0) and stoneDark or Color3.fromRGB(30, 35, 50)
			-- Banner cloth
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Fabric, Color = bannerCol,
				Size = Vector3.new(2.8, 6, 0.18),
				CFrame = baseCFrame * CFrame.new(bx, wallY + 1.5, dz * (size / 2 - 4)),
			}, model)
			-- Gold top crossbar
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.22,
				Size = Vector3.new(3.0, 0.22, 0.26),
				CFrame = baseCFrame * CFrame.new(bx, wallY + 4.5, dz * (size / 2 - 4)),
			}, model)
			-- Gold bottom weight bar
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.32,
				Size = Vector3.new(3.0, 0.18, 0.24),
				CFrame = baseCFrame * CFrame.new(bx, wallY - 1.5, dz * (size / 2 - 4)),
			}, model)
			-- Gold side trim strips
			for _, sx in ipairs({-1.4, 1.4}) do
				make("Part", {
					Anchored = true, CanCollide = false,
					Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.4,
					Size = Vector3.new(0.18, 6, 0.22),
					CFrame = baseCFrame * CFrame.new(bx + sx, wallY + 1.5, dz * (size / 2 - 4)),
				}, model)
			end
			-- Center decorative emblem (small gold disc)
			make("Part", {
				Anchored = true, CanCollide = false, Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon, Color = goldCol,
				Size = Vector3.new(0.7, 0.7, 0.7),
				CFrame = baseCFrame * CFrame.new(bx, wallY + 1.5, dz * (size / 2 - 4.05)),
			}, model)
		end
	end

	-- ── Inner tunnel doors (decorative crowd entrance archways) ─────────────
	-- 4 tunnel doors: 2 along the back wall, 2 along the back-side walls
	-- These suggest fans enter from these tunnels into the bleachers area.
	local tunnelDoorPositions = {
		-- Back wall (-X side): two tunnel doors flanking
		{ x = -size / 2 + 3.5, z = -10, faceDir = Vector3.new(1, 0, 0) },
		{ x = -size / 2 + 3.5, z =  10, faceDir = Vector3.new(1, 0, 0) },
		-- Side back walls
		{ x = -size / 4, z = -size / 2 + 3.5, faceDir = Vector3.new(0, 0, 1) },
		{ x = -size / 4, z =  size / 2 - 3.5, faceDir = Vector3.new(0, 0, -1) },
	}
	for tdI, tdPos in ipairs(tunnelDoorPositions) do
		local doorYaw = math.atan2(tdPos.faceDir.X, tdPos.faceDir.Z)
		local doorCenter = baseCFrame * CFrame.new(tdPos.x, floorH + 3, tdPos.z) * CFrame.Angles(0, doorYaw, 0)
		-- Door header (top)
		make("Part", {
			Name = "TunnelDoor" .. tdI .. "Header", Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = stoneDark,
			Size = Vector3.new(5.6, 1.2, 0.7),
			CFrame = doorCenter * CFrame.new(0, 3, 0),
		}, model)
		-- Door side jambs
		for _, sx in ipairs({-2.55, 2.55}) do
			make("Part", {
				Anchored = true, CanCollide = true,
				Material = Enum.Material.Slate, Color = stoneDark,
				Size = Vector3.new(0.55, 6.5, 0.7),
				CFrame = doorCenter * CFrame.new(sx, 0.25, 0),
			}, model)
		end
		-- Inner darkness (the tunnel interior)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(8, 10, 14),
			Size = Vector3.new(4.5, 5.6, 0.2),
			CFrame = doorCenter * CFrame.new(0, 0, -0.22),
		}, model)
		-- Warm gold underglow at the bottom of the door (tunnel light spill)
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.28,
			Size = Vector3.new(4.5, 0.18, 0.22),
			CFrame = doorCenter * CFrame.new(0, -2.7, -0.12),
		}, model)
		-- Top trim glow
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.32,
			Size = Vector3.new(5.7, 0.2, 0.74),
			CFrame = doorCenter * CFrame.new(0, 3.65, 0),
		}, model)
		-- Interior PointLight (warm spill glow)
		local doorLightAnchor = make("Part", {
			Anchored = true, CanCollide = false, Transparency = 1,
			Size = Vector3.new(1, 1, 1),
			CFrame = doorCenter * CFrame.new(0, 0, -0.5),
		}, model)
		make("PointLight", { Brightness = 1.2, Range = 10, Color = goldCol }, doorLightAnchor)
	end

	-- ── Wall screens / LED panels (jumbotron-style above bleachers) ─────────
	-- Mounted high on the side walls so they read like stadium scoreboards
	for _, dz in ipairs({-1, 1}) do
		for _, lx in ipairs({-14, 0, 14}) do
			-- Frame (dark stone)
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Slate, Color = stoneDark,
				Size = Vector3.new(7.2, 3.6, 0.5),
				CFrame = baseCFrame * CFrame.new(lx, wallY + 4.4, dz * (size / 2 - 4)),
			}, model)
			-- LED panel (neon emissive)
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon, Color = Color3.fromRGB(70, 110, 200), Transparency = 0.18,
				Size = Vector3.new(6.6, 3, 0.22),
				CFrame = baseCFrame * CFrame.new(lx, wallY + 4.4, dz * (size / 2 - 4.18)),
			}, model)
			-- Gold frame trim
			make("Part", {
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.32,
				Size = Vector3.new(7.4, 3.8, 0.18),
				CFrame = baseCFrame * CFrame.new(lx, wallY + 4.4, dz * (size / 2 - 4.06)),
			}, model)
			-- Soft fill light cast from screen
			local screenAnchor = make("Part", {
				Anchored = true, CanCollide = false, Transparency = 1,
				Size = Vector3.new(1, 1, 1),
				CFrame = baseCFrame * CFrame.new(lx, wallY + 4.4, dz * (size / 2 - 5)),
			}, model)
			make("PointLight", { Brightness = 0.5, Range = 14, Color = Color3.fromRGB(120, 160, 220) }, screenAnchor)
		end
	end

	-- (Kiosks removed — were not adding value to the arena)
	-- Crowd barriers along walkway entrance
	for _, dz in ipairs({-1, 1}) do
		for i = 0, 3 do
			make("Part", {
				Anchored = true, CanCollide = true,
				Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 65, 75),
				Size = Vector3.new(1.6, 1.8, 0.3),
				CFrame = baseCFrame * CFrame.new(archX + 4 + i * 3, floorH + 0.9, dz * (archWidth / 2 - 1)),
			}, model)
		end
	end

	-- ── Wide entrance stairs (per concept brief: stairs leading upward) ─────
	-- 4 step-down blocks descending from the floor level out to the plaza
	for stepI = 1, 4 do
		local stepDepth = 2.4
		local stepX = archX + 11 + (stepI - 1) * stepDepth
		local stepHeight = floorH - (stepI - 1) * 0.22
		make("Part", {
			Name = "EntranceStep" .. stepI, Anchored = true, CanCollide = true,
			Material = Enum.Material.Slate, Color = stoneMid,
			Size = Vector3.new(stepDepth, stepHeight, archWidth + frameW * 2),
			CFrame = baseCFrame * CFrame.new(stepX, stepHeight / 2, 0),
		}, model)
		-- Gold trim along front edge of each step
		make("Part", {
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon, Color = goldCol, Transparency = 0.48,
			Size = Vector3.new(0.16, 0.16, archWidth + frameW * 2 + 0.1),
			CFrame = baseCFrame * CFrame.new(stepX + stepDepth / 2, stepHeight + 0.08, 0),
		}, model)
	end

	return model
end


function BaseService.BuildBaseMap()
	setupCollisionGroups()
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
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(22, 28, 38),   -- premium dark tile (was rough cobblestone)
		Size = Vector3.new(mapWidth - 8, 0.2, mapLength - 8),
		CFrame = CFrame.new(0, 0.1, 0),
	}, basesFolder)

	createFanZone(mapWidth, mapLength)

	-- ── Side corridor strips (fill dead zone between walkway and stadiums) ─────
	-- Walkway ends at X=±27, stadiums begin at X=±115.  We add two lit paths
	-- at X=±71 to break up the dark floor and give players a visual guide.
	local sidePathColor   = Color3.fromRGB(30, 38, 52)
	local sideEdgeColor   = Color3.fromRGB(96, 178, 255)   -- cool blue neon
	local sideLampColor   = Color3.fromRGB(200, 225, 255)
	local halfLen         = mapLength / 2 - 6
	for _, sx in ipairs({ -71, 71 }) do
		make("Part", {
			Name = "SideCorridorPath",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Slate,
			Color = sidePathColor,
			Size = Vector3.new(20, 0.16, mapLength - 12),
			CFrame = CFrame.new(sx, 0.22, 0),
		}, basesFolder)
		-- Inner neon edge (faces walkway)
		make("Part", {
			Name = "SideCorridorInnerEdge",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = sideEdgeColor,
			Transparency = 0.52,
			Size = Vector3.new(0.22, 0.18, mapLength - 12),
			CFrame = CFrame.new(sx + (sx > 0 and -10 or 10), 0.3, 0),
		}, basesFolder)
		-- Outer neon edge (faces stadium)
		make("Part", {
			Name = "SideCorridorOuterEdge",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = sideEdgeColor,
			Transparency = 0.52,
			Size = Vector3.new(0.22, 0.18, mapLength - 12),
			CFrame = CFrame.new(sx + (sx > 0 and 10 or -10), 0.3, 0),
		}, basesFolder)
		-- Lamp posts every 48 studs
		local lampZ = -halfLen + 24
		while lampZ <= halfLen - 24 do
			local pole = make("Part", {
				Name = "SideLampPole",
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(28, 34, 46),
				Size = Vector3.new(0.5, 9, 0.5),
				CFrame = CFrame.new(sx, 4.5, lampZ),
			}, basesFolder)
			make("Part", {
				Name = "SideLampHead",
				Anchored = true, CanCollide = false,
				Material = Enum.Material.Neon,
				Color = sideEdgeColor,
				Transparency = 0.22,
				Size = Vector3.new(1.6, 0.5, 1.6),
				CFrame = CFrame.new(sx, 9.2, lampZ),
			}, basesFolder)
			make("PointLight", {
				Color = sideLampColor,
				Brightness = 0.58,
				Range = 36,
				Shadows = false,
			}, pole)
			lampZ = lampZ + 48
		end
	end

	-- ── Perimeter neon border (defines map edges) ─────────────────────────────
	local borderColor = Color3.fromRGB(255, 210, 50)  -- gold
	local bx = mapWidth / 2 - 2
	local bz = mapLength / 2 - 2
	for _, data in ipairs({
		{ pos = Vector3.new(0,  0.3,  bz), sz = Vector3.new(mapWidth - 4, 0.22, 0.28) },
		{ pos = Vector3.new(0,  0.3, -bz), sz = Vector3.new(mapWidth - 4, 0.22, 0.28) },
		{ pos = Vector3.new( bx, 0.3, 0),  sz = Vector3.new(0.28, 0.22, mapLength - 4) },
		{ pos = Vector3.new(-bx, 0.3, 0),  sz = Vector3.new(0.28, 0.22, mapLength - 4) },
	}) do
		make("Part", {
			Name = "PerimeterBorder",
			Anchored = true, CanCollide = false,
			Material = Enum.Material.Neon,
			Color = borderColor,
			Transparency = 0.48,
			Size = data.sz,
			CFrame = CFrame.new(data.pos),
		}, basesFolder)
	end

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

-- Creates a single extra display slot on an already-assigned plot.
-- Called when a player rebirths and earns an additional slot.
function BaseService.AddDisplaySlot(plot, slotIndex)
	if not plot then return end
	local localOffset = ALL_SLOT_OFFSETS[slotIndex]
	if not localOffset then return end
	if plot.displaySlots[slotIndex] then return end  -- already exists

	local displayFolder = plot.model:FindFirstChild("DisplaySlots")
	if not displayFolder then return end

	local fd  = plot.facingDirection
	local worldOffset = resolveDisplaySlotOffset(localOffset, fd, slotIndex)
	local pedestalSizeZ = slotIndex > 6 and 3 or nil
	local slot = createDisplaySlot(
		displayFolder, slotIndex,
		plot.baseCFrame * CFrame.new(worldOffset),
		slotLookDir(localOffset, fd, slotIndex),
		pedestalSizeZ
	)
	plot.displaySlots[slotIndex] = slot
	return slot
end

function BaseService.SetDisplaySlotLimit(plot, slotCount)
	if not plot or not plot.displaySlots then
		return
	end

	slotCount = math.clamp(slotCount or layout.DisplaySlotCount, layout.DisplaySlotCount, Constants.Rebirth.MaxSlots)
	for index, slot in pairs(plot.displaySlots) do
		if index > slotCount then
			clearDisplayCard(slot)
			if slot.model and slot.model.Parent then
				slot.model:Destroy()
			end
			plot.displaySlots[index] = nil
		end
	end
end

function BaseService.UpdateRebirthMultiplier(plot, multiplier)
	if not plot or not plot.rebirthMultiplierGui or not plot.rebirthMultiplierLabel then
		return
	end

	if not plot.ownerPlayer or not multiplier then
		plot.rebirthMultiplierGui.Enabled = false
		plot.rebirthMultiplierLabel.Text = "1x FANS"
		return
	end

	plot.rebirthMultiplierLabel.Text = formatFanMultiplier(multiplier)
	plot.rebirthMultiplierGui.Enabled = true
end

function BaseService.AssignPlot(player, rebirthTier, baseSlots)
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
			BaseService.UpdateRebirthMultiplier(plot, 1)
			updatePadLabel(plot, "Rolling Pack", "Preparing your next spawn", Color3.fromRGB(255, 170, 48))
			assignedPlots[player] = plot
			if plot.spawnLocation then
				player.RespawnLocation = plot.spawnLocation
			end
			-- Build any extra slots the player has earned through rebirths
			local slotCount = math.min(baseSlots or 6, Constants.Rebirth.MaxSlots)
			local visualTier = math.max(rebirthTier or 0, slotCount > layout.DisplaySlotCount and 1 or 0)
			BaseService.UpdateStadiumTier(plot, visualTier)
			for i = layout.DisplaySlotCount + 1, slotCount do
				BaseService.AddDisplaySlot(plot, i)
			end

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
	BaseService.UpdateRebirthMultiplier(plot, nil)
	BaseService.UpdateStadiumTier(plot, 0)
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

function BaseService.UpdatePackMilestone(plot, totalPacks, claimedMilestones, queuedRewardCount)
	if not plot or not plot.milestonePacksLabel or not plot.milestoneNextLabel or not plot.milestoneBarFill then
		return
	end

	totalPacks = math.max(0, totalPacks or 0)
	claimedMilestones = claimedMilestones or {}
	queuedRewardCount = math.max(0, tonumber(queuedRewardCount) or 0)

	local ms = getNextPackMilestone(totalPacks)
	local nearMilestone = ms.progress >= 0.80
	local milestoneColor = ms.color or Color3.fromRGB(255, 215, 0)

	-- Hero counter
	if queuedRewardCount > 0 then
		plot.milestonePacksLabel.Text = Utils.FormatNumber(totalPacks) .. " PACKS OPENED  |  " .. tostring(queuedRewardCount) .. " QUEUED"
	else
		plot.milestonePacksLabel.Text = Utils.FormatNumber(totalPacks) .. " PACKS OPENED"
	end

	-- Next reward line
	plot.milestoneNextLabel.Text = "NEXT: " .. string.upper(ms.reward)
	plot.milestoneNextLabel.TextColor3 = nearMilestone and Color3.fromRGB(255, 250, 220) or milestoneColor

	-- Progress bar + % label
	local pct = math.floor(ms.progress * 100)
	plot.milestoneBarFill.Size = UDim2.fromScale(ms.progress, 1)
	plot.milestoneBarFill.BackgroundColor3 = milestoneColor
	if plot.milestoneBarPct then
		plot.milestoneBarPct.Text = string.format(
			"%s / %s  (%d%%)",
			Utils.FormatNumber(ms.progressCount),
			Utils.FormatNumber(ms.threshold),
			pct
		)
		plot.milestoneBarPct.TextColor3 = nearMilestone and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 248, 220)
	end
	if plot.milestoneLight then
		plot.milestoneLight.Color = milestoneColor
		plot.milestoneLight.Brightness = nearMilestone and 1.25 or 0.5
		plot.milestoneLight.Range = nearMilestone and 34 or 22
	end

	-- Reward icons: flash the just-hit cycle, then return to tracking the next loop.
	if plot.milestoneIconFrames then
		for _, entry in ipairs(plot.milestoneIconFrames) do
			if entry.tick then
				local T       = entry.threshold
				local key = nil
				for _, milestone in ipairs(packMilestones or {}) do
					if milestone.threshold == T then
						key = milestone.id or tostring(T)
						break
					end
				end
				local claimed = key and claimedMilestones[key] or claimedMilestones[tostring(T)]
				if claimed == true then claimed = 1 end
				claimed = tonumber(claimed) or 0
				entry.tick.Visible = claimed > 0 and totalPacks > 0 and (totalPacks % T == 0)
			end
			if entry.card then
				entry.card.BackgroundColor3 = entry.threshold == ms.threshold and Color3.fromRGB(20, 26, 42) or Color3.fromRGB(12, 16, 28)
			end
		end
	end
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
	setSlotHalo(slot, SLOT_HALO_OCCUPIED)
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

	BaseService.ConfigurePlayerCharacterCollision(targetCharacter)
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
