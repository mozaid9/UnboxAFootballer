local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local CardData = require(Shared:WaitForChild("CardData"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetInventoryFn = Remotes:WaitForChild("GetInventory")
local SellCardFn = Remotes:WaitForChild("SellCard")
local SellAllCardsFn = Remotes:WaitForChild("SellAllCards")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")
local PromptPackShopEvent = Remotes:WaitForChild("PromptPackShop")
local OpenSlotPickerEvent = Remotes:WaitForChild("OpenSlotPicker")
local PlaceInventoryCardInSlotFn = Remotes:WaitForChild("PlaceInventoryCardInSlot")

local function make(className, props, parent)
	props = props or {}
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local existingGui = playerGui:FindFirstChild("InventoryUI")
if existingGui then
	existingGui:Destroy()
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
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
	Name = "InventoryUI",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

local toggle = make("TextButton", {
	Visible = false,
	AnchorPoint = Vector2.new(0, 1),
	Size = UDim2.fromOffset(176, 38),
	Position = UDim2.new(0, 24, 1, -116),
	BackgroundColor3 = Constants.UI.Panel,
	Text = "Inventory",
	TextColor3 = Constants.UI.Text,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
}, screenGui)
addCorner(toggle, 12)

local panel = make("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.92, 0, 0.85, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Constants.UI.Panel,
}, screenGui)
addCorner(panel, 18)

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(320, 360)
panelSize.MaxSize = Vector2.new(660, 520)
panelSize.Parent = panel

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -72, 0, 36),
	Position = UDim2.new(0, 12, 0, 10),
	Text = "Stored Players",
	TextColor3 = Constants.UI.Text,
	TextScaled = false,
	TextSize = 28,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(36, 36),
	Position = UDim2.new(1, -12, 0, 10),
	BackgroundColor3 = Constants.UI.PanelAlt,
	Text = "X",
	TextColor3 = Constants.UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
}, panel)
addCorner(closeButton, 10)

local statusLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 24),
	Position = UDim2.new(0, 12, 0, 48),
	Text = "",
	TextColor3 = Constants.UI.Muted,
	TextScaled = false,
	TextSize = 14,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold,
}, panel)

local bulkBar = make("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 26),
	Position = UDim2.new(0, 12, 0, 78),
}, panel)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, bulkBar)

local function createBulkButton(order, text, backgroundColor)
	local button = make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(136, 24),
		BackgroundColor3 = backgroundColor,
		Text = text,
		TextColor3 = Color3.fromRGB(18, 12, 6),
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamBlack,
	}, bulkBar)
	addCorner(button, 8)
	addStroke(button, Color3.fromRGB(255, 236, 150), 1, 0.45)
	return button
end

local sellGoldButton = createBulkButton(1, "Sell All Gold", Constants.UI.Gold)
local sellWeakButton = createBulkButton(2, "Sell <100/s", Color3.fromRGB(255, 190, 78))

local sortBar = make("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 26),
	Position = UDim2.new(0, 12, 0, 110),
}, panel)

local sortLayout = make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, sortBar)
_ = sortLayout

local scrolling = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -24, 1, -158),
	Position = UDim2.new(0, 12, 0, 146),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, panel)

local layout = make("UIGridLayout", {
	CellSize = UDim2.fromOffset(132, 188),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scrolling)

local currentMode = "inventory"
local currentSortMode = "fans"
local targetSlotIndex = nil
local lastInventory = {}
local isSubmitting = false
local statusOverride = nil
local refreshToken = 0
local refreshInventory

local RARITY_RANK = {
	["Gold"] = 1,
	["Rare Gold"] = 2,
	["Premium Gold"] = 3,
	["Talisman"] = 4,
	["Maestro"] = 5,
	["Immortal"] = 6,
	["Player of the Year"] = 7,
}

local TOTAL_CARD_VARIANTS = #(CardData.Pool or {})

local function formatShortNumber(value)
	return Utils.FormatNumber(math.max(0, tonumber(value) or 0))
end

local function addButtonHover(button, normalColor, hoverColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = hoverColor,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = normalColor,
		}):Play()
	end)
end

addButtonHover(sellGoldButton, Constants.UI.Gold, Color3.fromRGB(255, 235, 88))
addButtonHover(sellWeakButton, Color3.fromRGB(255, 190, 78), Color3.fromRGB(255, 213, 110))

local sortButtons = {}

local function setSortMode(mode)
	currentSortMode = mode
	for _, entry in ipairs(sortButtons) do
		entry.button.BackgroundColor3 = entry.mode == currentSortMode and Constants.UI.Gold or Constants.UI.PanelAlt
		entry.button.TextColor3 = entry.mode == currentSortMode and Color3.fromRGB(18, 12, 6) or Constants.UI.Text
	end
	if panel.Visible then
		refreshInventory()
	end
