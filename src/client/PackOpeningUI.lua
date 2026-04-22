local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local PackConfig = require(Shared:WaitForChild("PackConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local OpenPackFn = Remotes:WaitForChild("OpenPack")
local SellCardFn = Remotes:WaitForChild("SellCard")
local SellAllCardsFn = Remotes:WaitForChild("SellAllCards")
local UpdateCoinsEvent = Remotes:WaitForChild("UpdateCoins")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")
local PackOpenFailedEvent = Remotes:WaitForChild("PackOpenFailed")
local PromptPackShopEvent = Remotes:WaitForChild("PromptPackShop")

local UI = Constants.UI

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
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
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local topBar = make("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 120),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
}, screenGui)

local coinPill = make("Frame", {
	Size = UDim2.fromOffset(178, 44),
	Position = UDim2.new(1, -18, 0, 58),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = UI.Panel,
}, topBar)
addCorner(coinPill, 14)
addStroke(coinPill, UI.Gold, 2, 0.15)

local coinGradient = make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 24, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
	}),
	Rotation = 90,
}, coinPill)

local coinIcon = make("TextLabel", {
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.new(0, 8, 0.5, -14),
	BackgroundColor3 = Color3.fromRGB(35, 30, 10),
	Text = "C",
	TextColor3 = UI.Gold,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, coinPill)
addCorner(coinIcon, 9)

local coinTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 44, 0, 4),
	Size = UDim2.new(1, -50, 0, 12),
	Text = "Coins",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local coinsLabel = make("TextLabel", {
	Name = "CoinsLabel",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 44, 0, 15),
	Size = UDim2.new(1, -50, 0, 20),
	Text = "0",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local openShopButton = make("TextButton", {
	Size = UDim2.fromOffset(142, 44),
	Position = UDim2.new(1, -208, 0, 58),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = UI.Gold,
	Text = "Pack Shop",
	TextColor3 = Color3.fromRGB(20, 14, 8),
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, topBar)
addCorner(openShopButton, 14)

local hintLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0.46, 0, 0, 22),
	Position = UDim2.new(0.5, 0, 0, 108),
	AnchorPoint = Vector2.new(0.5, 0),
	Text = "Walk to a pack stand and press E to open packs.",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
}, topBar)

local shopScreen = make("Frame", {
	Name = "ShopScreen",
	Visible = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = UI.Background,
	BackgroundTransparency = 0.08,
}, screenGui)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(7, 10, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 12, 28)),
	}),
	Rotation = 140,
}, shopScreen)

local shopPanel = make("Frame", {
	Size = UDim2.new(0.86, 0, 0.68, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = UI.Panel,
}, shopScreen)
addCorner(shopPanel, 24)
addStroke(shopPanel, UI.Gold, 2, 0.6)

local shopTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 0, 18),
	Size = UDim2.new(0.5, 0, 0, 34),
	Text = "Choose A Pack",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, shopPanel)

local shopSubTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 0, 54),
	Size = UDim2.new(0.55, 0, 0, 18),
	Text = "Server-rolled odds. Higher rebirth tiers boost luck.",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, shopPanel)

local closeShopButton = make("TextButton", {
	Size = UDim2.fromOffset(46, 46),
	Position = UDim2.new(1, -24, 0, 24),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = Color3.fromRGB(42, 28, 28),
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, shopPanel)
addCorner(closeShopButton, 14)

local shopStatus = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 28, 1, -40),
	Size = UDim2.new(1, -56, 0, 20),
	Text = "",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, shopPanel)

local packRow = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.04, 0, 0.18, 0),
	Size = UDim2.new(0.92, 0, 0.62, 0),
}, shopPanel)

local packLayout = make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 26),
}, packRow)

local revealScreen = make("Frame", {
	Name = "RevealScreen",
	Visible = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = UI.Background,
}, screenGui)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 12, 22)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 17, 28)),
	}),
	Rotation = 120,
}, revealScreen)

local revealTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0, 26),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.6, 0, 0, 42),
	Text = "Pack Reveal",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, revealScreen)

local revealSubTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0, 66),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.7, 0, 0, 18),
	Text = "Cards flip one by one. Rare Gold pulls hit brighter.",
	TextColor3 = UI.Muted,
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
}, revealScreen)

local cardContainer = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0.48, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.94, 0, 0.48, 0),
}, revealScreen)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 18),
}, cardContainer)

local actionRow = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 1, -86),
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(420, 54),
}, revealScreen)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 18),
}, actionRow)

