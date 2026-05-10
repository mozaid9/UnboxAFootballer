local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, child in ipairs(script.Parent:GetChildren()) do
	if child:IsA("LocalScript") and child ~= script and child.Name == script.Name then
		child.Disabled = true
	end
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local CardFrames = require(Shared:WaitForChild("CardFrames"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local UpdateCoinsEvent = Remotes:WaitForChild("UpdateCoins")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")
local PackOpenFailedEvent = Remotes:WaitForChild("PackOpenFailed")
local PromptPackShopEvent = Remotes:WaitForChild("PromptPackShop")
local PackHitFeedbackEvent = Remotes:WaitForChild("PackHitFeedback")
local MilestoneRewardEvent = Remotes:WaitForChild("MilestoneReward")
local ChoosePlayerPickFn = Remotes:WaitForChild("ChoosePlayerPick")
local QuestUpdatedEvent = Remotes:WaitForChild("QuestUpdated")

local UI = Constants.UI

local function make(className, props, parent)
	props = props or {}
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local existingGui = playerGui:FindFirstChild("PackOpeningUI")
if existingGui then
	existingGui:Destroy()
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local screenGui = make("ScreenGui", {
	Name = "PackOpeningUI",
	ResetOnSpawn = false,
	DisplayOrder = 8,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local hitSound = make("Sound", {
	Name = "PackHitSound",
	SoundId = "rbxasset://sounds/action_jump_land.mp3",
	Volume = 0.42,
	PlaybackSpeed = 0.82,
}, screenGui)

local finalBreakSound = make("Sound", {
	Name = "PackFinalBreakSound",
	SoundId = "rbxasset://sounds/action_jump_land.mp3",
	Volume = 0.34,
	PlaybackSpeed = 0.68,
}, screenGui)

local milestoneSound = make("Sound", {
	Name = "MilestoneRewardSound",
	SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.46,
	PlaybackSpeed = 0.92,
}, screenGui)

local watchedPlots = {}

local function getOwnedPlot()
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	if not basesFolder then
		return nil
	end

	for _, child in ipairs(basesFolder:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == player.UserId then
			return child
		end
	end

	return nil
end

local function snapCameraToOwnedBase(character)
	local camera = Workspace.CurrentCamera
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local plotModel = getOwnedPlot()
	local packPad = plotModel and plotModel:FindFirstChild("PackPad")
	if not camera or not rootPart or not humanoid or not packPad then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid

	local lookTarget = packPad.Position + Vector3.new(0, 3, 0)
	local forward = (lookTarget - rootPart.Position)
	if forward.Magnitude < 0.1 then
		return
	end
	forward = forward.Unit

	local cameraPosition = rootPart.Position - (forward * 12) + Vector3.new(0, 5, 0)
	camera.CFrame = CFrame.lookAt(cameraPosition, lookTarget)
end

local function applyPlotPadVisibility(plotModel)
	if not plotModel or not plotModel.Parent then
		return
	end

	local packPad = plotModel:FindFirstChild("PackPad")
	local padGui = packPad and packPad:FindFirstChild("PadGui")
	if padGui and padGui:IsA("BillboardGui") then
		padGui.Enabled = plotModel:GetAttribute("OwnerUserId") == player.UserId
	end
end

local function watchPlot(plotModel)
	if watchedPlots[plotModel] or not plotModel:IsA("Model") then
		return
	end

	watchedPlots[plotModel] = true
	applyPlotPadVisibility(plotModel)

	plotModel:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		applyPlotPadVisibility(plotModel)
	end)

	local packPad = plotModel:FindFirstChild("PackPad")
	if packPad then
		packPad.ChildAdded:Connect(function(child)
			if child.Name == "PadGui" then
				applyPlotPadVisibility(plotModel)
			end
		end)
	end
end

task.spawn(function()
	local basesFolder = Workspace:WaitForChild("PlayerBases", 10)
	if not basesFolder then
		return
	end

	for _, child in ipairs(basesFolder:GetChildren()) do
		watchPlot(child)
	end

	basesFolder.ChildAdded:Connect(function(child)
		watchPlot(child)
	end)
end)

local sidebar = make("Frame", {
	Name = "Sidebar",
	AnchorPoint = Vector2.new(0, 1),
	Size = UDim2.fromOffset(190, 338),
	Position = UDim2.new(0, 20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(5, 8, 15),
	BackgroundTransparency = 0.18,
}, screenGui)
addCorner(sidebar, 16)
addStroke(sidebar, UI.Gold, 1.5, 0.48)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 22, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 18)),
	}),
	Rotation = 110,
}, sidebar)

local sidebarPadding = make("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, sidebar)
_ = sidebarPadding

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

-- ── Wallet counters (bottom-left, concept style) ──────────────────────────────
local COUNTER_W, COUNTER_H = 210, 64

local function makeCounter(yOffset, iconEmoji, iconBg, labelText, accentColor)
	local panel = make("Frame", {
		Name = labelText .. "Counter",
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 13, 22),
		BackgroundTransparency = 0,
		Position = UDim2.new(1, -16, 1, yOffset),
		Size = UDim2.fromOffset(COUNTER_W, COUNTER_H),
		ZIndex = 10,
	}, screenGui)
	addCorner(panel, 14)
	addStroke(panel, accentColor, 1.5, 0.55)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 22, 36)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 18)),
		}),
		Rotation = 135,
	}, panel)

	-- Icon circle
	local iconCircle = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = iconBg,
		Position = UDim2.new(0, 36, 0.5, 0),
		Size = UDim2.fromOffset(44, 44),
		ZIndex = 11,
	}, panel)
	addCorner(iconCircle, 22)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, iconBg:Lerp(Color3.fromRGB(255,255,255), 0.18)),
			ColorSequenceKeypoint.new(1, iconBg:Lerp(Color3.fromRGB(0,0,0), 0.30)),
		}),
		Rotation = 135,
	}, iconCircle)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = iconEmoji,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 12,
	}, iconCircle)

	-- Label
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 88, 0, 10),
		Size = UDim2.new(1, -120, 0, 16),
		Text = string.upper(labelText),
		TextColor3 = Color3.fromRGB(160, 165, 180),
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
	}, panel)

	-- Value
	local valueLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 88, 0, 26),
		Size = UDim2.new(1, -120, 0, 28),
		Text = "0",
		TextColor3 = Color3.fromRGB(255, 252, 240),
		TextScaled = false,
		TextSize = 22,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
	}, panel)

	-- Plus button
	local plusBtn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(0,0,0), 0.38),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		Text = "+",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = true,
		ZIndex = 12,
	}, panel)
	addCorner(plusBtn, 8)
	addStroke(plusBtn, accentColor, 1.5, 0.30)

	return valueLabel, plusBtn
end

local fansLabel, addFansButton = makeCounter(-84, "👥", Color3.fromRGB(196, 152, 18), "Fans", UI.Gold)
local gemsLabel, addGemsButton = makeCounter(-14, "💎", Color3.fromRGB(24, 110, 196), "Gems", Color3.fromRGB(69, 207, 255))

-- walletDock kept as a no-op container so old references don't break
local walletDock = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0,0) }, screenGui)

local function makeIconLine(parent, position, size, color, rotation)
	return make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Position = position,
		Rotation = rotation or 0,
		Size = size,
	}, parent)
end

local function drawInventoryIcon(parent, accentColor)
	for index, props in ipairs({
		{ x = 17, y = 22, rot = -12, alpha = 0.25 },
		{ x = 22, y = 20, rot = 5, alpha = 0.08 },
		{ x = 26, y = 21, rot = 12, alpha = 0 },
	}) do
		local card = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(255, 255, 255), props.alpha),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(props.x, props.y),
			Rotation = props.rot,
			Size = UDim2.fromOffset(15, 22),
			ZIndex = 2 + index,
		}, parent)
		addCorner(card, 3)
		addStroke(card, accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.15), 1, 0.18)

		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(5, 14, 28),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.58, 0.52),
			Rotation = 45,
			Size = UDim2.fromOffset(5, 5),
			ZIndex = 4 + index,
		}, card)
	end
end

local function drawCollectionIcon(parent, accentColor)
	local book = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(5, 8, 16), 0.32),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(21, 22),
		Size = UDim2.fromOffset(25, 30),
		ZIndex = 2,
	}, parent)
	addCorner(book, 5)
	addStroke(book, accentColor, 2, 0.18)

	make("Frame", {
		BackgroundColor3 = accentColor,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, 4),
		Size = UDim2.fromOffset(3, 22),
		ZIndex = 3,
	}, book)

	for index = 1, 3 do
		make("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 250, 220),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 7 + (index - 1) * 7),
			Size = UDim2.fromOffset(9, 2),
			ZIndex = 3,
		}, book)
	end
end

local function drawUpgradeIcon(parent, accentColor)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(4, -2),
		Size = UDim2.fromOffset(34, 42),
		Text = "↑",
		TextColor3 = accentColor,
		TextScaled = false,
		TextSize = 34,
		Font = Enum.Font.GothamBlack,
		ZIndex = 3,
	}, parent)
end

local function drawQuestIcon(parent, accentColor)
	for _, diameter in ipairs({ 28, 18, 8 }) do
		local ring = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(19, 23),
			Size = UDim2.fromOffset(diameter, diameter),
			ZIndex = 2,
		}, parent)
		addCorner(ring, diameter / 2)
		addStroke(ring, accentColor, 2, diameter == 8 and 0 or 0.15)
	end

	makeIconLine(parent, UDim2.fromOffset(29, 13), UDim2.fromOffset(4, 20), accentColor, 42)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 2),
		Size = UDim2.fromOffset(18, 18),
		Text = "✦",
		TextColor3 = accentColor,
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBlack,
		ZIndex = 4,
	}, parent)
end

