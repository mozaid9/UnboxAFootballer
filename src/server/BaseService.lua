local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Utils = require(ReplicatedStorage.Shared.Utils)

local BaseService = {}

local layout = Constants.BaseLayout
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
	Lighting.ClockTime = 20.15
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(38, 45, 58)
	Lighting.OutdoorAmbient = Color3.fromRGB(24, 30, 42)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.FogColor = Color3.fromRGB(18, 25, 38)
	Lighting.FogStart = 240
	Lighting.FogEnd = 620

	replaceLightingEffect("Atmosphere", "UnboxNightAtmosphere", {
		Density = 0.24,
		Offset = 0.08,
		Color = Color3.fromRGB(165, 185, 210),
		Decay = Color3.fromRGB(18, 22, 32),
		Glare = 0.25,
		Haze = 1.7,
	})

	replaceLightingEffect("BloomEffect", "UnboxGoldBloom", {
		Intensity = 0.55,
		Size = 28,
		Threshold = 1.25,
	})

	replaceLightingEffect("ColorCorrectionEffect", "UnboxColorGrade", {
		Brightness = -0.04,
		Contrast = 0.16,
		Saturation = 0.08,
		TintColor = Color3.fromRGB(235, 242, 255),
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
		Color = Color3.fromRGB(53, 61, 76),
		Size = size,
		CFrame = cframe,
	}, parent)
end

local function createStadiumWedge(parent, size, cframe)
	make("WedgePart", {
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(66, 75, 92),
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

	createGlowStrip(model, "PlanterTrim", Vector3.new(4.5, 0.14, 4.5) * scale, CFrame.new(position + Vector3.new(0, 1.25 * scale, 0)), Color3.fromRGB(255, 183, 53), 0.35)
	return model
end

local function createFloodlightRig(parent, name, position, targetPosition)
	local model = make("Model", {
		Name = name,
	}, parent)

	local poleHeight = 28
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
		Size = Vector3.new(11, 5.5, 0.55),
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
				Color = Color3.fromRGB(245, 245, 235),
				Size = Vector3.new(1.25, 1.25, 0.35),
				CFrame = panel.CFrame * CFrame.new(x, y, -0.38),
			}, model)
		end
	end

	make("SpotLight", {
		Name = "FloodBeam",
		Face = Enum.NormalId.Front,
		Color = Color3.fromRGB(255, 245, 218),
		Range = 170,
		Angle = 72,
		Brightness = 4.6,
		Shadows = true,
	}, panel)

	return model
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
	createGlowStrip(model, "BannerGlow", Vector3.new(5.2, 0.18, 0.5), banner.CFrame * CFrame.new(0, -4.45, -0.08), Color3.fromRGB(255, 215, 0), 0.1)

	return model
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
		Size = Vector3.new(30, 5, 0.5),
		CFrame = CFrame.lookAt(center + Vector3.new(0, 15.2, -facingDirection * 0.3), center + Vector3.new(0, 15.2, -facingDirection * 0.3) + lookDirection),
	}, gate)
	createSurfaceText(sign, "WELCOME FANS", "TURNSTILES")

	for index = 1, 3 do
		local x = -8 + ((index - 1) * 8)
		createTurnstile(gate, CFrame.new(center + Vector3.new(x, 2.1, -facingDirection * 2)))
		createGlowStrip(gate, "GateLight" .. index, Vector3.new(4.2, 0.18, 1.4), CFrame.new(center + Vector3.new(x, 0.2, -facingDirection * 5.2)), Color3.fromRGB(65, 255, 112), 0.05)
	end

	return gate
end

