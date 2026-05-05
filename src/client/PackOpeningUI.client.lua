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
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local UpdateCoinsEvent = Remotes:WaitForChild("UpdateCoins")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")
local PackOpenFailedEvent = Remotes:WaitForChild("PackOpenFailed")
local PromptPackShopEvent = Remotes:WaitForChild("PromptPackShop")
local PackHitFeedbackEvent = Remotes:WaitForChild("PackHitFeedback")
local MilestoneRewardEvent = Remotes:WaitForChild("MilestoneReward")
local ChoosePlayerPickFn = Remotes:WaitForChild("ChoosePlayerPick")

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
	SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.32,
	PlaybackSpeed = 0.86,
}, screenGui)

local finalBreakSound = make("Sound", {
	Name = "PackFinalBreakSound",
	SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.48,
	PlaybackSpeed = 0.78,
}, screenGui)

local revealSound = make("Sound", {
	Name = "CardRevealSound",
	SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.36,
	PlaybackSpeed = 1.18,
}, screenGui)

local cardRiseSound = make("Sound", {
	Name = "CardRiseSound",
	SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.22,
	PlaybackSpeed = 0.72,
}, screenGui)

local cardFlipSound = make("Sound", {
	Name = "CardFlipSound",
	SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.28,
	PlaybackSpeed = 1.52,
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

local walletDock = make("Frame", {
	Name = "WalletDock",
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(232, 98),
	Position = UDim2.new(1, -20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.08,
}, screenGui)
addCorner(walletDock, 16)
addStroke(walletDock, UI.Gold, 1.5, 0.68)

local walletPadding = make("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, walletDock)
_ = walletPadding

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, walletDock)

local function drawWalletGemIcon(parent, accentColor)
	local gem = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = accentColor,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(13, 13),
		Rotation = 45,
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 2,
	}, parent)
	addCorner(gem, 3)
	addStroke(gem, Color3.fromRGB(169, 239, 255), 1, 0.05)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(176, 246, 255)),
			ColorSequenceKeypoint.new(0.5, accentColor),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 132, 219)),
		}),
		Rotation = 35,
	}, gem)

	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(221, 255, 255),
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 8),
		Rotation = 45,
		Size = UDim2.fromOffset(7, 3),
		ZIndex = 3,
	}, parent)
end

local function createWalletRow(parent, order, labelText, iconText, iconColor)
	local row = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = UI.Panel,
	}, parent)
	addCorner(row, 10)
	addStroke(row, iconColor, 1.5, 0.7)

	local icon = make("Frame", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 8, 0.5, -13),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.72),
	}, row)
	addCorner(icon, 9)
	if iconText == "Gem" then
		drawWalletGemIcon(icon, iconColor)
	else
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = iconText,
			TextColor3 = iconColor,
			TextScaled = false,
			TextSize = 17,
			Font = Enum.Font.GothamBlack,
		}, icon)
	end

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 42, 0, 3),
		Size = UDim2.new(1, -82, 0, 12),
		Text = labelText,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local valueLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 42, 0, 14),
		Size = UDim2.new(1, -82, 0, 22),
		Text = "0",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local plusButton = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(32, 128, 55),
		Text = "+",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
	}, row)
	addCorner(plusButton, 8)

	return valueLabel, plusButton
end

local fansLabel, addFansButton = createWalletRow(walletDock, 1, "Fans", "F", UI.Gold)
local gemsLabel, addGemsButton = createWalletRow(walletDock, 2, "Gems", "Gem", Color3.fromRGB(69, 207, 255))

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

	make("TextLabel", {
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
	Position = UDim2.new(1, -20, 0, 92),
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(320, 420),
}, screenGui)

make("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 10),
}, toastHolder)

local function setCoinsDisplay(coins)
	fansLabel.Text = Utils.FormatNumber(coins or 0)
end

local function setGemsDisplay(gems)
	gemsLabel.Text = Utils.FormatNumber(gems or 0)
end

local function showToast(text, accent)
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

local function refreshStatus()
	local data = GetPlayerDataFn:InvokeServer()
	if not data then
		return
	end

	setCoinsDisplay(data.coins)
	setGemsDisplay(data.gems)
end

inventoryButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("InventoryUI") then
		showToast("Inventory UI is still loading. Try again in a second.", UI.Gold)
	end
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
end)

questsButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("QuestsUI") then
		showToast("Quests are still loading. Try again in a second.", Color3.fromRGB(205, 88, 255))
	end
end)

shopButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("ShopUI") then
		showToast("Shop is still loading. Try again in a second.", Color3.fromRGB(74, 185, 98))
	end