local function drawShopIcon(parent, accentColor)
	makeIconLine(parent, UDim2.fromOffset(10, 11), UDim2.fromOffset(14, 4), accentColor, 26)
	makeIconLine(parent, UDim2.fromOffset(21, 18), UDim2.fromOffset(24, 5), accentColor)
	makeIconLine(parent, UDim2.fromOffset(20, 28), UDim2.fromOffset(23, 5), accentColor)
	makeIconLine(parent, UDim2.fromOffset(9, 23), UDim2.fromOffset(5, 15), accentColor)
	makeIconLine(parent, UDim2.fromOffset(32, 23), UDim2.fromOffset(5, 15), accentColor)

	make("Frame", {
		BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(0, 0, 0), 0.6),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(11, 19),
		Size = UDim2.fromOffset(20, 8),
		ZIndex = 2,
	}, parent)

	for _, x in ipairs({ 14, 28 }) do
		local wheel = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(x, 35),
			Size = UDim2.fromOffset(7, 7),
			ZIndex = 3,
		}, parent)
		addCorner(wheel, 4)
	end
end

local function drawHelpIcon(parent, accentColor)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.fromOffset(42, 36),
		Text = "?",
		TextColor3 = accentColor,
		TextScaled = false,
		TextSize = 30,
		Font = Enum.Font.GothamBlack,
		ZIndex = 4,
	}, parent)
end

local function drawPopupIcon(parent, accentColor)
	makeIconLine(parent, UDim2.fromOffset(9, 11), UDim2.fromOffset(24, 18), accentColor, 14)
	makeIconLine(parent, UDim2.fromOffset(15, 29), UDim2.fromOffset(12, 4), accentColor, 28)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(7, 6),
		Size = UDim2.fromOffset(28, 24),
		Text = "!",
		TextColor3 = accentColor,
		TextScaled = false,
		TextSize = 21,
		Font = Enum.Font.GothamBlack,
		ZIndex = 4,
	}, parent)
end

local function drawMenuIcon(parent, iconKind, accentColor)
	if iconKind == "inventory" then
		drawInventoryIcon(parent, accentColor)
	elseif iconKind == "collection" then
		drawCollectionIcon(parent, accentColor)
	elseif iconKind == "upgrades" then
		drawUpgradeIcon(parent, accentColor)
	elseif iconKind == "quests" then
		drawQuestIcon(parent, accentColor)
	elseif iconKind == "shop" then
		drawShopIcon(parent, accentColor)
	elseif iconKind == "help" then
		drawHelpIcon(parent, accentColor)
	elseif iconKind == "popups" then
		drawPopupIcon(parent, accentColor)
	end
end

local function createMenuButton(order, text, iconKind, accentColor)
	local baseColor = accentColor:Lerp(Color3.fromRGB(5, 8, 16), 0.82)
	local hoverColor = accentColor:Lerp(Color3.fromRGB(8, 12, 22), 0.68)
	local labelColor = text == "Inventory" and UI.Text or accentColor

	local frame = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = baseColor,
		BackgroundTransparency = 0.02,
	}, sidebar)
	addCorner(frame, 12)
	local frameStroke = addStroke(frame, accentColor, 1.5, 0.38)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 24, 42)),
			ColorSequenceKeypoint.new(1, baseColor),
		}),
		Rotation = 0,
	}, frame)

	local iconBg = make("Frame", {
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(0, 7, 0.5, -21),
		BackgroundColor3 = accentColor:Lerp(Color3.fromRGB(0, 0, 0), 0.52),
		ClipsDescendants = false,
	}, frame)
	addCorner(iconBg, 11)
	addStroke(iconBg, accentColor, 1, 0.72)
	drawMenuIcon(iconBg, iconKind, accentColor)

	local label = make("TextLabel", {
		Name = "MenuLabel",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 62, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Text = string.upper(text),
		TextColor3 = labelColor,
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)

	local button = make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		AutoButtonColor = false,
	}, frame)
	addCorner(button, 12)

	button.MouseEnter:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.1), {
			BackgroundColor3 = hoverColor,
		}):Play()
		TweenService:Create(frameStroke, TweenInfo.new(0.1), {
			Transparency = 0.16,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.1), {
			BackgroundColor3 = baseColor,
		}):Play()
		TweenService:Create(frameStroke, TweenInfo.new(0.1), {
			Transparency = 0.38,
		}):Play()
	end)

	return button
end

local inventoryButton = createMenuButton(1, "Inventory", "inventory", Color3.fromRGB(78, 170, 255))
local collectionButton = createMenuButton(2, "Collection", "collection", Color3.fromRGB(255, 210, 68))
local upgradesButton  = createMenuButton(3, "Upgrades",  "upgrades",  UI.Gold)
local questsButton    = createMenuButton(4, "Quests",    "quests",    Color3.fromRGB(205, 88, 255))
local shopButton      = createMenuButton(5, "Shop",      "shop",      Color3.fromRGB(85, 226, 112))

local questBadge = make("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 6),
	Size = UDim2.fromOffset(24, 24),
	BackgroundColor3 = Color3.fromRGB(69, 207, 255),
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 8,
}, questsButton.Parent)
addCorner(questBadge, 12)
addStroke(questBadge, Color3.fromRGB(220, 250, 255), 1.4, 0.18)
local questBadgeScale = make("UIScale", { Scale = 1 }, questBadge)
local questBadgeLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "1",
	TextColor3 = Color3.fromRGB(4, 8, 16),
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	ZIndex = 9,
}, questBadge)

-- ── Sidebar collapse tab ──────────────────────────────────────────────────────
local SIDEBAR_OPEN_POS = UDim2.new(0, 20, 1, -20)
local SIDEBAR_CLOSED_POS = UDim2.new(0, -208, 1, -20)
local TAB_OPEN_POS = UDim2.new(0, 218, 1, -190)
local TAB_CLOSED_POS = UDim2.new(0, 10, 1, -190)
local SLIDE_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local sidebarIsOpen = true

local collapseTab = make("TextButton", {
	Name = "SidebarToggle",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = TAB_OPEN_POS,
	Size = UDim2.fromOffset(34, 48),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.08,
	Text = "<",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = false,
	ZIndex = 10,
}, screenGui)
addCorner(collapseTab, 12)
addStroke(collapseTab, UI.Gold, 1.5, 0.68)

collapseTab.MouseEnter:Connect(function()
	TweenService:Create(collapseTab, TweenInfo.new(0.1), {
		BackgroundColor3 = UI.Gold:Lerp(Color3.fromRGB(8, 12, 22), 0.85),
	}):Play()
end)
collapseTab.MouseLeave:Connect(function()
	TweenService:Create(collapseTab, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	}):Play()
end)

local function setSidebarOpen(open)
	sidebarIsOpen = open
	collapseTab.Text = open and "<" or ">"
	TweenService:Create(sidebar, SLIDE_INFO, {
		Position = open and SIDEBAR_OPEN_POS or SIDEBAR_CLOSED_POS,
	}):Play()
	TweenService:Create(collapseTab, SLIDE_INFO, {
		Position = open and TAB_OPEN_POS or TAB_CLOSED_POS,
	}):Play()
end

collapseTab.MouseButton1Click:Connect(function()
	setSidebarOpen(not sidebarIsOpen)
end)

local toastHolder = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -20, 0, 288),
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(320, 420),
}, screenGui)

make("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 10),
}, toastHolder)

-- ── Top-right quick-access row (Daily Rewards / Settings / Codes) ─────────────
local topRightRow = make("Frame", {
	Name = "TopRightRow",
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(312, 76),
	ZIndex = 80,
}, screenGui)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, topRightRow)

local function makeTopBtn(order, icon, label, accent)
	local btn = make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(96, 72),
		BackgroundColor3 = Color3.fromRGB(10, 13, 22),
		BackgroundTransparency = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 80,
	}, topRightRow)
	addCorner(btn, 12)
	addStroke(btn, accent, 1.5, 0.40)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 22, 36)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 18)),
		}),
		Rotation = 135,
	}, btn)

	-- Icon circle
	local iconCircle = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = accent:Lerp(Color3.fromRGB(0,0,0), 0.50),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(36, 36),
		ZIndex = 81,
	}, btn)
	addCorner(iconCircle, 18)
	addStroke(iconCircle, accent, 1, 0.42)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = icon,
		TextColor3 = accent,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 82,
	}, iconCircle)

	-- Label
	make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 1, -7),
		Size = UDim2.new(1, -4, 0, 16),
		Text = label,
		TextColor3 = Color3.fromRGB(210, 215, 225),
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		ZIndex = 81,
	}, btn)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundColor3 = accent:Lerp(Color3.fromRGB(10, 13, 22), 0.82),
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(10, 13, 22),
		}):Play()
	end)
	return btn
end

local dailyRewardButton = makeTopBtn(1, "📅", "Daily Rewards", Color3.fromRGB(255, 182, 60))
local settingsButton    = makeTopBtn(2, "⚙",  "Settings",      Color3.fromRGB(180, 190, 210))
local codesButton       = makeTopBtn(3, "🎁", "Codes",         Color3.fromRGB(85, 226, 112))

-- ── Settings sub-panel (replaces old utility panel) ───────────────────────────
local utilityPanelOpen = false
local utilityPanel = make("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = Color3.fromRGB(6, 8, 14),
	BackgroundTransparency = 0.02,
	Position = UDim2.new(1, -20, 0, 70),
	Size = UDim2.fromOffset(224, 132),
	Visible = false,
	ZIndex = 80,
}, screenGui)
addCorner(utilityPanel, 16)
addStroke(utilityPanel, UI.Gold, 1.5, 0.34)
make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 22, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 7, 12)),
	}),
	Rotation = 100,
}, utilityPanel)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 10),
	Size = UDim2.new(1, -56, 0, 22),
	Text = "SETTINGS",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 14,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 81,
}, utilityPanel)

local utilityCloseButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = Color3.fromRGB(18, 24, 40),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.fromOffset(28, 28),
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 82,
}, utilityPanel)
addCorner(utilityCloseButton, 8)

local helpButton = make("TextButton", {
	BackgroundColor3 = UI.Gold,
	Position = UDim2.new(0, 14, 0, 44),
	Size = UDim2.new(1, -28, 0, 32),
	Text = "HOW TO PLAY",
	TextColor3 = Color3.fromRGB(12, 9, 3),
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 81,
}, utilityPanel)
addCorner(helpButton, 10)

local popupMuteButton = make("TextButton", {
	BackgroundColor3 = Color3.fromRGB(24, 29, 43),
	Position = UDim2.new(0, 14, 0, 84),
	Size = UDim2.new(1, -28, 0, 32),
	Text = "POPUPS: ON",
	TextColor3 = Color3.fromRGB(248, 240, 210),
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 81,
}, utilityPanel)
addCorner(popupMuteButton, 10)

