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
	Size = UDim2.fromOffset(190, 276),
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

local function createWalletRow(parent, order, labelText, iconText, iconColor)
	local row = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = UI.Panel,
	}, parent)
	addCorner(row, 10)
	addStroke(row, iconColor, 1.5, 0.7)

	local icon = make("TextLabel", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 8, 0.5, -13),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.72),
		Text = iconText,
		TextColor3 = iconColor,
		TextScaled = false,
		TextSize = 17,
		Font = Enum.Font.GothamBlack,
	}, row)
	addCorner(icon, 9)

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
local gemsLabel, addGemsButton = createWalletRow(walletDock, 2, "Gems", "D", Color3.fromRGB(69, 207, 255))

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

local function drawUpgradeIcon(parent, accentColor)
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(5, 1),
		Size = UDim2.fromOffset(32, 30),
		Text = "▲",
		TextColor3 = accentColor,
		TextScaled = false,
		TextSize = 26,
		Font = Enum.Font.GothamBlack,
		ZIndex = 3,
	}, parent)
	makeIconLine(parent, UDim2.fromOffset(21, 29), UDim2.fromOffset(10, 15), accentColor)
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
	local basket = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(9, 14),
		Size = UDim2.fromOffset(23, 15),
		ZIndex = 2,
	}, parent)
	addStroke(basket, accentColor, 3, 0)
	makeIconLine(parent, UDim2.fromOffset(12, 12), UDim2.fromOffset(15, 4), accentColor, 28)
	makeIconLine(parent, UDim2.fromOffset(18, 31), UDim2.fromOffset(17, 3), accentColor)

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
local upgradesButton  = createMenuButton(2, "Upgrades",  "upgrades",  UI.Gold)
local questsButton    = createMenuButton(3, "Quests",    "quests",    Color3.fromRGB(205, 88, 255))
local shopButton      = createMenuButton(4, "Shop",      "shop",      Color3.fromRGB(85, 226, 112))

-- ── Sidebar collapse tab ──────────────────────────────────────────────────────
local SIDEBAR_OPEN_POS = UDim2.new(0, 20, 1, -20)
local SIDEBAR_CLOSED_POS = UDim2.new(0, -208, 1, -20)
local TAB_OPEN_POS = UDim2.new(0, 218, 1, -158)
local TAB_CLOSED_POS = UDim2.new(0, 10, 1, -158)
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

-- ── Rare pull screen effect ───────────────────────────────────────────────────
-- Talisman  = tier 1 : coloured flash only
-- Maestro   = tier 2 : flash + rarity burst label + cinematic black bars
-- Immortal / POTY = tier 3 : flash + burst + bars + brief camera shake
-- Returns the number of seconds the caller should wait before showing the card.
local REVEAL_TIERS = {
	["Talisman"]           = 1,
	["Maestro"]            = 2,
	["Immortal"]           = 3,
	["Player of the Year"] = 3,
}