end)

addFansButton.MouseButton1Click:Connect(function()
	showToast("Fans come from displayed players. Future boosts will help you grow faster.", UI.Gold)
end)

addGemsButton.MouseButton1Click:Connect(function()
	showToast("Gems are planned for premium packs and cosmetics later.", Color3.fromRGB(69, 207, 255))
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins)
	setCoinsDisplay(coins)
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
-- Slides a bright diagonal stripe across `panel` once (card reveal shine).
local function sweepShimmer(panel, color)
	local shine = make("Frame", {
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.fromScale(-0.38, 0.5),
		Size             = UDim2.fromScale(0.38, 1.5),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.46,
		Rotation         = -22,
		BorderSizePixel  = 0,
		ZIndex           = 209,
	}, panel)
	TweenService:Create(shine, TweenInfo.new(0.44, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(1.38, 0.5),
	}):Play()
	task.delay(0.50, function()
		if shine.Parent then shine:Destroy() end
	end)
end

-- ── Rare pull screen effect ───────────────────────────────────────────────────
-- Gold       = tier 0 : quick flash
-- Premium    = tier 1 : particles + stronger shine
-- Talisman   = tier 2 : rarity label + cinematic bars
-- Maestro+   = tier 3/4 : suspense pause + impact shake
-- Returns seconds the caller should wait before showing the card panel.
local REVEAL_TIERS = {
	["Premium Gold"]       = 1,
	["Talisman"]           = 2,
	["Maestro"]            = 3,
	["Immortal"]           = 4,
	["Player of the Year"] = 4,
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

	-- Phase 1 + 2: flash, particles, and rarity-specific suspense.
	local revealPreDelay = playRevealEffect(card.rarity)
	if revealPreDelay > 0 then
		task.wait(revealPreDelay)
	end
	local rarityDelay = REVEAL_DELAYS[card.rarity] or 0.08
	if rarityDelay > 0 then
		task.wait(rarityDelay)
	end

	local cardWidth = 184 + math.min(tier, 3) * 6
	local cardHeight = 258 + math.min(tier, 3) * 7
	local revealPos = UDim2.new(0.5, 0, 0.46, 0)
	local startPos = getWorldScreenTarget(payload.packWorldPosition, UDim2.new(0.5, 0, 0.78, 0))
	local focus = makeRevealFocus(style, tier, revealPos)

	cardRiseSound.PlaybackSpeed = 0.72 + (tier * 0.04)
	cardRiseSound.Volume = 0.20 + (tier * 0.025)
	cardRiseSound:Play()

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
	local outerStroke = addStroke(cardPanel, trimColor, tier >= 2 and 4 or 3, tier >= 2 and 0.02 or 0.14)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, darkColor),
			ColorSequenceKeypoint.new(0.30, secondaryColor),
			ColorSequenceKeypoint.new(0.62, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), tier >= 2 and 0.24 or 0.12)),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 146,
	}, cardPanel)

	local cardScale = make("UIScale", { Scale = 0.84 }, cardPanel)

	for index = 1, 9 do
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = tier >= 2 and 0.86 or 0.92,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, index / 10),
			Rotation = -22,
			Size = UDim2.new(1.25, 0, 0, 1),
			ZIndex = 201,
		}, cardPanel)
	end

	local innerGlow = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -12, 1, -12),
		ZIndex = 207,
	}, cardPanel)
	addCorner(innerGlow, 14)
	local innerStroke = addStroke(innerGlow, glowColor, tier >= 2 and 2.2 or 1.4, tier >= 1 and 0.34 or 0.58)

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

	local rarityBand = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 13),
		Size = UDim2.fromOffset(cardWidth - 42, 26),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 204,
	}, frontGroup)
	addCorner(rarityBand, 13)
	addStroke(rarityBand, trimColor, 1.2, 0.18)

	local rarityLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = string.upper(style.label or card.rarity or "CARD"),
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamBlack,
		ZIndex = 205,
	}, rarityBand)
	addStroke(rarityLabel, Color3.fromRGB(6, 3, 1), 1, 0.30)

	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 78),
		Size = UDim2.new(0.84, 0, 0, 1.5),
		BackgroundColor3 = glowColor,
		BackgroundTransparency = 0.36,
		BorderSizePixel = 0,
		ZIndex = 203,
	}, frontGroup)

	local badgeGlow = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = glowColor,
		BackgroundTransparency = tier >= 2 and 0.60 or 0.74,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 86),
		Size = UDim2.fromOffset(104, 104),
		ZIndex = 202,
	}, frontGroup)
	addCorner(badgeGlow, 52)

	local badge = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(8, 10, 18),
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 102),
		Rotation = 45,
		Size = UDim2.fromOffset(70, 70),
		ZIndex = 204,
	}, frontGroup)
	addCorner(badge, 12)
	addStroke(badge, trimColor, 2.4, 0.12)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0),
		Rotation = -45,
		Size = UDim2.fromScale(1, 1),
		Text = string.upper(string.sub(card.name, 1, 1)),
		TextColor3 = textColor,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 205,
	}, badge)

	local nameLabel = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 178),
		Size = UDim2.new(0.90, 0, 0, 40),
		Text = string.upper(card.name),
		TextColor3 = textColor,
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 204,
	}, frontGroup)
	make("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 23 }, nameLabel)
	addStroke(nameLabel, Color3.fromRGB(6, 3, 1), 1.2, 0.18)

	local metaPanel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, cardHeight - 34),
		Size = UDim2.fromOffset(cardWidth - 36, 24),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		ZIndex = 204,
	}, frontGroup)
	addCorner(metaPanel, 12)
	addStroke(metaPanel, trimColor, 1.2, 0.24)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = (card.position or "--") .. "  |  " .. (card.nation or "Unknown"),
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 205,
	}, metaPanel)

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

	cardFlipSound.PlaybackSpeed = 1.36 + (tier * 0.04)
	cardFlipSound.Volume = 0.24 + (tier * 0.025)
	cardFlipSound:Play()
	TweenService:Create(cardPanel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(18, cardHeight),
		Rotation = 7,
	}):Play()
	task.wait(0.12)

	cardBack.Visible = false
	frontGroup.Visible = true
	if aura then
		aura.Visible = true
	end

	TweenService:Create(cardPanel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(cardWidth, cardHeight),
		Rotation = 0,
	}):Play()
	task.wait(0.12)

	revealSound.PlaybackSpeed = 1.08 + (tier * 0.05)
	revealSound.Volume = math.min(0.58, 0.34 + (tier * 0.045))
	revealSound:Play()
	showImpactFlash(glowColor, tier >= 2)
	spawnParticleBurst(glowColor, tier >= 2 and 28 or 12, payload.packWorldPosition, tier >= 2 and 0.86 or 0.45)
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
			sweepShimmer(cardPanel, Color3.fromRGB(255, 255, 255))
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