-- Codes entry panel
local codesPanelOpen = false
local codesPanel = make("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = Color3.fromRGB(6, 10, 16),
	BackgroundTransparency = 0.02,
	Position = UDim2.new(1, -20, 0, 70),
	Size = UDim2.fromOffset(224, 96),
	Visible = false,
	ZIndex = 80,
}, screenGui)
addCorner(codesPanel, 16)
addStroke(codesPanel, Color3.fromRGB(85, 226, 112), 1.5, 0.30)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 10),
	Size = UDim2.new(1, -40, 0, 20),
	Text = "ENTER CODE",
	TextColor3 = Color3.fromRGB(85, 226, 112),
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 81,
}, codesPanel)

local codesCloseBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = Color3.fromRGB(18, 24, 40),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.fromOffset(28, 28),
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 82,
}, codesPanel)
addCorner(codesCloseBtn, 8)

local codeBox = make("TextBox", {
	BackgroundColor3 = Color3.fromRGB(14, 20, 32),
	ClearTextOnFocus = true,
	PlaceholderText = "e.g. FREEGEMS2025",
	PlaceholderColor3 = Color3.fromRGB(100, 120, 100),
	Position = UDim2.new(0, 14, 0, 36),
	Size = UDim2.new(1, -28, 0, 28),
	Text = "",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	ZIndex = 82,
}, codesPanel)
addCorner(codeBox, 8)
addStroke(codeBox, Color3.fromRGB(85, 226, 112), 1, 0.48)

local redeemBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	BackgroundColor3 = Color3.fromRGB(60, 180, 90),
	Position = UDim2.new(1, -14, 1, -10),
	Size = UDim2.fromOffset(80, 28),
	Text = "REDEEM",
	TextColor3 = Color3.fromRGB(8, 20, 8),
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 82,
}, codesPanel)
addCorner(redeemBtn, 8)

local popupsMuted = false
local coachDismissed = false
local coachReplayActive = false
local coachReplayIndex = 0
local coachAction
local coachCard = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(9, 13, 24),
	BackgroundTransparency = 0.06,
	Position = UDim2.new(0.5, 0, 0, 86),
	Size = UDim2.new(0.9, 0, 0, 112),
	Visible = false,
	ZIndex = 70,
}, screenGui)
addCorner(coachCard, 16)
addStroke(coachCard, UI.Gold, 1.5, 0.34)
make("UISizeConstraint", {
	MaxSize = Vector2.new(420, 112),
	MinSize = Vector2.new(300, 112),
}, coachCard)

local coachAccent = make("Frame", {
	BackgroundColor3 = UI.Gold,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 12, 0, 14),
	Size = UDim2.new(0, 5, 1, -28),
	ZIndex = 71,
}, coachCard)
addCorner(coachAccent, 4)

local coachStepLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 0, 10),
	Size = UDim2.new(1, -106, 0, 18),
	Text = "NEXT STEP",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 71,
}, coachCard)

local coachTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 0, 30),
	Size = UDim2.new(1, -154, 0, 24),
	Text = "",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 19,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 71,
}, coachCard)

local coachBody = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 0, 58),
	Size = UDim2.new(1, -154, 0, 42),
	Text = "",
	TextColor3 = Color3.fromRGB(218, 213, 194),
	TextScaled = false,
	TextSize = 13,
	TextWrapped = true,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 71,
}, coachCard)

local coachButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	BackgroundColor3 = UI.Gold,
	Position = UDim2.new(1, -14, 1, -14),
	Size = UDim2.fromOffset(104, 34),
	Text = "Got it",
	TextColor3 = Color3.fromRGB(10, 8, 3),
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 72,
}, coachCard)
addCorner(coachButton, 10)

local coachClose = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = Color3.fromRGB(19, 25, 41),
	Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.fromOffset(30, 30),
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 14,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 72,
}, coachCard)
addCorner(coachClose, 9)

local function setCoinsDisplay(coins)
	fansLabel.Text = Utils.FormatNumber(coins or 0)
end

local function setGemsDisplay(gems)
	gemsLabel.Text = Utils.FormatNumber(gems or 0)
end

local function updatePopupMuteButton()
	popupMuteButton.Text = popupsMuted and "POPUPS: OFF" or "POPUPS: ON"
	popupMuteButton.BackgroundColor3 = popupsMuted and Color3.fromRGB(52, 20, 18) or Color3.fromRGB(24, 29, 43)
	popupMuteButton.TextColor3 = popupsMuted and Color3.fromRGB(255, 184, 166) or Color3.fromRGB(248, 240, 210)
end

local function showToast(text, accent, force)
	if popupsMuted and not force then
		return
	end

	local toast = make("Frame", {
		BackgroundColor3 = UI.PanelAlt,
		Size = UDim2.new(1, 0, 0, 58),
	}, toastHolder)
	addCorner(toast, 16)
	addStroke(toast, accent, 2, 0.25)

	make("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 6, 1, -12),
		Position = UDim2.new(0, 8, 0, 6),
	}, toast)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Text = text,
		TextColor3 = UI.Text,
		TextWrapped = true,
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, toast)

	toast.BackgroundTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.18), {
		BackgroundTransparency = 0,
	}):Play()

	task.delay(3.2, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.2), {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
			}):Play()
			task.wait(0.22)
			if toast.Parent then
				toast:Destroy()
			end
		end
	end)
end
updatePopupMuteButton()

local lastQuestReadyCount = nil
local function pulseQuestBadge()
	if not questBadge.Visible then
		return
	end

	TweenService:Create(questBadgeScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.22,
	}):Play()
	task.delay(0.14, function()
		if questBadgeScale.Parent then
			TweenService:Create(questBadgeScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
		end
	end)
end

local function applyQuestNotification(payload)
	local readyCount = math.max(0, math.floor(tonumber(payload and payload.claimableCount) or 0))
	questBadge.Visible = readyCount > 0
	questBadgeLabel.Text = readyCount > 9 and "9+" or tostring(readyCount)

	if lastQuestReadyCount ~= nil and readyCount > lastQuestReadyCount then
		showToast("Quest complete - claim your reward.", Color3.fromRGB(69, 207, 255))
		pulseQuestBadge()
	elseif readyCount > 0 then
		pulseQuestBadge()
	end

	lastQuestReadyCount = readyCount
end

local function fireGuiToggle(guiName)
	local targetGui = playerGui:FindFirstChild(guiName)
	if not targetGui then
		targetGui = playerGui:WaitForChild(guiName, 3)
	end

	local toggleEvent = targetGui and targetGui:FindFirstChild("ToggleEvent")
	if toggleEvent then
		toggleEvent:Fire()
		return true
	end

	return false
end

local function countInventoryCards(inventoryCounts)
	local total = 0
	if type(inventoryCounts) ~= "table" then
		return total
	end

	for _, amount in pairs(inventoryCounts) do
		total += math.max(0, tonumber(amount) or 0)
	end
	return total
end

local refreshCoachSoon

local function setCoachStep(step)
	if coachDismissed or not step then
		coachCard.Visible = false
		coachAction = nil
		if not step then
			coachReplayActive = false
			coachReplayIndex = 0
		end
		return
	end

	coachStepLabel.Text = step.eyebrow or "NEXT STEP"
	coachTitle.Text = step.title or ""
	coachBody.Text = step.body or ""
	coachButton.Text = step.buttonText or "Got it"
	coachAccent.BackgroundColor3 = step.accent or UI.Gold
	coachStepLabel.TextColor3 = step.accent or UI.Gold
	coachButton.BackgroundColor3 = step.accent or UI.Gold
	coachAction = step.action
	coachCard.Visible = true
end

local function updateCoach(data)
	if coachDismissed or coachReplayActive or type(data) ~= "table" then
		return
	end

	-- Players who have rebirthed at least once already know the basics —
	-- don't show the intro tutorial steps after each rebirth resets the counters.
	if (tonumber(data.rebirthTier) or 0) > 0 then
		setCoachStep(nil)
		return
	end

	local totalPacks = math.max(0, tonumber(data.totalPacksOpened) or 0)
	local passiveFans = math.max(0, tonumber(data.passiveCoinsPerSecond) or 0)
	local storedCount = countInventoryCards(data.inventoryCounts)

	if totalPacks <= 0 then
		setCoachStep({
			title = "Crack your first pack",
			body = "Equip the Pitchfork, stand by the red pad, then hit the pack until it opens.",
			buttonText = "Got it",
			action = function()
				coachDismissed = true
				coachCard.Visible = false
			end,
		})
	elseif passiveFans <= 0 and storedCount > 0 then
		setCoachStep({
			title = "Put a player on display",
			body = "Hold E on an empty green slot, then choose a stored player to start earning Fans.",
			buttonText = "Inventory",
			accent = Color3.fromRGB(78, 170, 255),
			action = function()
				fireGuiToggle("InventoryUI")
				showToast("Green display slots place stored players onto your stadium.", UI.Gold)
				refreshCoachSoon(0.6)
			end,
		})
	elseif passiveFans <= 0 then
		setCoachStep({
			title = "Find a display player",
			body = "Open another pack, then place the player on a green display slot to earn Fans.",
			buttonText = "Got it",
			action = function()
				coachDismissed = true
				coachCard.Visible = false
			end,
		})
	elseif totalPacks < 5 then
		setCoachStep({
			title = "Spend Fans on upgrades",
			body = "Fans are coming in. Upgrade sprint speed, pack spawn luck, or card pull luck to progress faster.",
			buttonText = "Upgrades",
			action = function()
				fireGuiToggle("UpgradesUI")
				refreshCoachSoon(0.6)
			end,
		})
	else
		setCoachStep(nil)
	end
end

local ONBOARDING_REPLAY_STEPS = {
	{
		title = "Crack a pack",
		body = "Equip the Pitchfork, stand by the red pad, and hit the pack until it opens.",
		accent = UI.Gold,
	},
	{
		title = "Display a player",
		body = "If a player goes to inventory, hold E on an empty green slot and choose them to start earning Fans.",
		accent = Color3.fromRGB(78, 170, 255),
	},
	{
		title = "Upgrade your stadium loop",
		body = "Use Fans on upgrades like sprint speed, pack spawn luck, and card pull luck. More slots come from rebirth.",
		accent = Color3.fromRGB(85, 226, 112),
	},
}

local function showOnboardingReplay(index)
	coachReplayActive = true
	coachDismissed = false
	coachReplayIndex = math.clamp(index or 1, 1, #ONBOARDING_REPLAY_STEPS)

	local replayStep = ONBOARDING_REPLAY_STEPS[coachReplayIndex]
	setCoachStep({
		eyebrow = "HELP",
		title = replayStep.title,
		body = replayStep.body,
		buttonText = coachReplayIndex >= #ONBOARDING_REPLAY_STEPS and "Done" or "Next",
		accent = replayStep.accent,
		action = function()
			if coachReplayIndex < #ONBOARDING_REPLAY_STEPS then
				showOnboardingReplay(coachReplayIndex + 1)
				return
			end

			coachReplayActive = false
			coachDismissed = true
			coachReplayIndex = 0
			coachCard.Visible = false
		end,
	})
end

local coachRefreshQueued = false
local lastCoachRefreshAt = 0
function refreshCoachSoon(delaySeconds)
	if coachDismissed or coachRefreshQueued then
		return
	end
	if os.clock() - lastCoachRefreshAt < 1.5 then
		return
	end

	coachRefreshQueued = true
	task.delay(delaySeconds or 0.2, function()
		coachRefreshQueued = false
		if coachDismissed then
			return
		end

		local ok, data = pcall(function()
			return GetPlayerDataFn:InvokeServer()
		end)
		if ok then
			lastCoachRefreshAt = os.clock()
			updateCoach(data)
		end
	end)
end

local function refreshStatus()
	local data = GetPlayerDataFn:InvokeServer()
	if not data then
		return
	end

	setCoinsDisplay(data.coins)
	setGemsDisplay(data.gems)
	lastCoachRefreshAt = os.clock()
	updateCoach(data)
end

coachButton.MouseButton1Click:Connect(function()
	if coachAction then
		coachAction()
	else
		coachDismissed = true
		coachCard.Visible = false
	end
end)

coachClose.MouseButton1Click:Connect(function()
	coachReplayActive = false
	coachReplayIndex = 0
	coachDismissed = true
	coachCard.Visible = false
end)

inventoryButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("InventoryUI") then
		showToast("Inventory UI is still loading. Try again in a second.", UI.Gold)
	end
	refreshCoachSoon(0.4)
end)

collectionButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("CollectionUI") then
		showToast("Collection book is still loading. Try again in a second.", UI.Gold)
	end
end)

upgradesButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("UpgradesUI") then
		showToast("Upgrades UI is still loading. Try again in a second.", UI.Gold)
	end
	refreshCoachSoon(0.4)
end)

questsButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("QuestsUI") then
		showToast("Quests are still loading. Try again in a second.", Color3.fromRGB(205, 88, 255))
	elseif questBadge.Visible then
		pulseQuestBadge()
	end
end)

shopButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("ShopUI") then
		showToast("Shop is still loading. Try again in a second.", Color3.fromRGB(74, 185, 98))
	end
end)

local function setUtilityPanelOpen(open)
	utilityPanelOpen = open
	utilityPanel.Visible = open
	if open then
		codesPanelOpen = false
		codesPanel.Visible = false
	end
end

settingsButton.MouseButton1Click:Connect(function()
	setUtilityPanelOpen(not utilityPanelOpen)
end)

utilityCloseButton.MouseButton1Click:Connect(function()
	setUtilityPanelOpen(false)
end)

codesButton.MouseButton1Click:Connect(function()
	codesPanelOpen = not codesPanelOpen
	codesPanel.Visible = codesPanelOpen
	if codesPanelOpen then
		setUtilityPanelOpen(false)
	end
end)

codesCloseBtn.MouseButton1Click:Connect(function()
	codesPanelOpen = false
	codesPanel.Visible = false
end)

redeemBtn.MouseButton1Click:Connect(function()
	local code = codeBox.Text
	if code == "" then
		showToast("Enter a code first.", Color3.fromRGB(85, 226, 112))
		return
	end
	showToast("Code '" .. code .. "' submitted! (Coming soon)", Color3.fromRGB(85, 226, 112))
	codeBox.Text = ""
end)

dailyRewardButton.MouseButton1Click:Connect(function()
	showToast("Daily Rewards coming soon! Check back each day.", Color3.fromRGB(255, 182, 60))
end)

helpButton.MouseButton1Click:Connect(function()
	setUtilityPanelOpen(false)
	showOnboardingReplay(1)
end)

popupMuteButton.MouseButton1Click:Connect(function()
	popupsMuted = not popupsMuted
	updatePopupMuteButton()
	if popupsMuted then
		showToast("Popup notifications muted.", Color3.fromRGB(255, 156, 82), true)
	else
		showToast("Popup notifications on.", Color3.fromRGB(85, 226, 112), true)
	end
end)

addFansButton.MouseButton1Click:Connect(function()
	showToast("Fans come from displayed players. Future boosts will help you grow faster.", UI.Gold)
end)

addGemsButton.MouseButton1Click:Connect(function()
	showToast("Earn Gems from daily quests, then spend them in the Shop.", Color3.fromRGB(69, 207, 255))
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins, gems)
	setCoinsDisplay(coins)
	if gems ~= nil then
		setGemsDisplay(gems)
	end
	refreshCoachSoon(0.5)
end)

local function getGuiCenterTarget(guiObject, fallback)
	if not guiObject or not guiObject.Parent then
		return fallback
	end

	local size = guiObject.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return fallback
	end

	local position = guiObject.AbsolutePosition
	return UDim2.fromOffset(position.X + (size.X / 2), position.Y + (size.Y / 2))
end

local function getWorldScreenTarget(worldPosition, fallback)
	if typeof(worldPosition) ~= "Vector3" then
		return fallback
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return fallback
	end

	local screenPoint, onScreen = camera:WorldToViewportPoint(worldPosition)
	if not onScreen or screenPoint.Z <= 0 then
		return fallback
	end

	return UDim2.fromOffset(screenPoint.X, screenPoint.Y)
end

local cameraShakeToken = 0
local cameraShakeRestoreType

local function shakeCamera(intensity, duration, steps)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	cameraShakeToken += 1
	local token = cameraShakeToken
	cameraShakeRestoreType = cameraShakeRestoreType or camera.CameraType
	local baseCFrame = camera.CFrame
	local totalSteps = steps or 5
	camera.CameraType = Enum.CameraType.Scriptable

	task.spawn(function()
		for index = 1, totalSteps do
			if token ~= cameraShakeToken or not camera.Parent then
				return
			end
			local falloff = 1 - ((index - 1) / totalSteps)
			local amount = intensity * falloff
			camera.CFrame = baseCFrame * CFrame.new(
				(math.random() - 0.5) * 2 * amount,
				(math.random() - 0.5) * 2 * amount,
				0
			)
			task.wait((duration or 0.12) / totalSteps)
		end

		if token == cameraShakeToken and camera.Parent then
			camera.CFrame = baseCFrame
			camera.CameraType = cameraShakeRestoreType or Enum.CameraType.Custom
			cameraShakeRestoreType = nil
		end
	end)
end

local function getWorldScreenPoint(worldPosition)
	if typeof(worldPosition) ~= "Vector3" then
		return nil
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local screenPoint, onScreen = camera:WorldToViewportPoint(worldPosition)
	if not onScreen or screenPoint.Z <= 0 then
		return nil
	end

	return Vector2.new(screenPoint.X, screenPoint.Y)
end