local function createFanPlaza(mapWidth, mapLength)
	local plaza = make("Model", {
		Name = "FanPlaza",
	}, basesFolder)

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
		Color = Color3.fromRGB(34, 41, 55),
		Size = Vector3.new(54, 0.18, mapLength - 64),
		CFrame = CFrame.new(0, 0.24, 0),
	}, plaza)

	createGlowStrip(plaza, "MainGoldLineLeft", Vector3.new(0.35, 0.22, mapLength - 78), CFrame.new(-29, 0.38, 0), Color3.fromRGB(255, 215, 0), 0.12)
	createGlowStrip(plaza, "MainGoldLineRight", Vector3.new(0.35, 0.22, mapLength - 78), CFrame.new(29, 0.38, 0), Color3.fromRGB(255, 215, 0), 0.12)
	createGlowStrip(plaza, "MainCenterGlow", Vector3.new(8, 0.18, mapLength - 100), CFrame.new(0, 0.36, 0), Color3.fromRGB(255, 180, 46), 0.82)

	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		make("Part", {
			Name = "StadiumPath" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(36, 43, 56),
			Size = Vector3.new((layout.SideOffset * 2) - 22, 0.14, 14),
			CFrame = CFrame.new(0, 0.28, laneZ),
		}, plaza)
		createGlowStrip(plaza, "StadiumPathGoldA" .. laneIndex, Vector3.new((layout.SideOffset * 2) - 28, 0.18, 0.25), CFrame.new(0, 0.42, laneZ - 7), Color3.fromRGB(255, 215, 0), 0.2)
		createGlowStrip(plaza, "StadiumPathGoldB" .. laneIndex, Vector3.new((layout.SideOffset * 2) - 28, 0.18, 0.25), CFrame.new(0, 0.42, laneZ + 7), Color3.fromRGB(255, 215, 0), 0.2)
	end

	local statueBase = make("Part", {
		Name = "FanPlazaPedestal",
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 23, 34),
		Size = Vector3.new(22, 1.1, 22),
		CFrame = CFrame.new(0, 0.9, 0),
	}, plaza)
	_ = statueBase

	createGlowStrip(plaza, "PedestalGlow", Vector3.new(24, 0.22, 24), CFrame.new(0, 1.52, 0), Color3.fromRGB(255, 215, 0), 0.22)
	createGlowStrip(plaza, "OuterPedestalGlow", Vector3.new(34, 0.16, 34), CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 180, 48), 0.64)

	local ball = make("Part", {
		Name = "GoldFootball",
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(255, 202, 61),
		Size = Vector3.new(8, 8, 8),
		CFrame = CFrame.new(0, 6.0, 0),
	}, plaza)

	make("PointLight", {
		Color = Color3.fromRGB(255, 215, 0),
		Range = 34,
		Brightness = 1.8,
		Shadows = false,
	}, ball)

	local plazaSign = make("Part", {
		Name = "FanPlazaSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(18, 3.2, 0.5),
		CFrame = CFrame.lookAt(Vector3.new(0, 3.2, -13), Vector3.new(0, 3.2, -40)),
	}, plaza)
	createSurfaceText(plazaSign, "FAN PLAZA", "")

	createFanGate(plaza, "NorthFanGate", northZ, -1)
	createFanGate(plaza, "SouthFanGate", southZ, 1)

	local bannerConfigs = {
		{ position = Vector3.new(-24, 0, -20), title = "FANS" },
		{ position = Vector3.new(24, 0, -20), title = "PACKS" },
		{ position = Vector3.new(-24, 0, 20), title = "CLUB" },
		{ position = Vector3.new(24, 0, 20), title = "STARS" },
	}
	for index, config in ipairs(bannerConfigs) do
		createVerticalBanner(plaza, "PlazaBanner" .. index, config.position, Vector3.new(0, 6, 0), config.title)
	end

	local planterPositions = {
		Vector3.new(-34, 0, -28),
		Vector3.new(34, 0, -28),
		Vector3.new(-34, 0, 28),
		Vector3.new(34, 0, 28),
		Vector3.new(-18, 0, northZ - 18),
		Vector3.new(18, 0, northZ - 18),
		Vector3.new(-18, 0, southZ + 18),
		Vector3.new(18, 0, southZ + 18),
	}
	for _, planterPosition in ipairs(planterPositions) do
		createPlanter(plaza, planterPosition, 0.9)
	end

	createFloodlightRig(plaza, "NorthWestFloodlight", Vector3.new(-50, 0, northZ - 18), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "NorthEastFloodlight", Vector3.new(50, 0, northZ - 18), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "SouthWestFloodlight", Vector3.new(-50, 0, southZ + 18), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "SouthEastFloodlight", Vector3.new(50, 0, southZ + 18), Vector3.new(0, 2, 0))

	createWaypoint(waypointFolder, "NorthGate", Vector3.new(0, 2.2, northZ - 10))
	createWaypoint(waypointFolder, "SouthGate", Vector3.new(0, 2.2, southZ + 10))
	createWaypoint(waypointFolder, "Center", Vector3.new(0, 2.2, 0))
	createWaypoint(waypointFolder, "WestLoop", Vector3.new(-16, 2.2, 0))
	createWaypoint(waypointFolder, "EastLoop", Vector3.new(16, 2.2, 0))

	startTurnstileAnimations()
	return plaza
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
		Color = Color3.fromRGB(55, 127, 67),
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	local trimY = layout.PlotSize.Y / 2 + 0.62
	createGlowStrip(model, "FrontGoldTrim", Vector3.new(0.32, 0.16, layout.PlotSize.Z - 3), baseCFrame * CFrame.new(frontEdgeX - (facingDirection * 0.8), trimY, 0), Color3.fromRGB(255, 200, 62), 0.16)
	createGlowStrip(model, "BackGoldTrim", Vector3.new(0.28, 0.12, layout.PlotSize.Z - 4), baseCFrame * CFrame.new(backEdgeX + (facingDirection * 0.8), trimY, 0), Color3.fromRGB(255, 190, 52), 0.45)
	createGlowStrip(model, "NorthGoldTrim", Vector3.new(layout.PlotSize.X - 4, 0.14, 0.28), baseCFrame * CFrame.new(0, trimY, -layout.PlotSize.Z / 2 + 0.9), Color3.fromRGB(255, 190, 52), 0.24)
	createGlowStrip(model, "SouthGoldTrim", Vector3.new(layout.PlotSize.X - 4, 0.14, 0.28), baseCFrame * CFrame.new(0, trimY, layout.PlotSize.Z / 2 - 0.9), Color3.fromRGB(255, 190, 52), 0.24)

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

	local packStage = make("Part", {
		Name = "PackStageGlow",
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 0),
		Transparency = 0.42,
		Size = Vector3.new(14, 0.25, 14),
		CFrame = packPad.CFrame * CFrame.new(0, -0.36, 0),
	}, model)
	_ = packStage

	make("PointLight", {
		Name = "PackStageLight",
		Color = Color3.fromRGB(255, 210, 80),
		Range = 22,
		Brightness = 1.15,
		Shadows = false,
	}, packPad)

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

	make("PointLight", {
		Name = "OwnerSignGlow",
		Color = Color3.fromRGB(255, 211, 86),
		Range = 22,
		Brightness = 1.15,
		Shadows = false,
	}, ownerSign)

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
	animatedTurnstiles = {}
	configureMapLighting()

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

	createFanPlaza(mapWidth, mapLength)

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