local function showPlayerPick(payload)
	local options = payload and payload.pickOptions or {}
	if type(options) ~= "table" or #options == 0 then
		showToast("Player pick failed. Try again.", UI.Danger)
		return
	end

	closePlayerPickOverlay()
	local overlay = make("Frame", {
		Name = "PlayerPickOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.24,
		ZIndex = 230,
	}, screenGui)
	activePlayerPickOverlay = overlay

	local panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
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

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 0, 48),
		Size = UDim2.new(1, -44, 0, 20),
		Text = "Pick one player",
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
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = true,
			ZIndex = 233,
		}, row)
		table.insert(buttons, button)
		addCorner(button, 12)
		addStroke(button, primary, 2, 0.18)
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, dark),
				ColorSequenceKeypoint.new(0.55, secondary),
				ColorSequenceKeypoint.new(1, dark),
			}),
			Rotation = 145,
		}, button)

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

			local ok, result = pcall(function()
				return ChoosePlayerPickFn:InvokeServer(index)
			end)
			if ok and result and result.success then
				closePlayerPickOverlay()
			else
				choosing = false
				for _, otherButton in ipairs(buttons) do
					otherButton.Active = true
					otherButton.AutoButtonColor = true
				end
				pickLabel.Text = "PICK"
				pickLabel.BackgroundColor3 = primary:Lerp(Color3.fromRGB(22, 124, 62), 0.36)
				local errorText = "Player pick failed. Try again."
				if ok and type(result) == "table" and result.error then
					errorText = result.error
				end
				showToast(errorText, UI.Danger)
			end
		end)
	end

	showImpactFlash(UI.Gold, true)
end

PackHitFeedbackEvent.OnClientEvent:Connect(function(payload)
	local ok, err = pcall(playPackHitFeedback, payload)
	if not ok then
		warn("[UnboxAFootballer] Pack hit feedback failed:", err)
	end
end)

MilestoneRewardEvent.OnClientEvent:Connect(function(payload)
	local ok, err = pcall(showMilestoneRewardPopup, payload)
	if not ok then
		warn("[UnboxAFootballer] Milestone popup failed:", err)
	end
end)

PackOpenedEvent.OnClientEvent:Connect(function(payload)
	if not payload or not payload.success then
		return
	end

	setCoinsDisplay(payload.newCoins)

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