-- ── Particle burst helper ─────────────────────────────────────────────────────
-- Spawns `count` small coloured dots that fly outward from the pack or centre.
local function spawnParticleBurst(color, count, worldPosition, distanceScale)
	local camera = Workspace.CurrentCamera
	local vp     = camera and camera.ViewportSize or Vector2.new(1024, 768)
	local origin = getWorldScreenPoint(worldPosition) or Vector2.new(vp.X / 2, vp.Y * 0.44)
	local cx, cy = origin.X, origin.Y
	for i = 1, count do
		local angle    = (i / count) * (math.pi * 2) + (math.random() - 0.5) * 0.9
		local dist     = (distanceScale or 1) * (80 + math.random(20, 110))
		local sz       = math.random(5, 14)
		local lifetime = 0.28 + math.random() * 0.28
		local px = make("Frame", {
			AnchorPoint      = Vector2.new(0.5, 0.5),
			Position         = UDim2.fromOffset(cx, cy),
			Size             = UDim2.fromOffset(sz, sz),
			BackgroundColor3 = color:Lerp(Color3.fromRGB(255, 255, 255), math.random() * 0.45),
			BorderSizePixel  = 0,
			ZIndex           = 195,
		}, screenGui)
		addCorner(px, math.floor(sz / 2))
		TweenService:Create(px, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position               = UDim2.fromOffset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(lifetime + 0.06, function()
			if px.Parent then px:Destroy() end
		end)
	end
end

local function showImpactFlash(color, isFinal)
	local flash = make("Frame", {
		BackgroundColor3 = isFinal and color:Lerp(Color3.fromRGB(255, 255, 255), 0.62) or Color3.fromRGB(255, 246, 204),
		BackgroundTransparency = isFinal and 0.32 or 0.64,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = isFinal and 190 or 188,
	}, screenGui)

	TweenService:Create(flash, TweenInfo.new(isFinal and 0.34 or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	task.delay(isFinal and 0.38 or 0.18, function()
		if flash.Parent then
			flash:Destroy()
		end
	end)
end

local function playPackHitFeedback(payload)
	if not payload then
		return
	end

	local color = payload.color or UI.Gold
	local isFinal = payload.isFinal == true
	showImpactFlash(color, isFinal)
	spawnParticleBurst(color, isFinal and 34 or 10, payload.packWorldPosition, isFinal and 1.18 or 0.42)
	shakeCamera(isFinal and 0.18 or 0.045, isFinal and 0.24 or 0.10, isFinal and 8 or 4)

	if isFinal then
		finalBreakSound:Play()
		task.delay(0.36, function()
			showImpactFlash(color, true)
			spawnParticleBurst(color:Lerp(Color3.fromRGB(255, 255, 255), 0.35), 44, payload.packWorldPosition, 1.35)
		end)
	else
		hitSound.PlaybackSpeed = 0.92 + ((1 - math.clamp(payload.integrity or 1, 0, 1)) * 0.25)
		hitSound:Play()
	end
end

local function showMilestoneRewardPopup(payload)
	if not payload then
		return
	end

	local rewards = payload.rewards or (payload.reward and { payload.reward }) or {}
	local reward = rewards[1]
	if not reward then
		return
	end

	local color = reward.color or UI.Gold
	local extraCount = math.max(0, #rewards - 1)
	local queueLength = tonumber(payload.queueLength) or #rewards
	local rewardText = string.upper(reward.reward or reward.packName or "REWARD QUEUED")
	local rewardSource = string.upper(tostring(reward.label or ""))
	local titleText = "\u{2605} MILESTONE REACHED!"
	local queueText = "NEXT REWARD PACK WILL SPAWN FIRST"

	if rewardSource == "SHOP" then
		titleText = "PACK BOUGHT!"
		queueText = "QUEUED FOR YOUR RED PAD"
	elseif rewardSource == "DAILY" then
		titleText = "DAILY REWARD!"
		queueText = "QUEUED FOR YOUR RED PAD"
	elseif rewardSource == "QUEST" then
		titleText = "QUEST COMPLETE!"
		queueText = "QUEUED FOR YOUR RED PAD"
	elseif reward.kind == "guarantee" then
		queueText = "NEXT PACK GETS THIS GUARANTEE"
	end

	milestoneSound.PlaybackSpeed = extraCount > 0 and 0.82 or 0.92
	milestoneSound:Play()
	showImpactFlash(color, true)
	spawnParticleBurst(color, extraCount > 0 and 38 or 26, nil, 0.78)
	shakeCamera(extraCount > 0 and 0.12 or 0.08, 0.18, 7)

	local popup = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, -0.22),
		Size = UDim2.fromOffset(430, 138),
		ZIndex = 240,
	}, screenGui)
	addCorner(popup, 20)
	addStroke(popup, color, 3, 0.04)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color:Lerp(Color3.fromRGB(0, 0, 0), 0.45)),
			ColorSequenceKeypoint.new(0.48, Color3.fromRGB(7, 10, 18)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 5, 10)),
		}),
		Rotation = 145,
	}, popup)

	local glow = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.76,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 26, 1, 26),
		ZIndex = 239,
	}, popup)
	addCorner(glow, 24)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.06, 0.10),
		Size = UDim2.fromScale(0.88, 0.24),
		Text = titleText,
		TextColor3 = Color3.fromRGB(255, 255, 245),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 242,
	}, popup)

	local rewardLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.06, 0.39),
		Size = UDim2.fromScale(0.88, 0.30),
		Text = rewardText,
		TextColor3 = color,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		ZIndex = 242,
	}, popup)
	make("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 32 }, rewardLabel)
	addStroke(rewardLabel, Color3.fromRGB(0, 0, 0), 1.2, 0.18)

	if extraCount > 0 then
		queueText = queueText .. "  |  +" .. tostring(extraCount) .. " MORE"
	elseif queueLength > 1 then
		queueText = queueText .. "  |  " .. tostring(queueLength) .. " QUEUED"
	end

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.08, 0.73),
		Size = UDim2.fromScale(0.84, 0.16),
		Text = queueText,
		TextColor3 = Color3.fromRGB(255, 246, 210),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 242,
	}, popup)

	local popupScale = make("UIScale", { Scale = 0.86 }, popup)
	TweenService:Create(popup, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.08),
	}):Play()
	TweenService:Create(popupScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	task.delay(0.36, function()
		if glow.Parent then
			TweenService:Create(glow, TweenInfo.new(0.50, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0.90,
				Size = UDim2.new(1, 46, 1, 46),
			}):Play()
		end
	end)

	task.delay(3.15, function()
		if not popup.Parent then
			return
		end
		TweenService:Create(popup, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, -0.22),
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(popupScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Scale = 0.92,
		}):Play()
		task.delay(0.25, function()
			if popup.Parent then
				popup:Destroy()
			end
		end)
	end)
end

-- ── Shimmer sweep helper ──────────────────────────────────────────────────────
-- Slides a subtle clipped gleam across the card face without spilling over the screen.
local function sweepShimmer(panel, color)
	local mask = make("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 208,
	}, panel)
	addCorner(mask, 18)

	local shine = make("Frame", {
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.fromScale(-0.20, 0.5),
		Size             = UDim2.fromScale(0.16, 1.12),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.76,
		Rotation         = -16,
		BorderSizePixel  = 0,
		ZIndex           = 209,
	}, mask)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.10),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 0,
	}, shine)
	TweenService:Create(shine, TweenInfo.new(0.36, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(1.08, 0.5),
	}):Play()
	task.delay(0.42, function()
		if mask.Parent then
			mask:Destroy()
		end
	end)
end

-- ── Rare pull screen effect ───────────────────────────────────────────────────
-- Gold       = tier 0 : quick flash
-- Rare Gold  = tier 1 : small particle pop
-- Premium    = tier 2 : rarity label + stronger shine
-- Talisman   = tier 3 : cinematic bars
-- Maestro+   = tier 4/5 : suspense pause + impact shake
-- Returns seconds the caller should wait before showing the card panel.
local REVEAL_TIERS = {
	["Rare Gold"]          = 1,
	["Premium Gold"]       = 2,
	["Talisman"]           = 3,
	["Maestro"]            = 4,
	["Immortal"]           = 5,
	["Player of the Year"] = 5,
}

local REVEAL_DELAYS = {
	["Gold"] = 0.02,
	["Rare Gold"] = 0.08,
	["Premium Gold"] = 0.24,
	["Talisman"] = 0.42,
	["Maestro"] = 0.66,
	["Immortal"] = 0.78,
	["Player of the Year"] = 0.82,
}

local CARD_VISUAL_TREATMENTS = {
	["Gold"] = {
		tag = "BASE",
		patternCount = 7,
		borderBoost = 0,
		portraitBoost = 0,
	},
	["Rare Gold"] = {
		tag = "RARE",
		patternCount = 10,
		borderBoost = 1,
		portraitBoost = 5,
	},
	["Premium Gold"] = {
		tag = "PREMIUM",
		patternCount = 12,
		borderBoost = 2,
		portraitBoost = 9,
	},
	["Talisman"] = {
		tag = "SPECIAL",
		patternCount = 14,
		borderBoost = 3,
		portraitBoost = 12,
	},
	["Maestro"] = {
		tag = "ELITE",
		patternCount = 16,
		borderBoost = 4,
		portraitBoost = 15,
	},
	["Immortal"] = {
		tag = "LEGEND",
		patternCount = 18,
		borderBoost = 5,
		portraitBoost = 18,
	},
	["Player of the Year"] = {
		tag = "BEST",
		patternCount = 20,
		borderBoost = 6,
		portraitBoost = 20,
	},
}

local function getCardVisualTreatment(rarity)
	return CARD_VISUAL_TREATMENTS[rarity] or CARD_VISUAL_TREATMENTS["Gold"]
end