local storeAllButton = make("TextButton", {
	Visible = false,
	Size = UDim2.fromOffset(190, 52),
	BackgroundColor3 = UI.Success,
	Text = "Store All",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, actionRow)
addCorner(storeAllButton, 16)

local sellAllButton = make("TextButton", {
	Visible = false,
	Size = UDim2.fromOffset(190, 52),
	BackgroundColor3 = UI.Danger,
	Text = "Quick Sell All",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, actionRow)
addCorner(sellAllButton, 16)

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

local currentCards = {}
local soldIndexes = {}
local isRevealing = false
local packButtons = {}

local function setCoinsDisplay(coins)
	coinsLabel.Text = Utils.FormatNumber(coins)
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

local function clearCards()
	for _, child in ipairs(cardContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	table.clear(currentCards)
	table.clear(soldIndexes)
end

local function buildPackButton(packDef)
	local frame = make("Frame", {
		BackgroundColor3 = UI.PanelAlt,
		Size = UDim2.fromOffset(250, 330),
	}, packRow)
	addCorner(frame, 22)
	addStroke(frame, packDef.color, 2, 0.4)

	local shine = make("Frame", {
		BackgroundColor3 = packDef.color,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Position = UDim2.new(0.57, 0, 0.06, 0),
		Rotation = -18,
		Size = UDim2.new(0.28, 0, 0.52, 0),
	}, frame)

	local packArt = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(196, 156, 40),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.39, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(104, 168),
	}, frame)
	addCorner(packArt, 8)
	addStroke(packArt, Color3.fromRGB(35, 28, 8), 3, 0)

	local packHighlight = make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 246, 188)),
			ColorSequenceKeypoint.new(0.4, packDef.color),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 90, 16)),
		}),
		Rotation = 20,
	}, packArt)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.06, 0),
		Size = UDim2.new(0.36, 0, 0.18, 0),
		Text = tostring(packDef.displayRating),
		TextColor3 = Color3.fromRGB(24, 20, 8),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, packArt)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.68, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.86, 0, 0.18, 0),
		Text = packDef.displayName,
		TextColor3 = Color3.fromRGB(50, 38, 12),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, packArt)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.08, 0),
		Size = UDim2.new(0.84, 0, 0.12, 0),
		Text = packDef.displayName,
		TextColor3 = UI.Text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, frame)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.74, 0),
		Size = UDim2.new(0.84, 0, 0.1, 0),
		Text = packDef.description,
		TextWrapped = true,
		TextColor3 = UI.Muted,
		TextScaled = true,
		Font = Enum.Font.GothamMedium,
	}, frame)

	local button = make("TextButton", {
		BackgroundColor3 = packDef.color,
		Size = UDim2.new(0.84, 0, 0, 44),
		Position = UDim2.new(0.08, 0, 1, -58),
		Text = Utils.FormatNumber(packDef.cost) .. " Coins",
		TextColor3 = Color3.fromRGB(20, 14, 8),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, frame)
	addCorner(button, 14)

	packButtons[packDef.id] = button
	return button
end

for _, packDef in ipairs(PackConfig.ShopOrder) do
	buildPackButton(packDef)
end

local function buildCard(cardData, cardIndex)
	local outer = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(15, 19, 30),
		Size = UDim2.fromOffset(156, 244),
		ClipsDescendants = true,
	}, cardContainer)
	addCorner(outer, 18)

	local border = addStroke(outer, UI.Gold, 2, 0.45)
	local accent = Utils.GetRarityColor(cardData.rarity)

	local back = make("Frame", {
		Name = "Back",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(22, 28, 42),
	}, outer)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 32, 48)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
		}),
		Rotation = 90,
	}, back)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "?",
		TextColor3 = UI.Gold,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, back)

	local front = make("Frame", {
		Name = "Front",
		Visible = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(70, 54, 14),
	}, outer)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 244, 186)),
			ColorSequenceKeypoint.new(0.4, accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(111, 83, 15)),
		}),
		Rotation = 22,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.05, 0),
		Size = UDim2.new(0.28, 0, 0.16, 0),
		Text = tostring(cardData.rating),
		TextColor3 = Color3.fromRGB(20, 15, 7),
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.18, 0),
		Size = UDim2.new(0.24, 0, 0.08, 0),
		Text = cardData.position,
		TextColor3 = Color3.fromRGB(46, 36, 12),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.12, 0, 0.54, 0),
		Size = UDim2.new(0.76, 0, 0.14, 0),
		Text = cardData.name,
		TextColor3 = Color3.fromRGB(28, 21, 9),
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.12, 0, 0.72, 0),
		Size = UDim2.new(0.76, 0, 0.08, 0),
		Text = cardData.nation,
		TextColor3 = Color3.fromRGB(52, 42, 14),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, front)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.08, 0, 0.83, 0),
		Size = UDim2.new(0.84, 0, 0.08, 0),
		Text = cardData.rarity,
		TextColor3 = Color3.fromRGB(56, 43, 12),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, front)

	local sellButton = make("TextButton", {
		Visible = false,
		BackgroundColor3 = UI.Danger,
		Size = UDim2.new(0.82, 0, 0, 34),
		Position = UDim2.new(0.09, 0, 1, -44),
		Text = "Sell " .. Utils.FormatNumber(cardData.sellValue),
		TextColor3 = UI.Text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
	}, outer)
	addCorner(sellButton, 12)

	local function flip()
		local collapse = TweenService:Create(outer, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(12, 244),
		})
		collapse:Play()
		collapse.Completed:Wait()
		back.Visible = false
		front.Visible = true
		local expand = TweenService:Create(outer, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(156, 244),
		})
		expand:Play()
		TweenService:Create(border, TweenInfo.new(0.25), {
			Color = accent,
			Transparency = 0,
			Thickness = cardData.rarity == "Rare Gold" and 3 or 2,
		}):Play()
		sellButton.Visible = true
		if cardData.rarity == "Rare Gold" then
			showToast("Rare pull: " .. cardData.name .. " (" .. cardData.rating .. ")", accent)
		end
	end

	sellButton.MouseButton1Click:Connect(function()
		if soldIndexes[cardIndex] then
			return
		end
		local response = SellCardFn:InvokeServer(cardData.id)
		if response and response.success then
			soldIndexes[cardIndex] = true
			sellButton.Visible = false
			outer.BackgroundTransparency = 0.35
			setCoinsDisplay(response.newCoins)
		end
	end)

	return flip