local function playRevealEffect(rarity)
	local tier = REVEAL_TIERS[rarity] or 0
	if tier == 0 then
		return 0
	end

	local style = Utils.GetRarityStyle(rarity)
	local flashColor = style.glow or style.primary

	-- Flash overlay ────────────────────────────────────────────────────────────
	local startTransp = tier == 1 and 0.52 or (tier == 2 and 0.32 or 0.16)
	local flash = make("Frame", {
		AnchorPoint    = Vector2.new(0.5, 0.5),
		Position       = UDim2.fromScale(0.5, 0.5),
		Size           = UDim2.fromScale(1, 1),
		BackgroundColor3 = flashColor,
		BackgroundTransparency = startTransp,
		BorderSizePixel = 0,
		ZIndex         = 188,
	}, screenGui)

	local holdTime = tier == 1 and 0.12 or (tier == 2 and 0.22 or 0.32)
	local fadeTime = tier == 1 and 0.32 or (tier == 2 and 0.52 or 0.68)
	task.delay(holdTime, function()
		if flash.Parent then
			TweenService:Create(flash, TweenInfo.new(fadeTime), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(fadeTime + 0.05, function()
				if flash.Parent then flash:Destroy() end
			end)
		end
	end)

	-- Rarity name burst (tier 2+) ──────────────────────────────────────────────
	if tier >= 2 then
		local burstLabel = make("TextLabel", {
			AnchorPoint    = Vector2.new(0.5, 0.5),
			Position       = UDim2.fromScale(0.5, 0.43),
			Size           = UDim2.fromOffset(480, 72),
			BackgroundTransparency = 1,
			Text           = string.upper(style.label or rarity),
			TextColor3     = style.primary,
			TextTransparency = 0,
			TextScaled     = true,
			Font           = Enum.Font.GothamBlack,
			ZIndex         = 193,
		}, screenGui)
		addStroke(burstLabel, Color3.fromRGB(0, 0, 0), 2, 0.05)

		local burstScale = make("UIScale", { Scale = 0.25 }, burstLabel)
		TweenService:Create(
			burstScale,
			TweenInfo.new(0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
		-- Fade out after the pop-in settles
		TweenService:Create(
			burstLabel,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0.55),
			{ TextTransparency = 1 }
		):Play()
		task.delay(1.05, function()
			if burstLabel.Parent then burstLabel:Destroy() end
		end)
	end

	-- Cinematic black bars (tier 2+) ───────────────────────────────────────────
	local topBar, bottomBar
	if tier >= 2 then
		local BAR_H = 76
		topBar = make("Frame", {
			AnchorPoint    = Vector2.new(0, 0),
			Position       = UDim2.new(0, 0, 0, -BAR_H),   -- starts off-screen top
			Size           = UDim2.new(1, 0, 0, BAR_H),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex         = 186,
		}, screenGui)
		bottomBar = make("Frame", {
			AnchorPoint    = Vector2.new(0, 1),
			Position       = UDim2.new(0, 0, 1, BAR_H),    -- starts off-screen bottom
			Size           = UDim2.new(1, 0, 0, BAR_H),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex         = 186,
		}, screenGui)

		local slideIn = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(topBar,    slideIn, { Position = UDim2.new(0, 0, 0, 0)       }):Play()
		TweenService:Create(bottomBar, slideIn, { Position = UDim2.new(0, 0, 1, -BAR_H)  }):Play()

		-- Slide bars back out once the card reveal is done (~2.4–2.8 s from now)
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

	-- Camera shake (tier 3 only) ───────────────────────────────────────────────
	if tier >= 3 then
		task.spawn(function()
			local camera = Workspace.CurrentCamera
			if not camera then return end
			local prevType = camera.CameraType
			local prevCF   = camera.CFrame
			camera.CameraType = Enum.CameraType.Scriptable
			local frames = 10
			for i = 1, frames do
				task.wait(0.032)
				if not camera or not camera.Parent then break end
				local intensity = 0.28 * (1 - (i - 1) / frames)
				camera.CFrame = prevCF * CFrame.new(
					(math.random() - 0.5) * 2 * intensity,
					(math.random() - 0.5) * 2 * intensity,
					0
				)
			end
			if camera and camera.Parent then
				camera.CFrame   = prevCF
				camera.CameraType = prevType
			end
		end)
	end

	-- Pre-delay before the card panel pops in
	return tier == 1 and 0.12 or (tier == 2 and 0.30 or 0.38)
end

-- ── Compact card reveal ───────────────────────────────────────────────────────
-- Appears near the pack, shows player info briefly, then flies toward the
-- destination slot (or inventory corner).  No full-screen overlay — keeps the
-- world visible while the card pops.  Auto-destroys in ~2 s.
local function showCardReveal(payload)
	local card = payload.card
	if not card then
		return
	end

	-- Play dramatic screen effect for Talisman+ cards; yields briefly so the
	-- flash and bars land before the card panel pops in on top of them.
	local revealPreDelay = playRevealEffect(card.rarity)
	if revealPreDelay > 0 then
		task.wait(revealPreDelay)
	end

	local style = Utils.GetRarityStyle(card.rarity)
	local rarityColor = style.primary
	local secondaryColor = style.secondary or rarityColor
	local darkColor = style.dark or Color3.fromRGB(10, 5, 2)
	local trimColor = style.trim or rarityColor
	local textColor = style.text or Color3.fromRGB(255, 255, 255)
	local income = payload.coinsPerSecond or 0
	local toInventory = payload.storedInInventory == true

	-- ── Card panel (compact: 180 × 256 px) ───────────────────────────
	local CARD_W, CARD_H = 180, 256
	-- Keep the reveal itself predictably visible. The fly-off still targets the
	-- actual 3D slot/inventory destination, which is the bit that matters.
	local revealStart = UDim2.new(0.5, 0, 0.46, 0)

	local cardPanel = make("Frame", {
		Name = "CardReveal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = revealStart,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = darkColor,
		ZIndex = 200,
	}, screenGui)
	addCorner(cardPanel, 16)
	addStroke(cardPanel, trimColor, 3)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12)),
			ColorSequenceKeypoint.new(0.48, secondaryColor),
			ColorSequenceKeypoint.new(1, darkColor),
		}),
		Rotation = 158,
	}, cardPanel)

	-- UIScale at 0.05 → 1 for the bounce pop-in
	local cardScale = make("UIScale", { Scale = 0.05 }, cardPanel)

	local rarityBand = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(142, 24),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 202,
	}, cardPanel)
	addCorner(rarityBand, 12)
	addStroke(rarityBand, trimColor, 1.2, 0.28)

	local rarityLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = string.upper(style.label or card.rarity or "CARD"),
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamBlack,
		ZIndex = 203,
	}, rarityBand)
	addStroke(rarityLabel, Color3.fromRGB(6, 3, 1), 1, 0.35)

	local positionBadge = make("Frame", {
		Position = UDim2.fromOffset(14, 47),
		Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = Color3.fromRGB(6, 8, 13),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 202,
	}, cardPanel)
	addCorner(positionBadge, 8)
	addStroke(positionBadge, trimColor, 1, 0.35)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = card.position or "--",
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamBlack,
		ZIndex = 203,
	}, positionBadge)

	-- Nation (top-right)
	make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 51),
		Size = UDim2.fromOffset(92, 16),
		Text = card.nation or "Unknown",
		TextColor3 = textColor,
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 202,
	}, cardPanel)

	-- Divider
	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 78),
		Size = UDim2.new(0.84, 0, 0, 1.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 202,
	}, cardPanel)

	-- Monogram circle
	local monogram = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 86),
		Size = UDim2.fromOffset(84, 84),
		BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(0, 0, 0), 0.55),
		BackgroundTransparency = 0.42,
		ZIndex = 201,
	}, cardPanel)
	addCorner(monogram, 42)
	addStroke(monogram, Color3.fromRGB(255, 255, 255), 1.2, 0.62)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = string.upper(string.sub(card.name, 1, 1)),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.30,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		ZIndex = 202,
	}, monogram)

	-- Player name
	local nameLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 170),
		Size = UDim2.new(0.90, 0, 0, 46),
		Text = string.upper(card.name),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 202,
	}, cardPanel)
	make("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 22 }, nameLabel)
	addStroke(nameLabel, Color3.fromRGB(6, 3, 1), 1.2, 0.20)

	-- Destination + income pill (bottom of card)
	local destStr = toInventory
		and ("→ Inventory  ·  +" .. Utils.FormatNumber(income) .. "/s")
		or ("→ Slot " .. tostring(payload.slotIndex) .. "  ·  +" .. Utils.FormatNumber(income) .. "/s")
	local pillBg = toInventory and Color3.fromRGB(40, 50, 80) or Color3.fromRGB(22, 74, 38)
	local pillAccent = toInventory and Color3.fromRGB(110, 130, 210) or Color3.fromRGB(74, 185, 98)

	local pill = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(158, 26),
		BackgroundColor3 = pillBg,
		ZIndex = 202,
	}, cardPanel)
	addCorner(pill, 13)
	addStroke(pill, pillAccent, 1.2, 0.28)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = destStr,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		ZIndex = 203,
	}, pill)

	-- ── Pop-in animation ─────────────────────────────────────────────
	task.wait(0.04)
	TweenService:Create(cardScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	-- ── Fly-off after 1.4 s ──────────────────────────────────────────
	-- Card shrinks and slides toward the destination corner so it feels like
	-- it "drops into" the slot or inventory rather than just disappearing.
	task.delay(1.4, function()
		if not cardPanel.Parent then
			return
		end

		local flyTarget = toInventory
			and getGuiCenterTarget(inventoryButton, UDim2.new(0.16, 0, 0.72, 0))
			or getWorldScreenTarget(payload.slotWorldPosition, UDim2.new(0.5, 0, 0.72, 0))

		TweenService:Create(
			cardPanel,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = flyTarget }
		):Play()
		TweenService:Create(
			cardScale,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 0 }
		):Play()

		task.delay(0.35, function()
			if cardPanel.Parent then
				cardPanel:Destroy()
			end
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