end

local function createSortButton(order, mode, label)
	local button = make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(54, 24),
		BackgroundColor3 = Constants.UI.PanelAlt,
		Text = label,
		TextColor3 = Constants.UI.Text,
		TextScaled = false,
		TextSize = 9,
		Font = Enum.Font.GothamBlack,
	}, sortBar)
	addCorner(button, 8)
	table.insert(sortButtons, { mode = mode, button = button })
	button.MouseButton1Click:Connect(function()
		setSortMode(mode)
	end)
	return button
end

createSortButton(1, "fans", "Best")
createSortButton(2, "rarity", "Rarity")
createSortButton(3, "newest", "Newest")
createSortButton(4, "quantity", "Stacks")
createSortButton(5, "value", "Value")
setSortMode("fans")

local function clearEntries()
	for _, child in ipairs(scrolling:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function closePanel()
	panel.Visible = false
	currentMode = "inventory"
	targetSlotIndex = nil
	statusOverride = nil
	statusLabel.Text = ""
end

local function openInventoryPanel()
	currentMode = "inventory"
	targetSlotIndex = nil
	statusOverride = nil
	panel.Visible = true
	refreshInventory()
end

local function mergeInventoryRows(inventory)
	local byId = {}
	local merged = {}

	for _, card in ipairs(inventory or {}) do
		local cardId = tonumber(card.id)
		if cardId then
			local existing = byId[cardId]
			if existing then
				existing.quantity += tonumber(card.quantity) or 0
			else
				local entry = {
					id = cardId,
					name = card.name,
					nation = card.nation,
					position = card.position,
					rarity = card.rarity,
					quantity = tonumber(card.quantity) or 1,
					fansPerSecond = card.fansPerSecond or 0,
					sellValue = card.sellValue,
				}
				byId[cardId] = entry
				table.insert(merged, entry)
			end
		end
	end

	table.sort(merged, function(a, b)
		if currentSortMode == "rarity" then
			local ar = RARITY_RANK[a.rarity] or 0
			local br = RARITY_RANK[b.rarity] or 0
			if ar ~= br then
				return ar > br
			end
		elseif currentSortMode == "newest" then
			if a.id ~= b.id then
				return a.id > b.id
			end
		elseif currentSortMode == "quantity" then
			if a.quantity ~= b.quantity then
				return a.quantity > b.quantity
			end
		elseif currentSortMode == "value" then
			local aValue = (a.sellValue or 0) * (a.quantity or 1)
			local bValue = (b.sellValue or 0) * (b.quantity or 1)
			if aValue ~= bValue then
				return aValue > bValue
			end
		end

		if a.fansPerSecond == b.fansPerSecond then
			return a.name < b.name
		end
		return a.fansPerSecond > b.fansPerSecond
	end)

	return merged
end

local function getInventorySummary(inventory)
	if #inventory == 0 then
		return "Open packs to build your club."
	end

	local totalCards = 0
	local totalValue = 0
	local bestFans = 0
	for _, card in ipairs(inventory) do
		local quantity = card.quantity or 1
		totalCards += quantity
		totalValue += (card.sellValue or 0) * quantity
		bestFans = math.max(bestFans, card.fansPerSecond or 0)
	end

	return string.format(
		"Stored: %d    Unique: %d/%d    Best: %s fans/s    Total Value: %s",
		totalCards,
		#inventory,
		TOTAL_CARD_VARIANTS,
		formatShortNumber(bestFans),
		formatShortNumber(totalValue)
	)
end

local function sellMatchingCards(predicate, emptyMessage, successMessage)
	if isSubmitting then
		return
	end
	if currentMode ~= "inventory" then
		return
	end

	local cardIds = {}
	for _, card in ipairs(lastInventory) do
		if predicate(card) then
			for _ = 1, (card.quantity or 1) do
				table.insert(cardIds, card.id)
			end
		end
	end

	if #cardIds == 0 then
		statusOverride = emptyMessage
		refreshInventory()
		return
	end

	isSubmitting = true
	statusOverride = "Selling..."
	local result = SellAllCardsFn:InvokeServer(cardIds)
	isSubmitting = false

	if result and result.success then
		statusOverride = successMessage .. " +" .. formatShortNumber(result.coinsEarned or 0) .. " Fans."
	else
		statusOverride = (result and result.error) or "Could not sell those players."
	end
	refreshInventory()
end

sellGoldButton.MouseButton1Click:Connect(function()
	sellMatchingCards(function(card)
		return card.rarity == "Gold"
	end, "No stored Gold cards to sell.", "Gold cards sold for")
end)

sellWeakButton.MouseButton1Click:Connect(function()
	sellMatchingCards(function(card)
		return (card.fansPerSecond or 0) < 100
	end, "No stored players below 100 fans/s.", "Low earners sold for")
end)

function refreshInventory()
	refreshToken += 1
	local myToken = refreshToken

	local inventory = mergeInventoryRows(GetInventoryFn:InvokeServer())
	lastInventory = inventory

	-- If another refresh started while we were yielded on InvokeServer, bail so we
	-- don't append a stale render on top of (or before) the newer one.
	if myToken ~= refreshToken then
		return
	end

	clearEntries()
	local isSlotPicker = currentMode == "slotPicker"

	if isSlotPicker then
		bulkBar.Visible = false
		title.Text = "Choose Player"
		statusLabel.Text = "Best earners are shown first for display slot " .. tostring(targetSlotIndex) .. "."
	else
		bulkBar.Visible = true
		title.Text = "Stored Players"
		statusLabel.Text = getInventorySummary(inventory)
	end
	if statusOverride then
		statusLabel.Text = statusOverride
		statusOverride = nil
	end

	if #inventory == 0 then
		local emptyState = make("Frame", {
			BackgroundColor3 = Constants.UI.PanelAlt,
		}, scrolling)
		addCorner(emptyState, 14)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -16, 1, -16),
			Position = UDim2.fromOffset(8, 8),
			Text = "No stored players yet",
			TextColor3 = Constants.UI.Muted,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
		}, emptyState)
	end

	for index, card in ipairs(inventory) do
		local style = Utils.GetRarityStyle(card.rarity)
		local rarityColor = style.primary
		local secondaryColor = style.secondary or rarityColor
		local darkColor = style.dark or Constants.UI.PanelAlt
		local trimColor = style.trim or rarityColor
		local textColor = style.text or Constants.UI.Text
		local incomePerSecond = card.fansPerSecond or 0

		local tile = make("Frame", {
			LayoutOrder = index,
			BackgroundColor3 = darkColor,
		}, scrolling)
		addCorner(tile, 14)
		local tileStroke = addStroke(tile, trimColor, 2, 0.28)
		local tileScale = make("UIScale", { Scale = 1 }, tile)

		tile.MouseEnter:Connect(function()
			TweenService:Create(tileScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1.025 }):Play()
			TweenService:Create(tileStroke, TweenInfo.new(0.12), { Transparency = 0.06 }):Play()
		end)
		tile.MouseLeave:Connect(function()
			TweenService:Create(tileScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
			TweenService:Create(tileStroke, TweenInfo.new(0.12), { Transparency = 0.28 }):Play()
		end)

		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, darkColor),
				ColorSequenceKeypoint.new(0.48, secondaryColor),
				ColorSequenceKeypoint.new(1, darkColor),
			}),
			Rotation = 35,
		}, tile)

		local rarityLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.new(1, -62, 0, 18),
			Text = string.upper(style.label or card.rarity or "CARD"),
			TextColor3 = textColor,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, tile)
		make("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 10 }, rarityLabel)
		addStroke(rarityLabel, Color3.fromRGB(0, 0, 0), 1, 0.38)

		local quantityBadge = make("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 8),
			Size = UDim2.fromOffset(44, 24),
			BackgroundColor3 = trimColor,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}, tile)
		addCorner(quantityBadge, 10)
		addStroke(quantityBadge, Color3.fromRGB(255, 246, 190), 1, 0.45)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "x" .. tostring(card.quantity),
			TextColor3 = Color3.fromRGB(18, 12, 6),
			TextScaled = false,
			TextSize = 13,
			Font = Enum.Font.GothamBlack,
		}, quantityBadge)

		local nameLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 36),
			Size = UDim2.new(1, -20, 0, 42),
			Text = card.name,
			TextColor3 = textColor,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
		}, tile)
		make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 24 }, nameLabel)

		local fansPill = make("Frame", {
			BackgroundColor3 = Color3.fromRGB(6, 8, 13),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(10, 82),
			Size = UDim2.new(1, -20, 0, 34),
		}, tile)
		addCorner(fansPill, 10)
		addStroke(fansPill, style.glow or trimColor, 1.5, 0.08)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = formatShortNumber(incomePerSecond) .. " fans/s",
			TextColor3 = style.glow or Color3.fromRGB(255, 225, 88),
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0.45,
			TextScaled = false,
			TextSize = 20,
			Font = Enum.Font.GothamBlack,
		}, fansPill)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 120),
			Size = UDim2.new(1, -20, 0, 16),
			Text = string.upper(tostring(card.position or "--")) .. "  •  " .. tostring(card.nation or "Unknown"),
			TextColor3 = Constants.UI.Muted,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, tile)

		local hasDuplicates = (card.quantity or 1) > 1
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 136),
			Size = UDim2.new(1, -20, 0, 14),
			Text = isSlotPicker and "Select for display" or (hasDuplicates and ("+" .. formatShortNumber(card.sellValue or 0) .. " each") or ""),
			TextColor3 = Constants.UI.Muted,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, tile)

		local actionButton
		local sellAllButton
		if isSlotPicker then
			local selectColor = Color3.fromRGB(74, 185, 98)
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(0.84, 0, 0, 28),
				BackgroundColor3 = selectColor,
				Text = "Select",
				TextColor3 = Constants.UI.Text,
				TextScaled = false,
				TextSize = 15,
				Font = Enum.Font.GothamBlack,
			}, tile)
			addButtonHover(actionButton, selectColor, Color3.fromRGB(92, 210, 118))
		else
			local sellOneColor = Constants.UI.Danger
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0.08, 0, 1, -8),
				Size = hasDuplicates and UDim2.new(0.40, 0, 0, 28) or UDim2.new(0.84, 0, 0, 28),
				BackgroundColor3 = sellOneColor,
				Text = hasDuplicates and "Sell 1" or ("Sell +" .. formatShortNumber(card.sellValue or 0)),
				TextColor3 = Constants.UI.Text,
				TextScaled = false,
				TextSize = 14,
				Font = Enum.Font.GothamBlack,
			}, tile)
			addButtonHover(actionButton, sellOneColor, Color3.fromRGB(210, 92, 68))
			if hasDuplicates then
				local sellAllColor = Color3.fromRGB(128, 45, 40)
				sellAllButton = make("TextButton", {
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(0.92, 0, 1, -8),
					Size = UDim2.new(0.40, 0, 0, 28),
					BackgroundColor3 = sellAllColor,
					Text = "Sell All",
					TextColor3 = Constants.UI.Text,
					TextScaled = false,
					TextSize = 13,
					Font = Enum.Font.GothamBlack,
				}, tile)
				addCorner(sellAllButton, 10)
				addButtonHover(sellAllButton, sellAllColor, Color3.fromRGB(154, 56, 50))
			end
		end
		addCorner(actionButton, 10)

		actionButton.MouseButton1Click:Connect(function()
			if isSubmitting then
				return
			end

			isSubmitting = true

			if isSlotPicker then
				actionButton.Text = "Selecting..."

				local result = PlaceInventoryCardInSlotFn:InvokeServer(targetSlotIndex, card.id)
				isSubmitting = false

				if result and result.success then
					closePanel()
					return
				end

				statusOverride = (result and result.error) or "Could not select that player."
				refreshInventory()
				return
			end

			actionButton.Text = "Selling..."
			local result = SellCardFn:InvokeServer(card.id)
			isSubmitting = false

			if result and result.success then
				statusOverride = card.name .. " sold for +" .. tostring(result.coinsEarned or card.sellValue) .. " Fans."
				refreshInventory()
				return
			end

			statusOverride = (result and result.error) or "Could not sell that player."
			refreshInventory()
		end)

		if sellAllButton then
			sellAllButton.MouseButton1Click:Connect(function()
				if isSubmitting then
					return
				end

				isSubmitting = true
				sellAllButton.Text = "Selling..."
				local cardIds = {}
				for _ = 1, (card.quantity or 1) do
					table.insert(cardIds, card.id)
				end
				local result = SellAllCardsFn:InvokeServer(cardIds)
				isSubmitting = false

				if result and result.success then
					statusOverride = card.name .. " stack sold for +" .. tostring(result.coinsEarned or 0) .. " Fans."
					refreshInventory()
					return
				end

				statusOverride = (result and result.error) or "Could not sell that stack."
				refreshInventory()
			end)
		end
	end

	task.defer(function()
		scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

toggle.MouseButton1Click:Connect(function()
	if panel.Visible and currentMode == "inventory" then
		closePanel()
	else
		openInventoryPanel()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)

toggleEvent.Event:Connect(function()
	if panel.Visible and currentMode == "inventory" then
		closePanel()
	else
		openInventoryPanel()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		closePanel()
	end
end)

local function refreshIfVisible()
	if panel.Visible then
		refreshInventory()
	end
end

PackOpenedEvent.OnClientEvent:Connect(refreshIfVisible)
PromptPackShopEvent.OnClientEvent:Connect(refreshIfVisible)

OpenSlotPickerEvent.OnClientEvent:Connect(function(payload)
	currentMode = "slotPicker"
	targetSlotIndex = payload and payload.slotIndex
	statusOverride = nil
	panel.Visible = true
	refreshInventory()
end)