local function playRevealEffect(rarity)
	local tier       = REVEAL_TIERS[rarity] or 0
	local style      = Utils.GetRarityStyle(rarity)
	local flashColor = style and (style.glow or style.primary) or Color3.fromRGB(255, 215, 0)

	-- Flash overlay — every rarity gets at least a brief subtle pop ────────────
	local startTransp = tier == 0 and 0.74 or (tier == 1 and 0.52 or (tier == 2 and 0.32 or 0.16))
	local holdTime    = tier == 0 and 0.05 or (tier == 1 and 0.12 or (tier == 2 and 0.22 or 0.32))
	local fadeTime    = tier == 0 and 0.18 or (tier == 1 and 0.32 or (tier == 2 and 0.52 or 0.68))

	local flash = make("Frame", {
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(0.5, 0.5),
		Size             = UDim2.fromScale(1, 1),
		BackgroundColor3 = flashColor,
		BackgroundTransparency = startTransp,
		BorderSizePixel  = 0,
		ZIndex           = 188,
	}, screenGui)

	task.delay(holdTime, function()
		if flash.Parent then
			TweenService:Create(flash, TweenInfo.new(fadeTime), { BackgroundTransparency = 1 }):Play()
			task.delay(fadeTime + 0.05, function()
				if flash.Parent then flash:Destroy() end
			end)
		end
	end)

	-- Particle burst (tier 1+) — coloured dots fly outward on flash ────────────
	if tier >= 1 then
		local pCount = tier == 1 and 14 or (tier == 2 and 24 or 36)
		task.spawn(function()
			task.wait(holdTime * 0.5)
			spawnParticleBurst(flashColor, pCount)
		end)
	end

	if tier == 0 then
		return 0   -- Gold: just the flash; card pops in immediately
	end

	-- Rarity name burst (tier 2+) ──────────────────────────────────────────────
	if tier >= 2 then
		local burstLabel = make("TextLabel", {
			AnchorPoint          = Vector2.new(0.5, 0.5),
			Position             = UDim2.fromScale(0.5, 0.43),
			Size                 = UDim2.fromOffset(480, 72),
			BackgroundTransparency = 1,
			Text                 = string.upper(style.label or rarity),
			TextColor3           = style.primary,
			TextTransparency     = 0,
			TextScaled           = true,
			Font                 = Enum.Font.GothamBlack,
			ZIndex               = 193,
		}, screenGui)
		addStroke(burstLabel, Color3.fromRGB(0, 0, 0), 2, 0.05)

		local burstScale = make("UIScale", { Scale = 0.25 }, burstLabel)
		TweenService:Create(burstScale,
			TweenInfo.new(0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
		TweenService:Create(burstLabel,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0.55),
			{ TextTransparency = 1 }
		):Play()
		task.delay(1.05, function()
			if burstLabel.Parent then burstLabel:Destroy() end
		end)
	end

	-- Cinematic black bars (tier 2+) ───────────────────────────────────────────
	if tier >= 2 then
		local BAR_H  = 76
		local topBar = make("Frame", {
			AnchorPoint      = Vector2.new(0, 0),
			Position         = UDim2.new(0, 0, 0, -BAR_H),
			Size             = UDim2.new(1, 0, 0, BAR_H),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel  = 0,
			ZIndex           = 186,
		}, screenGui)
		local bottomBar = make("Frame", {
			AnchorPoint      = Vector2.new(0, 1),
			Position         = UDim2.new(0, 0, 1, BAR_H),
			Size             = UDim2.new(1, 0, 0, BAR_H),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel  = 0,
			ZIndex           = 186,
		}, screenGui)

		local slideIn = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(topBar,    slideIn, { Position = UDim2.new(0, 0, 0, 0)      }):Play()
		TweenService:Create(bottomBar, slideIn, { Position = UDim2.new(0, 0, 1, -BAR_H) }):Play()

		local barLifetime = tier == 2 and 2.4 or 2.8
		task.delay(barLifetime, function()
			local slideOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			if topBar.Parent    then TweenService:Create(topBar,    slideOut, { Position = UDim2.new(0, 0, 0, -BAR_H) }):Play() end
			if bottomBar.Parent then TweenService:Create(bottomBar, slideOut, { Position = UDim2.new(0, 0, 1,  BAR_H) }):Play() end
			task.delay(0.40, function()
				if topBar.Parent    then topBar:Destroy()    end
				if bottomBar.Parent then bottomBar:Destroy() end
			end)
		end)
	end

	-- Camera shake (tier 3) ────────────────────────────────────────────────────
	if tier >= 3 then
		task.spawn(function()
			local camera = Workspace.CurrentCamera
			if not camera then return end
			local prevType = camera.CameraType
			local prevCF   = camera.CFrame
			camera.CameraType = Enum.CameraType.Scriptable
			for i = 1, 10 do
				task.wait(0.032)
				if not camera or not camera.Parent then break end
				local intensity = 0.28 * (1 - (i - 1) / 10)
				camera.CFrame = prevCF * CFrame.new(
					(math.random() - 0.5) * 2 * intensity,
					(math.random() - 0.5) * 2 * intensity,
					0
				)
			end
			if camera and camera.Parent then
				camera.CFrame     = prevCF
				camera.CameraType = prevType
			end
		end)
	end

	if tier >= 4 then
		return 0.52
	end
	return tier == 1 and 0.14 or (tier == 2 and 0.32 or 0.42)
end

local function getRevealFocusTransparency(tier)
	if tier >= 4 then
		return 0.40
	elseif tier >= 3 then
		return 0.46
	elseif tier >= 2 then
		return 0.56
	elseif tier >= 1 then
		return 0.64
	end
	return 0.74
end

local function makeRevealFocus(style, tier, revealPos)
	local glowColor = style.glow or style.primary or UI.Gold
	local overlay = make("Frame", {
		Name = "RevealFocusOverlay",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 187,
	}, screenGui)
	TweenService:Create(overlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = getRevealFocusTransparency(tier),
	}):Play()

	local stage = make("Frame", {
		Name = "RevealStageGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = revealPos,
		Size = UDim2.fromOffset(560, 560),
		ZIndex = 196,
	}, screenGui)
	local stageScale = make("UIScale", { Scale = tier >= 2 and 0.78 or 0.86 }, stage)

	local haloSize = 300 + (tier * 34)
	local halo = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = glowColor,
		BackgroundTransparency = tier >= 3 and 0.62 or 0.72,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(haloSize, haloSize),
		ZIndex = 197,
	}, stage)
	addCorner(halo, haloSize)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.10),
			NumberSequenceKeypoint.new(0.58, 0.72),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, halo)

	local rayCount = tier >= 3 and 14 or (tier >= 2 and 10 or (tier >= 1 and 7 or 4))
	for index = 1, rayCount do
		local ray = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = glowColor:Lerp(Color3.fromRGB(255, 255, 255), 0.18),
			BackgroundTransparency = tier >= 2 and 0.70 or 0.82,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = (360 / rayCount) * (index - 1),
			Size = UDim2.fromOffset(tier >= 3 and 9 or 6, 270 + (tier * 24)),
			ZIndex = 198,
		}, stage)
		make("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.48, 0.18),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, ray)
	end

	TweenService:Create(stageScale, TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.02 + (math.min(tier, 4) * 0.012),
	}):Play()
	TweenService:Create(halo, TweenInfo.new(0.72, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		BackgroundTransparency = tier >= 3 and 0.48 or 0.60,
		Size = UDim2.fromOffset(haloSize + 42 + (tier * 8), haloSize + 42 + (tier * 8)),
	}):Play()
	if tier >= 2 then
		TweenService:Create(stage, TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Rotation = tier >= 4 and 10 or 6,
		}):Play()
	end

	return {
		overlay = overlay,
		stage = stage,
	}
end

local function clearRevealFocus(focus)
	if not focus then
		return
	end

	if focus.overlay and focus.overlay.Parent then
		TweenService:Create(focus.overlay, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.30, function()
			if focus.overlay and focus.overlay.Parent then
				focus.overlay:Destroy()
			end
		end)
	end

	if focus.stage and focus.stage.Parent then
		focus.stage:Destroy()
	end
end

local function burstRevealRing(parent, color, tier)
	local ring = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 18, 1, 18),
		ZIndex = 199,
	}, parent)
	addCorner(ring, 24)
	local stroke = addStroke(ring, color, tier >= 3 and 5 or 3.5, tier >= 2 and 0.10 or 0.24)
	TweenService:Create(ring, TweenInfo.new(0.52, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 74 + (tier * 4), 1, 74 + (tier * 4)),
	}):Play()
	TweenService:Create(stroke, TweenInfo.new(0.52, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
	}):Play()
	task.delay(0.58, function()
		if ring.Parent then
			ring:Destroy()
		end
	end)
end

