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
	Lighting.Brightness = 2.05
	Lighting.Ambient = Color3.fromRGB(44, 52, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(34, 42, 60)
	Lighting.EnvironmentDiffuseScale = 0.42
	Lighting.EnvironmentSpecularScale = 0.58
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
		Intensity = 0.16,
		Size = 12,
		Threshold = 2.05,
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

	local poleHeight = 30
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

	make("SpotLight", {
		Name = "FloodBeam",
		Face = Enum.NormalId.Front,
		Color = Color3.fromRGB(255, 245, 218),
		Range = 118,
		Angle = 56,
		Brightness = 1.15,
		Shadows = false,
	}, panel)

	make("PointLight", {
		Name = "FloodFill",
		Color = Color3.fromRGB(255, 235, 190),
		Range = 24,
		Brightness = 0.08,
		Shadows = false,
	}, panel)

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
		Range = 56,
		Angle = 46,
		Brightness = 0.62,
		Shadows = false,
	}, head)

	make("PointLight", {
		Name = "PostFill",
		Color = Color3.fromRGB(255, 220, 150),
		Range = 12,
		Brightness = 0.2,
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
		createGlowStrip(gate, "GateLight" .. index, Vector3.new(4.2, 0.18, 1.4), CFrame.new(center + Vector3.new(x, 0.2, -facingDirection * 5.2)), Color3.fromRGB(65, 255, 112), 0.05)
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
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 183, 53),
		Transparency = 0.18,
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

	make("PointLight", {
		Color = Color3.fromRGB(255, 175, 68),
		Range = 24,
		Brightness = 1.4,
		Shadows = false,
	}, sign)

	return model
end

local function createFoodKiosk(parent, name, position, signText, facingPos)
	local isDrinkStall = string.find(string.upper(signText), "DRINK") ~= nil
	local assetId = isDrinkStall and fanZoneConfig.KioskAssets.Drink or fanZoneConfig.KioskAssets.Food
	local importedModel = tryCreateImportedKiosk(parent, name, position, signText, facingPos, assetId)
	if importedModel then
		return importedModel
	end

	local model = make("Model", { Name = name }, parent)

	local flatFacing = Vector3.new(facingPos.X, 0, facingPos.Z)
	local boothCF = CFrame.lookAt(position + Vector3.new(0, 2.1, 0), flatFacing + Vector3.new(0, 2.1, 0))

	-- Main booth body — bright red so it pops against the dark plaza
	make("Part", {
		Name = "Booth",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(168, 38, 24),
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

	-- Canopy — bright yellow base
	make("Part", {
		Name = "Canopy",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(252, 210, 0),
		Size = Vector3.new(8.0, 0.40, 4.6),
		CFrame = boothCF * CFrame.new(0, 2.38, 0.95),
	}, model)

	-- Three red stripes across the canopy — classic market-stall look
	for i = 1, 3 do
		make("Part", {
			Name = "CanopyStripe" .. i,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(208, 30, 18),
			Size = Vector3.new(8.0, 0.42, 0.62),
			CFrame = boothCF * CFrame.new(0, 2.39, -1.0 + (i - 1) * 1.08),
		}, model)
	end

	-- Large neon sign above the canopy — highly visible from a distance
	local sign = make("Part", {
		Name = "KioskSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(255, 170, 40),
		Transparency = 0.12,
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
		TextColor3 = Color3.fromRGB(28, 10, 0),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, signGui)

	-- Bright warm light spills onto nearby NPCs
	make("PointLight", {
		Color = Color3.fromRGB(255, 158, 42),
		Range = 12,
		Brightness = 0.45,
		Shadows = false,
	}, sign)

	-- Gold neon strip along the canopy front lip
	createGlowStrip(
		model,
		"CanopyTrim",
		Vector3.new(8.2, 0.18, 0.22),
		boothCF * CFrame.new(0, 2.19, 3.22),
		Color3.fromRGB(255, 200, 40),
		0.42
	)

	return model
end

local function createFanZone(mapWidth, mapLength)
	local plaza = make("Model", {
		Name = "FanZone",
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
		Color = Color3.fromRGB(46, 54, 70),
		Size = Vector3.new(54, 0.18, mapLength - 64),
		CFrame = CFrame.new(0, 0.24, 0),
	}, plaza)

	createGlowStrip(plaza, "MainGoldLineLeft", Vector3.new(0.35, 0.22, mapLength - 78), CFrame.new(-29, 0.38, 0), Color3.fromRGB(255, 215, 0), 0.55)
	createGlowStrip(plaza, "MainGoldLineRight", Vector3.new(0.35, 0.22, mapLength - 78), CFrame.new(29, 0.38, 0), Color3.fromRGB(255, 215, 0), 0.55)
	createGlowStrip(plaza, "MainCenterGlow", Vector3.new(8, 0.18, mapLength - 100), CFrame.new(0, 0.36, 0), Color3.fromRGB(255, 180, 46), 0.94)

	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		make("Part", {
			Name = "StadiumPath" .. laneIndex,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(48, 56, 72),
			Size = Vector3.new((layout.SideOffset * 2) - 22, 0.14, 14),
			CFrame = CFrame.new(0, 0.28, laneZ),
		}, plaza)
		createGlowStrip(plaza, "StadiumPathGoldA" .. laneIndex, Vector3.new((layout.SideOffset * 2) - 28, 0.18, 0.25), CFrame.new(0, 0.42, laneZ - 7), Color3.fromRGB(255, 215, 0), 0.64)
		createGlowStrip(plaza, "StadiumPathGoldB" .. laneIndex, Vector3.new((layout.SideOffset * 2) - 28, 0.18, 0.25), CFrame.new(0, 0.42, laneZ + 7), Color3.fromRGB(255, 215, 0), 0.64)
	end

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
	createGlowStrip(plaza, "Tier1Ring", Vector3.new(26, 0.18, 26), CFrame.new(0, 3.28, 0), Color3.fromRGB(255, 215, 0), 0.18)

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
	createGlowStrip(plaza, "Tier2Ring", Vector3.new(18, 0.16, 18), CFrame.new(0, 6.0, 0), Color3.fromRGB(255, 215, 0), 0.22)

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
	createGlowStrip(plaza, "Tier3Ring", Vector3.new(12, 0.16, 12), CFrame.new(0, 8.52, 0), Color3.fromRGB(255, 215, 0), 0.25)

	-- Ground-level glow halos
	createGlowStrip(plaza, "OuterPedestalGlow", Vector3.new(40, 0.15, 40), CFrame.new(0, 0.46, 0), Color3.fromRGB(255, 175, 44), 0.65)
	createGlowStrip(plaza, "InnerPedestalGlow", Vector3.new(28, 0.18, 28), CFrame.new(0, 0.50, 0), Color3.fromRGB(255, 215, 0), 0.35)

	-- ── Planter ring around the podium ────────────────────────────────
	-- Six smaller planters form a decorative circle at radius 17, just
	-- outside the Tier1 ring (radius ≈ 12).
	local RING_RADIUS = 17
	local RING_COUNT = 6
	for ringIndex = 1, RING_COUNT do
		local angle = math.rad((ringIndex - 1) * (360 / RING_COUNT))
		createPlanter(plaza, Vector3.new(math.cos(angle) * RING_RADIUS, 0, math.sin(angle) * RING_RADIUS), 0.52)
	end

	-- Gold football sitting on the top plinth (centre at Y=12.0, radius=3.5 → bottom Y=8.5)
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
		Range = 26,
		Brightness = 0.85,
		Shadows = false,
	}, ball)

	-- Slow spin + tilt so the ball looks like it's rolling in the air
	task.spawn(function()
		local ballAngle = 0
		local ballBaseY = 12.0
		while ball.Parent do
			ballAngle = ballAngle + math.rad(20) / 30 -- ≈ 20°/s
			local floatOffset = math.sin(os.clock() * 0.85) * 0.38
			ball.CFrame = CFrame.new(0, ballBaseY + floatOffset, 0)
				* CFrame.Angles(math.rad(22), ballAngle, 0)
			task.wait(1 / 30)
		end
	end)

	local plazaSign = make("Part", {
		Name = "FanZoneSign",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(18, 3.2, 0.5),
		CFrame = CFrame.lookAt(Vector3.new(0, 3.2, -13), Vector3.new(0, 3.2, -40)),
	}, plaza)
	createSurfaceText(plazaSign, "FAN ZONE", "")

	createFanGate(plaza, "NorthFanGate", northZ, -1)
	createFanGate(plaza, "SouthFanGate", southZ, 1)

	-- ── Food & drinks kiosks ──────────────────────────────────────────
	-- Two stalls flank each gate entrance.  NPCs detour here, pause to
	-- "buy something", then carry on through the Fan Zone.
	local kioskInset = 22   -- studs inside from each gate (toward Z=0)
	local kioskX    = 12   -- studs either side of the central walkway
	local walkwayX  = 0    -- the central path that NPCs walk along

	-- North pair (just inside the north gate, facing the walkway center)
	-- Y=0.35 sits the booth base flush on the plaza surface (top ≈ Y=0.33)
	createFoodKiosk(plaza, "KioskNorthWest",
		Vector3.new(-kioskX, 0.35, northZ - kioskInset),
		"HOT DOGS",
		Vector3.new(walkwayX, 0.35, northZ - kioskInset))

	createFoodKiosk(plaza, "KioskNorthEast",
		Vector3.new(kioskX, 0.35, northZ - kioskInset),
		"DRINKS",
		Vector3.new(walkwayX, 0.35, northZ - kioskInset))

	-- South pair (just inside the south gate, facing the walkway center)
	createFoodKiosk(plaza, "KioskSouthWest",
		Vector3.new(-kioskX, 0.35, southZ + kioskInset),
		"SNACKS",
		Vector3.new(walkwayX, 0.35, southZ + kioskInset))

	createFoodKiosk(plaza, "KioskSouthEast",
		Vector3.new(kioskX, 0.35, southZ + kioskInset),
		"COLD DRINKS",
		Vector3.new(walkwayX, 0.35, southZ + kioskInset))

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

	createSoftFillLight(plaza, "CenterPlazaFill", Vector3.new(0, 13, 0), 84, 0.34, Color3.fromRGB(255, 225, 170))
	createSoftFillLight(plaza, "NorthPlazaFill", Vector3.new(0, 13, northZ - 8), 70, 0.24, Color3.fromRGB(230, 238, 255))
	createSoftFillLight(plaza, "SouthPlazaFill", Vector3.new(0, 13, southZ + 8), 70, 0.24, Color3.fromRGB(230, 238, 255))
	createSoftFillLight(plaza, "WestPlazaFill", Vector3.new(-layout.SideOffset + 20, 12, 0), 76, 0.22, Color3.fromRGB(255, 232, 185))
	createSoftFillLight(plaza, "EastPlazaFill", Vector3.new(layout.SideOffset - 20, 12, 0), 76, 0.22, Color3.fromRGB(255, 232, 185))

	createFloodlightRig(plaza, "NorthWestFloodlight", Vector3.new(-54, 0, northZ - 22), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "NorthEastFloodlight", Vector3.new(54, 0, northZ - 22), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "SouthWestFloodlight", Vector3.new(-54, 0, southZ + 22), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "SouthEastFloodlight", Vector3.new(54, 0, southZ + 22), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "CenterWestFloodlight", Vector3.new(-72, 0, 0), Vector3.new(0, 2, 0))
	createFloodlightRig(plaza, "CenterEastFloodlight", Vector3.new(72, 0, 0), Vector3.new(0, 2, 0))

	for laneIndex = 1, layout.PlotsPerSide do
		local laneZ = layout.StartZ + ((laneIndex - 1) * layout.PlotSpacing)
		createLightPost(plaza, "LaneWestLightA" .. laneIndex, Vector3.new(-36, 0, laneZ - 12), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneWestLightB" .. laneIndex, Vector3.new(-36, 0, laneZ + 12), Vector3.new(-layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightA" .. laneIndex, Vector3.new(36, 0, laneZ - 12), Vector3.new(layout.SideOffset, 1, laneZ))
		createLightPost(plaza, "LaneEastLightB" .. laneIndex, Vector3.new(36, 0, laneZ + 12), Vector3.new(layout.SideOffset, 1, laneZ))
	end

	createWaypoint(waypointFolder, "NorthGate", Vector3.new(0, 3.1, northZ - 10))
	createWaypoint(waypointFolder, "SouthGate", Vector3.new(0, 3.1, southZ + 10))
	createWaypoint(waypointFolder, "Center", Vector3.new(0, 3.1, 0))
	createWaypoint(waypointFolder, "WestLoop", Vector3.new(-16, 3.1, 0))
	createWaypoint(waypointFolder, "EastLoop", Vector3.new(16, 3.1, 0))
	-- Food stand stops: close to the serving counters, not the walkway centre.
	-- Keep the old center names too as safe fallbacks for older crowd routes.
	createWaypoint(waypointFolder, "FoodNorth", Vector3.new(0, 3.1, northZ - 26))
	createWaypoint(waypointFolder, "FoodSouth", Vector3.new(0, 3.1, southZ + 26))
	createWaypoint(waypointFolder, "FoodNorthWest", Vector3.new(-6.2, 3.1, northZ - kioskInset))
	createWaypoint(waypointFolder, "FoodNorthEast", Vector3.new(6.2, 3.1, northZ - kioskInset))
	createWaypoint(waypointFolder, "FoodSouthWest", Vector3.new(-6.2, 3.1, southZ + kioskInset))
	createWaypoint(waypointFolder, "FoodSouthEast", Vector3.new(6.2, 3.1, southZ + kioskInset))

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
		Color = Color3.fromRGB(34, 170, 94),
		Transparency = 0.14,
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
		Color = Color3.fromRGB(76, 158, 82),
		Size = layout.PlotSize,
		CFrame = baseCFrame,
	}, model)

	local trimY = layout.PlotSize.Y / 2 + 0.62
	createGlowStrip(model, "FrontGoldTrim", Vector3.new(0.32, 0.16, layout.PlotSize.Z - 3), baseCFrame * CFrame.new(frontEdgeX - (facingDirection * 0.8), trimY, 0), Color3.fromRGB(255, 200, 62), 0.4)
	createGlowStrip(model, "BackGoldTrim", Vector3.new(0.28, 0.12, layout.PlotSize.Z - 4), baseCFrame * CFrame.new(backEdgeX + (facingDirection * 0.8), trimY, 0), Color3.fromRGB(255, 190, 52), 0.58)
	createGlowStrip(model, "NorthGoldTrim", Vector3.new(layout.PlotSize.X - 4, 0.14, 0.28), baseCFrame * CFrame.new(0, trimY, -layout.PlotSize.Z / 2 + 0.9), Color3.fromRGB(255, 190, 52), 0.48)
	createGlowStrip(model, "SouthGoldTrim", Vector3.new(layout.PlotSize.X - 4, 0.14, 0.28), baseCFrame * CFrame.new(0, trimY, layout.PlotSize.Z / 2 - 0.9), Color3.fromRGB(255, 190, 52), 0.48)

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
		Color = Color3.fromRGB(192, 196, 194),
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
		Transparency = 0.7,
		Size = Vector3.new(14, 0.25, 14),
		CFrame = packPad.CFrame * CFrame.new(0, -0.36, 0),
	}, model)
	_ = packStage

	make("PointLight", {
		Name = "PackStageLight",
		Color = Color3.fromRGB(255, 210, 80),
		Range = 10,
		Brightness = 0.22,
		Shadows = false,
	}, packPad)

	local spawnPad = make("Part", {
		Name = "SpawnPad",
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(192, 196, 194),
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

	local milestoneSignPosition = position
		+ Vector3.new(backEdgeX - (facingDirection * 7.2), 5.2, 0)
	local milestoneSign = make("Part", {
		Name = "PackMilestoneBillboard",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(8, 12, 20),
		Size = Vector3.new(14.5, 5.2, 0.5),
		CFrame = CFrame.lookAt(milestoneSignPosition, milestoneSignPosition + centerDirection),
	}, model)

	local milestoneGui = make("SurfaceGui", {
		Face = Enum.NormalId.Front,
		PixelsPerStud = 95,
		LightInfluence = 0,
	}, milestoneSign)

	local milestoneFrame = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(9, 13, 22),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, milestoneGui)

	make("UIStroke", {
		Color = Color3.fromRGB(255, 215, 0),
		Thickness = 2,
		Transparency = 0.15,
	}, milestoneFrame)

	local milestoneTitleLabel = createOwnerSignText("PACK MILESTONES", UDim2.fromScale(0.9, 0.18), UDim2.fromScale(0.05, 0.08), Color3.fromRGB(255, 215, 0), {
		textScaled = true,
		minTextSize = 18,
		maxTextSize = 48,
		textStrokeTransparency = 0.7,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)
	_ = milestoneTitleLabel

	local milestonePacksLabel = createOwnerSignText("0 PACKS OPENED", UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.07, 0.3), Color3.fromRGB(245, 238, 220), {
		textScaled = true,
		minTextSize = 20,
		maxTextSize = 64,
		textStrokeTransparency = 0.72,
		font = Enum.Font.GothamBlack,
	}, milestoneFrame)

	local milestoneNextLabel = createOwnerSignText("NEXT: 50 - RARE PACK", UDim2.fromScale(0.84, 0.14), UDim2.fromScale(0.08, 0.58), Color3.fromRGB(190, 184, 164), {
		textScaled = true,
		minTextSize = 14,
		maxTextSize = 34,
		textStrokeTransparency = 0.84,
		font = Enum.Font.GothamBold,
	}, milestoneFrame)

	local milestoneBarBack = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(35, 40, 54),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.78, 0.075),
		Position = UDim2.fromScale(0.11, 0.78),
	}, milestoneFrame)
	make("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}, milestoneBarBack)

	local milestoneBarFill = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	}, milestoneBarBack)
	make("UICorner", {
		CornerRadius = UDim.new(0, 8),
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
	createLightPost(model, "EntranceLightSouth", position + Vector3.new(entranceLightX, 0, entranceWidth / 2 + 6), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "BackStandLightNorth", position + Vector3.new(backEdgeX - (facingDirection * 8), 0, -(layout.PlotSize.Z / 2 + 5)), packPad.Position + Vector3.new(0, 2, 0))
	createLightPost(model, "BackStandLightSouth", position + Vector3.new(backEdgeX - (facingDirection * 8), 0, layout.PlotSize.Z / 2 + 5), packPad.Position + Vector3.new(0, 2, 0))
	createSoftFillLight(model, "StadiumSoftFill", position + Vector3.new(0, 12, 0), 30, 0.12, Color3.fromRGB(255, 232, 184))

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
	BaseService.UpdatePackMilestone(plot, 0)
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

function BaseService.UpdatePackMilestone(plot, totalPacks)
	if not plot or not plot.milestonePacksLabel or not plot.milestoneNextLabel or not plot.milestoneBarFill then
		return
	end

	totalPacks = math.max(0, totalPacks or 0)
	local milestone = getNextPackMilestone(totalPacks)
	plot.milestonePacksLabel.Text = Utils.FormatNumber(totalPacks) .. " PACKS OPENED"
	plot.milestoneNextLabel.Text = string.format("NEXT: %d - %s", milestone.nextAt, string.upper(milestone.reward))
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
		Range = 7,
		Brightness = 0.45,
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
