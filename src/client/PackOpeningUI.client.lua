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
	showToast("Quests are coming soon. This button is ready for the next system.", Color3.fromRGB(110, 130, 255))
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

-- ── Particle burst helper ─────────────────────────────────────────────────────
-- Spawns `count` small coloured dots that fly outward from screen centre.
local function spawnParticleBurst(color, count)
	local camera = Workspace.CurrentCamera
	local vp     = camera and camera.ViewportSize or Vector2.new(1024, 768)
	local cx, cy = vp.X / 2, vp.Y * 0.44
	for i = 1, count do
		local angle    = (i / count) * (math.pi * 2) + (math.random() - 0.5) * 0.9
		local dist     = 80 + math.random(20, 110)
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
-- Gold       = tier 0 : subtle flash only (new)
-- Talisman   = tier 1 : stronger flash + particle burst
-- Maestro    = tier 2 : flash + particles + rarity burst label + cinematic bars
-- Immortal/POTY = tier 3 : all of the above + camera shake
-- Returns seconds the caller should wait before showing the card panel.
local REVEAL_TIERS = {
	["Talisman"]           = 1,
	["Maestro"]            = 2,
	["Immortal"]           = 3,
	["Player of the Year"] = 3,
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

	return tier == 1 and 0.12 or (tier == 2 and 0.30 or 0.38)
end

-- ── Card reveal ───────────────────────────────────────────────────────────────
-- 5-phase sequence matching the reference design:
--   1. INITIATE  — flash fires (playRevealEffect)
--   2. BUILD UP  — particles burst outward
--   3. FLASH     — card animates up from below with scale bounce
--   4. REVEAL    — shimmer sweep + rarity aura pulse
--   5. RESULT    — result stats shown, card flies to slot/inventory
local function showCardReveal(payload)
	local card = payload.card
	if not card then return end

	-- Phase 1 + 2: flash & particles — wait for pre-delay before card appears
	local revealPreDelay = playRevealEffect(card.rarity)
	if revealPreDelay > 0 then
		task.wait(revealPreDelay)
	end

	local style         = Utils.GetRarityStyle(card.rarity)
	local rarityColor   = style.primary
	local secondaryColor = style.secondary or rarityColor
	local darkColor     = style.dark or Color3.fromRGB(10, 5, 2)
	local trimColor     = style.trim or rarityColor
	local textColor     = style.text or Color3.fromRGB(255, 255, 255)
	local income        = payload.coinsPerSecond or 0
	local toInventory   = payload.storedInInventory == true
	local tier          = REVEAL_TIERS[card.rarity] or 0

	-- Card is 180 × 290 px — taller than before to fit the result stats row
	local CARD_W, CARD_H = 180, 290
	local revealPos = UDim2.new(0.5, 0, 0.46, 0)

	-- ── Phase 3: REVEAL — card panel ─────────────────────────────────
	-- Starts small and below-centre; slides up with a bounce pop-in.
	local cardPanel = make("Frame", {
		Name             = "CardReveal",
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0.5, 0, 0.78, 0),   -- below screen centre
		Size             = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = darkColor,
		ZIndex           = 200,
	}, screenGui)
	addCorner(cardPanel, 16)
	addStroke(cardPanel, trimColor, 3)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12)),
			ColorSequenceKeypoint.new(0.48, secondaryColor),
			ColorSequenceKeypoint.new(1,    darkColor),
		}),
		Rotation = 158,
	}, cardPanel)

	-- UIScale drives the bounce pop-in (starts tiny, springs to full size)
	local cardScale = make("UIScale", { Scale = 0.06 }, cardPanel)

	-- ── Phase 4: REVEAL aura — pulsing glow ring (tier 1+) ───────────
	-- Lives inside cardPanel so it follows the card automatically.
	if tier >= 1 then
		local aura = make("Frame", {
			AnchorPoint          = Vector2.new(0.5, 0.5),
			Position             = UDim2.fromScale(0.5, 0.5),
			Size                 = UDim2.new(1, 22, 1, 22),   -- 11 px outside card edge
			BackgroundTransparency = 1,
			ZIndex               = 199,
		}, cardPanel)
		addCorner(aura, 22)
		local auraStroke = addStroke(aura, rarityColor, 4, 0.36)

		local function pulseAura()
			if not aura.Parent then return end
			TweenService:Create(aura, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(1, 40, 1, 40),
			}):Play()
			TweenService:Create(auraStroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
				Transparency = 0.80,
			}):Play()
			task.delay(0.55, function()
				if aura.Parent then
					TweenService:Create(aura, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Size = UDim2.new(1, 22, 1, 22),
					}):Play()
					TweenService:Create(auraStroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
						Transparency = 0.36,
					}):Play()
				end
			end)
		end

		task.delay(0.40, pulseAura)
		task.delay(1.50, pulseAura)
	end

	-- ── Rarity band ───────────────────────────────────────────────────
	local rarityBand = make("Frame", {
		AnchorPoint      = Vector2.new(0.5, 0),
		Position         = UDim2.new(0.5, 0, 0, 12),
		Size             = UDim2.fromOffset(142, 24),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.10,
		BorderSizePixel  = 0,
		ZIndex           = 202,
	}, cardPanel)
	addCorner(rarityBand, 12)
	addStroke(rarityBand, trimColor, 1.2, 0.28)

	local rarityLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Size       = UDim2.fromScale(1, 1),
		Text       = string.upper(style.label or card.rarity or "CARD"),
		TextColor3 = textColor,
		TextScaled = false,
		TextSize   = 12,
		Font       = Enum.Font.GothamBlack,
		ZIndex     = 203,
	}, rarityBand)
	addStroke(rarityLabel, Color3.fromRGB(6, 3, 1), 1, 0.35)

	-- ── Position badge (top-left) ─────────────────────────────────────
	local positionBadge = make("Frame", {
		Position         = UDim2.fromOffset(14, 47),
		Size             = UDim2.fromOffset(46, 24),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.08,
		BorderSizePixel  = 0,
		ZIndex           = 202,
	}, cardPanel)
	addCorner(positionBadge, 8)
	addStroke(positionBadge, trimColor, 1, 0.35)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size       = UDim2.fromScale(1, 1),
		Text       = card.position or "--",
		TextColor3 = textColor,
		TextScaled = false,
		TextSize   = 12,
		Font       = Enum.Font.GothamBlack,
		ZIndex     = 203,
	}, positionBadge)

	-- ── Nation (top-right) ────────────────────────────────────────────
	make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint    = Vector2.new(1, 0),
		Position       = UDim2.new(1, -12, 0, 51),
		Size           = UDim2.fromOffset(92, 16),
		Text           = card.nation or "Unknown",
		TextColor3     = textColor,
		TextScaled     = false,
		TextSize       = 11,
		Font           = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex         = 202,
	}, cardPanel)

	-- ── Divider ───────────────────────────────────────────────────────
	make("Frame", {
		AnchorPoint      = Vector2.new(0.5, 0),
		Position         = UDim2.new(0.5, 0, 0, 78),
		Size             = UDim2.new(0.84, 0, 0, 1.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.55,
		BorderSizePixel  = 0,
		ZIndex           = 202,
	}, cardPanel)

	-- ── Monogram circle — tinted by rarity colour ─────────────────────
	local monogram = make("Frame", {
		AnchorPoint      = Vector2.new(0.5, 0),
		Position         = UDim2.new(0.5, 0, 0, 86),
		Size             = UDim2.fromOffset(84, 84),
		BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(12, 16, 30), 0.45),
		BackgroundTransparency = 0.10,
		ZIndex           = 201,
	}, cardPanel)
	addCorner(monogram, 42)
	addStroke(monogram, rarityColor, 2.5, 0.25)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size             = UDim2.fromScale(1, 1),
		Text             = string.upper(string.sub(card.name, 1, 1)),
		TextColor3       = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0,
		TextScaled       = true,
		Font             = Enum.Font.GothamBlack,
		ZIndex           = 202,
	}, monogram)

	-- ── Player name ───────────────────────────────────────────────────
	local nameLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint    = Vector2.new(0.5, 0),
		Position       = UDim2.new(0.5, 0, 0, 178),
		Size           = UDim2.new(0.90, 0, 0, 38),
		Text           = string.upper(card.name),
		TextColor3     = Color3.fromRGB(255, 255, 255),
		TextScaled     = true,
		TextWrapped    = true,
		Font           = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex         = 202,
	}, cardPanel)
	make("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 22 }, nameLabel)
	addStroke(nameLabel, Color3.fromRGB(6, 3, 1), 1.2, 0.20)

	-- ── Phase 5: RESULT stats panel ───────────────────────────────────
	-- Shows destination + income/s on row 1, total fans on row 2.
	local destStr    = toInventory
		and ("→ Inventory   +" .. Utils.FormatNumber(income) .. "/s")
		or  ("→ Slot " .. tostring(payload.slotIndex) .. "   +" .. Utils.FormatNumber(income) .. "/s")
	local pillAccent = toInventory and Color3.fromRGB(110, 130, 210) or Color3.fromRGB(74, 185, 98)
	local pillBg     = toInventory and Color3.fromRGB(14, 20, 44)    or Color3.fromRGB(10, 32, 18)

	local resultPanel = make("Frame", {
		AnchorPoint      = Vector2.new(0.5, 0),
		Position         = UDim2.new(0.5, 0, 0, 224),   -- 8 px below name
		Size             = UDim2.fromOffset(162, 52),
		BackgroundColor3 = pillBg,
		ZIndex           = 202,
	}, cardPanel)
	addCorner(resultPanel, 12)
	addStroke(resultPanel, pillAccent, 1.5, 0.22)

	-- Row 1: destination + income/s
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position       = UDim2.new(0, 10, 0, 5),
		Size           = UDim2.new(1, -20, 0, 18),
		Text           = destStr,
		TextColor3     = pillAccent,
		TextScaled     = false,
		TextSize       = 11,
		Font           = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex         = 203,
	}, resultPanel)

	-- Thin divider between rows
	make("Frame", {
		Position         = UDim2.new(0, 10, 0, 25),
		Size             = UDim2.new(1, -20, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.78,
		BorderSizePixel  = 0,
		ZIndex           = 203,
	}, resultPanel)

	-- Row 2: total fans
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position       = UDim2.new(0, 10, 0, 28),
		Size           = UDim2.new(1, -20, 0, 18),
		Text           = "\u{2605}  " .. Utils.FormatNumber(payload.newCoins or 0) .. " total fans",
		TextColor3     = UI.Gold,
		TextScaled     = false,
		TextSize       = 11,
		Font           = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex         = 203,
	}, resultPanel)

	-- ── Pop-in: slide up from below + scale bounce ────────────────────
	task.wait(0.04)
	TweenService:Create(cardPanel,
		TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = revealPos }
	):Play()
	TweenService:Create(cardScale,
		TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()

	-- ── Shimmer sweep once the card has landed ────────────────────────
	task.delay(0.38, function()
		if cardPanel.Parent then
			sweepShimmer(cardPanel, Color3.fromRGB(255, 255, 255))
		end
	end)

	-- ── Fly-off after 1.9 s ──────────────────────────────────────────
	task.delay(1.9, function()
		if not cardPanel.Parent then return end

		local flyTarget = toInventory
			and getGuiCenterTarget(inventoryButton, UDim2.new(0.16, 0, 0.72, 0))
			or  getWorldScreenTarget(payload.slotWorldPosition, UDim2.new(0.5, 0, 0.72, 0))

		TweenService:Create(cardPanel,
			TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = flyTarget }
		):Play()
		TweenService:Create(cardScale,
			TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 0 }
		):Play()

		task.delay(0.34, function()
			if cardPanel.Parent then cardPanel:Destroy() end
		end)
	end)
end

PackOpenedEvent.OnClientEvent:Connect(function(payload)
	if not payload or not payload.success then
		return
	end

	setCoinsDisplay(payload.newCoins)

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