-- ── Card reveal ───────────────────────────────────────────────────────────────
-- 5-phase sequence matching the reference design:
--   1. INITIATE  — flash fires (playRevealEffect)
--   2. BUILD UP  — particles burst outward
--   3. FLASH     — card animates up from below with scale bounce
--   4. REVEAL    — shimmer sweep + rarity aura pulse
--   5. RESULT    — clean card face, then it flies to slot/inventory
local function showCardReveal(payload)
	local card = payload.card
	if not card then return end

	local style          = Utils.GetRarityStyle(card.rarity)
	local rarityColor    = style.primary
	local secondaryColor = style.secondary or rarityColor
	local darkColor      = style.dark or Color3.fromRGB(10, 5, 2)
	local trimColor      = style.trim or rarityColor
	local textColor      = style.text or Color3.fromRGB(255, 255, 255)
	local glowColor      = style.glow or trimColor
	local toInventory    = payload.storedInInventory == true
	local tier           = REVEAL_TIERS[card.rarity] or 0
	local treatment      = getCardVisualTreatment(card.rarity)
	local patternCount   = treatment.patternCount or 8
	local borderBoost    = treatment.borderBoost or 0
	local portraitBoost  = treatment.portraitBoost or 0

	-- Phase 1 + 2: flash, particles, and rarity-specific suspense.
	local revealPreDelay = playRevealEffect(card.rarity)
	if revealPreDelay > 0 then
		task.wait(revealPreDelay)
	end
	local rarityDelay = REVEAL_DELAYS[card.rarity] or 0.08
	if rarityDelay > 0 then
		task.wait(rarityDelay)
	end

	local cardWidth = 184 + math.min(borderBoost, 5) * 5
	local cardHeight = 258 + math.min(borderBoost, 5) * 7
	local revealPos = UDim2.new(0.5, 0, 0.46, 0)
	local startPos = getWorldScreenTarget(payload.packWorldPosition, UDim2.new(0.5, 0, 0.78, 0))
	local focus = makeRevealFocus(style, tier, revealPos)

	local cardPanel = make("Frame", {
		Name = "CardReveal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = startPos,
		Size = UDim2.fromOffset(math.max(18, cardWidth * 0.18), cardHeight),
		BackgroundColor3 = darkColor,
		BorderSizePixel = 0,
		Rotation = -16,
		ZIndex = 200,
		ClipsDescendants = false,
	}, screenGui)
	addCorner(cardPanel, 18)
	local outerStroke = addStroke(cardPanel, trimColor, 3 + math.min(borderBoost, 5) * 0.45, tier >= 2 and 0.02 or 0.14)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, darkColor),
			ColorSequenceKeypoint.new(0.24, secondaryColor),
			ColorSequenceKeypoint.new(0.58, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), tier >= 2 and 0.28 or 0.12)),
			ColorSequenceKeypoint.new(0.80, tier >= 4 and glowColor or secondaryColor),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 146,
	}, cardPanel)

	local cardScale = make("UIScale", { Scale = 0.84 }, cardPanel)

	local railWidth = 8 + math.min(borderBoost, 5) * 1.7
	for _, rail in ipairs({
		{ anchor = Vector2.new(0, 0), position = UDim2.fromScale(0, 0), rotation = 0 },
		{ anchor = Vector2.new(1, 0), position = UDim2.fromScale(1, 0), rotation = 0 },
	}) do
		local railFrame = make("Frame", {
			AnchorPoint = rail.anchor,
			BackgroundColor3 = glowColor,
			BackgroundTransparency = tier >= 3 and 0.08 or 0.22,
			BorderSizePixel = 0,
			Position = rail.position,
			Size = UDim2.new(0, railWidth, 1, 0),
			ZIndex = 201,
		}, cardPanel)
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, trimColor),
				ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, trimColor),
			}),
			Rotation = 90,
		}, railFrame)
	end

	for index = 1, patternCount do
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = tier >= 3 and 0.78 or (tier >= 1 and 0.86 or 0.93),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, index / (patternCount + 1)),
			Rotation = tier >= 4 and -32 or -22,
			Size = UDim2.new(tier >= 3 and 1.45 or 1.25, 0, 0, tier >= 4 and 2 or 1),
			ZIndex = 201,
		}, cardPanel)
	end

	local topTag = nil

	local innerGlow = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -12, 1, -12),
		ZIndex = 207,
	}, cardPanel)
	addCorner(innerGlow, 14)
	local innerStroke = addStroke(innerGlow, glowColor, (tier >= 2 and 2.2 or 1.4) + math.min(borderBoost, 4) * 0.2, tier >= 1 and 0.34 or 0.58)

	local aura
	local auraStroke
	if tier >= 1 then
		aura = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 28, 1, 28),
			Visible = false,
			ZIndex = 199,
		}, cardPanel)
		addCorner(aura, 24)
		auraStroke = addStroke(aura, glowColor, tier >= 3 and 5 or 3.5, tier >= 3 and 0.22 or 0.36)
	end

	local cardBack = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(5, 7, 13),
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 214,
	}, cardPanel)
	addCorner(cardBack, 18)
	addStroke(cardBack, trimColor, 1.4, 0.24)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, glowColor:Lerp(Color3.fromRGB(0, 0, 0), 0.35)),
			ColorSequenceKeypoint.new(0.54, Color3.fromRGB(5, 7, 13)),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 156,
	}, cardBack)

	make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0.82, 0, 0.28, 0),
		Text = "PACK THAT PLAYER",
		TextColor3 = textColor,
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 215,
	}, cardBack)

	make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.64),
		Size = UDim2.new(0.82, 0, 0.10, 0),
		Text = string.upper(style.label or card.rarity or "CARD"),
		TextColor3 = glowColor,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 215,
	}, cardBack)

	local frontGroup = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 202,
	}, cardPanel)

	local frameAsset = CardFrames.GetAsset(card.rarity)
	local frameAccent = CardFrames.GetAccent(card.rarity)
	local frameTextColor = frameAccent.text or textColor
	local displayRarityLabel = string.upper(style.label or card.rarity or "CARD")
	local surname = string.upper((card.name or "Player"):match("(%S+)%s*$") or (card.name or "Player"))
	local revealIncome = payload.coinsPerSecond or card.fansPerSecond or 0

	if frameAsset then
		local frameImage = make("ImageLabel", {
			BackgroundTransparency = 1,
			Image = frameAsset,
			ScaleType = Enum.ScaleType.Stretch,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 203,
		}, frontGroup)
		addCorner(frameImage, 18)
	end

	local interiorWash = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = frameAccent.wash or rarityColor,
		BackgroundTransparency = frameAccent.washTransparency or 0.54,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.190),
		Size = UDim2.fromScale(0.82, 0.515),
		ZIndex = 204,
	}, frontGroup)
	addCorner(interiorWash, 14)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, frameAccent.glow or glowColor),
			ColorSequenceKeypoint.new(0.50, frameAccent.wash or rarityColor),
			ColorSequenceKeypoint.new(1, (frameAccent.wash or rarityColor):Lerp(Color3.fromRGB(0, 0, 0), 0.35)),
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
		BackgroundColor3 = frameAccent.glow or glowColor,
		BackgroundTransparency = frameAccent.glowTransparency or 0.70,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.420),
		Size = UDim2.fromScale(0.56, 0.26),
		ZIndex = 204,
	}, frontGroup)
	addCorner(softGlow, 80)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.50, 0.00),
			NumberSequenceKeypoint.new(1, 0.88),
		}),
	}, softGlow)

	local function makeFrameLabel(labelProps, strokeThickness, strokeTransparency, minTextSize, maxTextSize)
		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			Position = labelProps.Position,
			Size = labelProps.Size,
			Text = labelProps.Text,
			TextColor3 = labelProps.TextColor3 or frameTextColor,
			TextScaled = true,
			TextWrapped = labelProps.TextWrapped or false,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 206,
		}, frontGroup)
		make("UITextSizeConstraint", { MinTextSize = minTextSize, MaxTextSize = maxTextSize }, label)
		addStroke(label, Color3.fromRGB(0, 0, 0), strokeThickness, strokeTransparency)
		return label
	end

	makeFrameLabel({
		Position = UDim2.fromScale(0.11, 0.043),
		Size = UDim2.fromScale(0.78, 0.055),
		Text = displayRarityLabel,
	}, 1.4, 0.18, tier >= 5 and 5 or 6, tier >= 5 and 12 or 15)

	makeFrameLabel({
		Position = UDim2.fromScale(0.07, 0.126),
		Size = UDim2.fromScale(0.40, 0.06),
		Text = string.upper(card.position or "--"),
	}, 1.1, 0.22, 6, 14)

	makeFrameLabel({
		Position = UDim2.fromScale(0.53, 0.126),
		Size = UDim2.fromScale(0.40, 0.06),
		Text = card.nation or "Unknown",
	}, 1.1, 0.24, 6, 13)

	makeFrameLabel({
		Position = UDim2.fromScale(0.09, 0.515),
		Size = UDim2.fromScale(0.82, 0.09),
		Text = surname,
	}, 2, 0.08, 12, tier >= 5 and 26 or 30)

	makeFrameLabel({
		Position = UDim2.fromScale(0.07, 0.742),
		Size = UDim2.fromScale(0.86, 0.07),
		Text = string.upper(card.name or "Player"),
		TextColor3 = Color3.fromRGB(255, 255, 245),
		TextWrapped = true,
	}, 1.3, 0.20, 7, 16)

	makeFrameLabel({
		Position = UDim2.fromScale(0.09, 0.858),
		Size = UDim2.fromScale(0.82, 0.075),
		Text = "+" .. Utils.FormatNumber(revealIncome) .. " fans/s",
		TextColor3 = Color3.fromRGB(184, 255, 196),
	}, 1.4, 0.18, 7, 16)

	task.wait(0.04)
	local riseTime = 0.34 + (math.min(tier, 3) * 0.03)
	TweenService:Create(cardPanel, TweenInfo.new(riseTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = revealPos,
		Rotation = -4,
		Size = UDim2.fromOffset(cardWidth, cardHeight),
	}):Play()
	TweenService:Create(cardScale, TweenInfo.new(riseTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
	task.wait(riseTime + (tier >= 3 and 0.24 or (tier >= 2 and 0.12 or 0.04)))

	TweenService:Create(cardPanel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(18, cardHeight),
		Rotation = 7,
	}):Play()
	task.wait(0.12)

	cardBack.Visible = false
	frontGroup.Visible = true
	if topTag then
		topTag.Visible = true
	end
	if aura then
		aura.Visible = true
	end

	TweenService:Create(cardPanel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(cardWidth, cardHeight),
		Rotation = 0,
	}):Play()
	task.wait(0.12)

	showImpactFlash(glowColor, tier >= 2)
	spawnParticleBurst(glowColor, tier >= 2 and 28 or 12, payload.packWorldPosition, tier >= 2 and 0.86 or 0.45)
	burstRevealRing(cardPanel, glowColor, tier)
	if tier >= 2 then
		shakeCamera(tier >= 3 and 0.11 or 0.06, 0.16, tier >= 3 and 7 or 5)
	end

	TweenService:Create(cardScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.04 + (math.min(tier, 3) * 0.015),
	}):Play()
	TweenService:Create(outerStroke, TweenInfo.new(0.20, Enum.EasingStyle.Quad), {
		Transparency = 0,
	}):Play()
	TweenService:Create(innerStroke, TweenInfo.new(0.20, Enum.EasingStyle.Quad), {
		Transparency = tier >= 2 and 0.08 or 0.24,
	}):Play()
	task.delay(0.14, function()
		if cardScale.Parent then
			TweenService:Create(cardScale, TweenInfo.new(0.24, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
		end
	end)

	local function pulseAura()
		if not aura or not aura.Parent or not auraStroke then return end
		TweenService:Create(aura, TweenInfo.new(0.58, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.new(1, 48, 1, 48),
		}):Play()
		TweenService:Create(auraStroke, TweenInfo.new(0.58, Enum.EasingStyle.Sine), {
			Transparency = 0.82,
		}):Play()
		task.delay(0.58, function()
			if aura and aura.Parent then
				TweenService:Create(aura, TweenInfo.new(0.58, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Size = UDim2.new(1, 28, 1, 28),
				}):Play()
				TweenService:Create(auraStroke, TweenInfo.new(0.58, Enum.EasingStyle.Sine), {
					Transparency = tier >= 3 and 0.22 or 0.36,
				}):Play()
			end
		end)
	end
	pulseAura()
	task.delay(1.15, pulseAura)

	task.delay(0.16, function()
		if cardPanel.Parent then
			sweepShimmer(cardPanel, glowColor:Lerp(Color3.fromRGB(255, 255, 255), 0.35))
		end
	end)
	if tier >= 2 then
		task.delay(0.72, function()
			if cardPanel.Parent then
				sweepShimmer(cardPanel, glowColor)
			end
		end)
	end

	local holdTime = tier >= 3 and 2.45 or (tier >= 2 and 2.15 or 1.85)
	task.delay(holdTime, function()
		if not cardPanel.Parent then
			clearRevealFocus(focus)
			return
		end

		clearRevealFocus(focus)
		local flyTarget = toInventory
			and getGuiCenterTarget(inventoryButton, UDim2.new(0.16, 0, 0.72, 0))
			or getWorldScreenTarget(payload.slotWorldPosition, UDim2.new(0.5, 0, 0.72, 0))

		TweenService:Create(cardPanel, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = flyTarget,
			Rotation = tier >= 2 and 8 or 0,
		}):Play()
		TweenService:Create(cardScale, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Scale = 0,
		}):Play()

		task.delay(0.34, function()
			if cardPanel.Parent then cardPanel:Destroy() end
		end)
	end)
end

local activePlayerPickOverlay

local function closePlayerPickOverlay()
	if activePlayerPickOverlay and activePlayerPickOverlay.Parent then
		activePlayerPickOverlay:Destroy()
	end
	activePlayerPickOverlay = nil
end

local function getPlayerPickOptionScore(card)
	local rarityScore = (REVEAL_TIERS[card and card.rarity] or 0) * 1000000
	local incomeScore = math.floor(tonumber(card and card.fansPerSecond) or 0)
	return rarityScore + incomeScore
end