end

local function refreshStatus()
	local data = GetPlayerDataFn:InvokeServer()
	if not data then
		return
	end

	setCoinsDisplay(data.coins)
	if data.canClaimFreePack then
		shopStatus.Text = "Free pack is ready."
		shopStatus.TextColor3 = UI.Success
	else
		shopStatus.Text = "Free pack cooldown: " .. Utils.FormatCountdown(data.freePackRemaining or 0)
		shopStatus.TextColor3 = UI.Muted
	end
end

local function runReveal(payload)
	isRevealing = true
	clearCards()
	revealTitle.Text = payload.packName
	revealSubTitle.Text = "Sound hooks: FlipSFX on each card, RarePullSFX for Rare Gold cards."
	revealScreen.Visible = true
	storeAllButton.Visible = false
	sellAllButton.Visible = false

	for _, card in ipairs(payload.cards) do
		table.insert(currentCards, card)
	end

	local flips = {}
	for index, card in ipairs(currentCards) do
		flips[index] = buildCard(card, index)
	end

	task.spawn(function()
		for index, flip in ipairs(flips) do
			task.wait(0.45)
			flip()
		end
		task.wait(0.35)
		storeAllButton.Visible = true
		sellAllButton.Visible = true
		isRevealing = false
	end)
end

local function openPack(packId)
	if isRevealing then
		return
	end

	local response = OpenPackFn:InvokeServer(packId)
	if response and response.success then
		shopScreen.Visible = false
		setCoinsDisplay(response.newCoins)
		runReveal(response)
	else
		shopStatus.Text = response and response.error or "Could not open pack."
		shopStatus.TextColor3 = UI.Danger
	end
end

for packId, button in pairs(packButtons) do
	button.MouseButton1Click:Connect(function()
		openPack(packId)
	end)
end

openShopButton.MouseButton1Click:Connect(function()
	refreshStatus()
	shopScreen.Visible = true
end)

closeShopButton.MouseButton1Click:Connect(function()
	shopScreen.Visible = false
end)

storeAllButton.MouseButton1Click:Connect(function()
	if isRevealing then
		return
	end
	revealScreen.Visible = false
	clearCards()
end)

sellAllButton.MouseButton1Click:Connect(function()
	if isRevealing then
		return
	end

	local toSell = {}
	for index, card in ipairs(currentCards) do
		if not soldIndexes[index] then
			table.insert(toSell, card.id)
		end
	end

	local response = SellAllCardsFn:InvokeServer(toSell)
	if response and response.success then
		setCoinsDisplay(response.newCoins)
	end

	revealScreen.Visible = false
	clearCards()
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins)
	setCoinsDisplay(coins)
end)

PackOpenedEvent.OnClientEvent:Connect(function(payload)
	if payload and payload.success then
		setCoinsDisplay(payload.newCoins)
		runReveal(payload)
	end
end)

PackOpenFailedEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end
	showToast(payload.error or "Pack could not be opened.", UI.Danger)
	shopStatus.Text = payload.error or "Pack could not be opened."
	shopStatus.TextColor3 = UI.Danger
end)

PromptPackShopEvent.OnClientEvent:Connect(function(payload)
	if payload and payload.message then
		hintLabel.Text = payload.message
	end
end)

openShopButton.MouseEnter:Connect(function()
	TweenService:Create(openShopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(255, 229, 70),
	}):Play()
end)

openShopButton.MouseLeave:Connect(function()
	TweenService:Create(openShopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = UI.Gold,
	}):Play()
end)

task.spawn(function()
	task.wait(1)
	refreshStatus()
end)