local function showPlayerPick(payload)
	local options = payload and payload.pickOptions or {}
	if type(options) ~= "table" or #options == 0 then
		showToast("Player pick failed. Try again.", UI.Danger)
		return
	end

	local bestIndex = nil
	local bestScore = -math.huge
	local secondScore = -math.huge
	for index, card in ipairs(options) do
		local score = getPlayerPickOptionScore(card)
		if score > bestScore then
			secondScore = bestScore
			bestScore = score
			bestIndex = index
		elseif score > secondScore then
			secondScore = score
		end
	end
	local shouldMarkTopPull = bestIndex ~= nil and bestScore > secondScore

	closePlayerPickOverlay()
	local overlay = make("Frame", {
		Name = "PlayerPickOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 230,
	}, screenGui)
	activePlayerPickOverlay = overlay
	TweenService:Create(overlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.18,
	}):Play()

	local panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.new(0.90, 0, 0, 344),
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		ZIndex = 231,
	}, overlay)
	addCorner(panel, 18)
	addStroke(panel, UI.Gold, 2, 0.22)
	make("UISizeConstraint", {
		MaxSize = Vector2.new(850, 360),
		MinSize = Vector2.new(360, 320),
	}, panel)

	local panelScale = make("UIScale", { Scale = 0.92 }, panel)
	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.52),
	}):Play()
	TweenService:Create(panelScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	local title = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 0, 14),
		Size = UDim2.new(1, -44, 0, 34),
		Text = string.upper(payload.packName or "Player Pick"),
		TextColor3 = UI.Text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 232,
	}, panel)
	make("UITextSizeConstraint", { MinTextSize = 18, MaxTextSize = 30 }, title)

	local subtitle = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 0, 48),
		Size = UDim2.new(1, -44, 0, 20),
		Text = "Scouting your options...",
		TextColor3 = Color3.fromRGB(198, 190, 164),
		TextScaled = false,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 232,
	}, panel)

	local row = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 82),
		Size = UDim2.new(1, -36, 1, -102),
		ZIndex = 232,
	}, panel)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)

	local choosing = false
	local buttons = {}
	local revealCards = {}
	for index, card in ipairs(options) do
		local style = Utils.GetRarityStyle(card.rarity)
		local primary = style.primary
		local secondary = style.secondary or primary
		local dark = style.dark or Color3.fromRGB(12, 14, 22)
		local textColor = style.text or UI.Text

		local button = make("TextButton", {
			LayoutOrder = index,
			Size = UDim2.new(1 / #options, -8, 1, 0),
			BackgroundColor3 = dark,
			BackgroundTransparency = 0.20,
			BorderSizePixel = 0,
			Text = "",
			Active = false,
			AutoButtonColor = false,
			ZIndex = 233,
		}, row)
		table.insert(buttons, button)
		addCorner(button, 12)
		addStroke(button, primary, 2, 0.18)
		local buttonScale = make("UIScale", { Scale = 0.86 }, button)
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, dark),
				ColorSequenceKeypoint.new(0.55, secondary),
				ColorSequenceKeypoint.new(1, dark),
			}),
			Rotation = 145,
		}, button)

		if shouldMarkTopPull and index == bestIndex then
			local topBadge = make("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = primary:Lerp(Color3.fromRGB(255, 255, 255), 0.10),
				Position = UDim2.new(1, -12, 0, 42),
				Size = UDim2.fromOffset(78, 18),
				Text = "TOP PULL",
				TextColor3 = textColor,
				TextScaled = false,
				TextSize = 8,
				Font = Enum.Font.GothamBlack,
				ZIndex = 236,
			}, button)
			addCorner(topBadge, 9)
			addStroke(topBadge, primary, 1, 0.18)
		end

		make("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(6, 8, 13),
			BackgroundTransparency = 0.06,
			Position = UDim2.new(0, 12, 0, 12),
			Size = UDim2.new(1, -24, 0, 24),
			Text = string.upper(style.label or card.rarity or "CARD"),
			TextColor3 = textColor,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBlack,
			ZIndex = 234,
		}, button)

		local badge = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 58),
			Size = UDim2.fromOffset(62, 62),
			Rotation = 45,
			BackgroundColor3 = Color3.fromRGB(8, 10, 18),
			BorderSizePixel = 0,
			ZIndex = 234,
		}, button)
		addCorner(badge, 10)
		addStroke(badge, primary, 2, 0.16)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Rotation = -45,
			Text = string.upper(string.sub(card.name or "P", 1, 1)),
			TextColor3 = textColor,
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
			ZIndex = 235,
		}, badge)

		local nameLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 134),
			Size = UDim2.new(1, -20, 0, 42),
			Text = string.upper(card.name or "Player"),
			TextColor3 = textColor,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
			ZIndex = 234,
		}, button)
		make("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 20 }, nameLabel)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 180),
			Size = UDim2.new(1, -20, 0, 18),
			Text = (card.position or "--") .. "  |  " .. (card.nation or "Unknown"),
			TextColor3 = textColor,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBlack,
			ZIndex = 234,
		}, button)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 202),
			Size = UDim2.new(1, -20, 0, 18),
			Text = "+" .. Utils.FormatNumber(card.fansPerSecond or 0) .. " fans/s",
			TextColor3 = Color3.fromRGB(168, 244, 184),
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBlack,
			ZIndex = 234,
		}, button)

		local pickLabel = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = primary:Lerp(Color3.fromRGB(22, 124, 62), 0.36),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.new(1, -24, 0, 26),
			Text = "PICK",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = false,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			ZIndex = 235,
		}, button)
		addCorner(pickLabel, 8)

		local cover = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(5, 7, 13),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 240,
		}, button)
		addCorner(cover, 12)
		addStroke(cover, primary, 2, 0.12)
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, primary:Lerp(Color3.fromRGB(0, 0, 0), 0.42)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(5, 7, 13)),
				ColorSequenceKeypoint.new(1, dark),
			}),
			Rotation = 145,
		}, cover)
		make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(76, 76),
			Text = "?",
			TextColor3 = primary,
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
			ZIndex = 241,
		}, cover)
		make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.66),
			Size = UDim2.new(0.84, 0, 0, 22),
			Text = "SCOUTING",
			TextColor3 = Color3.fromRGB(220, 214, 186),
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBlack,
			ZIndex = 241,
		}, cover)
		table.insert(revealCards, {
			button = button,
			scale = buttonScale,
			cover = cover,
			color = primary,
		})

		button.MouseButton1Click:Connect(function()
			if choosing then
				return
			end
			choosing = true
			for _, otherButton in ipairs(buttons) do
				otherButton.Active = false
				otherButton.AutoButtonColor = false
			end
			pickLabel.Text = "CLAIMING..."
			pickLabel.BackgroundColor3 = Color3.fromRGB(35, 140, 65)
			TweenService:Create(buttonScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1.06,
			}):Play()

			local ok, result = pcall(function()
				return ChoosePlayerPickFn:InvokeServer(index)
			end)
			if ok and result and result.success then
				pickLabel.Text = "SIGNED"
				task.delay(0.22, closePlayerPickOverlay)
			else
				choosing = false
				for _, otherButton in ipairs(buttons) do
					otherButton.Active = true
					otherButton.AutoButtonColor = true
				end
				pickLabel.Text = "PICK"
				pickLabel.BackgroundColor3 = primary:Lerp(Color3.fromRGB(22, 124, 62), 0.36)
				TweenService:Create(buttonScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Scale = 1,
				}):Play()
				local errorText = "Player pick failed. Try again."
				if ok and type(result) == "table" and result.error then
					errorText = result.error
				end
				showToast(errorText, UI.Danger)
			end
		end)
	end

	showImpactFlash(UI.Gold, true)
	task.spawn(function()
		task.wait(0.18)
		for index, entry in ipairs(revealCards) do
			if not overlay.Parent then
				return
			end

			TweenService:Create(entry.scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
			TweenService:Create(entry.cover, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 8, 1, 0),
				Position = UDim2.fromScale(0.5, 0),
			}):Play()
			task.delay(0.13, function()
				if entry.cover and entry.cover.Parent then
					entry.cover:Destroy()
				end
				spawnParticleBurst(entry.color, 8, nil, 0.30)
			end)
			task.wait(0.16)
		end

		for _, button in ipairs(buttons) do
			if button and button.Parent then
				button.Active = true
				button.AutoButtonColor = true
			end
		end
		if subtitle.Parent then
			subtitle.Text = "Pick one player"
			subtitle.TextColor3 = Color3.fromRGB(220, 214, 186)
		end
	end)
end

PackHitFeedbackEvent.OnClientEvent:Connect(function(payload)
	local ok, err = pcall(playPackHitFeedback, payload)
	if not ok then
		warn("[UnboxAFootballer] Pack hit feedback failed:", err)
	end
end)

MilestoneRewardEvent.OnClientEvent:Connect(function(payload)
	if popupsMuted then
		return
	end

	local ok, err = pcall(showMilestoneRewardPopup, payload)
	if not ok then
		warn("[UnboxAFootballer] Milestone popup failed:", err)
	end
end)

QuestUpdatedEvent.OnClientEvent:Connect(function(payload)
	applyQuestNotification(payload)
end)

PackOpenedEvent.OnClientEvent:Connect(function(payload)
	if not payload or not payload.success then
		return
	end

	setCoinsDisplay(payload.newCoins)
	refreshCoachSoon(payload.playerPick and 1.0 or 2.8)

	if payload.playerPick then
		local ok, err = pcall(showPlayerPick, payload)
		if not ok then
			warn("[UnboxAFootballer] Player pick UI failed:", err)
			showToast("Player pick is ready, but the UI failed. Rejoin to recover.", UI.Danger)
		end
		return
	end

	if payload.card then
		local ok, err = pcall(showCardReveal, payload)
		if not ok then
			warn("[UnboxAFootballer] Card reveal failed:", err)
			local destination = payload.storedInInventory and "Inventory" or ("display slot " .. tostring(payload.slotIndex or "?"))
			showToast(payload.card.name .. " added to " .. destination .. ".", UI.Gold)
		end
	end
end)

PackOpenFailedEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end

	showToast(payload.error or "Pack could not be opened.", UI.Danger)
end)

PromptPackShopEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end

	if payload.coins ~= nil then
		setCoinsDisplay(payload.coins)
	end
	if payload.message then
		showToast(payload.message, payload.accent or UI.Gold)
	end
	refreshCoachSoon(0.6)
end)

task.spawn(function()
	task.wait(1)
	refreshStatus()
end)

local function onCharacterAdded(character)
	task.delay(0.25, function()
		if player.Parent and character.Parent then
			snapCameraToOwnedBase(character)
		end
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
