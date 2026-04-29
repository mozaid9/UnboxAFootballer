local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
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

local sortBar = make("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 26),
	Position = UDim2.new(0, 12, 0, 76),
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
	Size = UDim2.new(1, -24, 1, -124),
	Position = UDim2.new(0, 12, 0, 112),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, panel)

local layout = make("UIGridLayout", {
	CellSize = UDim2.fromOffset(132, 176),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scrolling)

local currentMode = "inventory"
local currentSortMode = "fans"
local targetSlotIndex = nil
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

local function formatShortNumber(value)
	return Utils.FormatNumber(math.max(0, tonumber(value) or 0))
end

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
		Size = UDim2.fromOffset(76, 24),
		BackgroundColor3 = Constants.UI.PanelAlt,
		Text = label,
		TextColor3 = Constants.UI.Text,
		TextScaled = false,
		TextSize = 10,
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
		"%d stored • %d card types • best %s fans/s • stack value %s",
		totalCards,
		#inventory,
		formatShortNumber(bestFans),
		formatShortNumber(totalValue)
	)
end

function refreshInventory()
	refreshToken += 1
	local myToken = refreshToken

	local inventory = mergeInventoryRows(GetInventoryFn:InvokeServer())

	-- If another refresh started while we were yielded on InvokeServer, bail so we
	-- don't append a stale render on top of (or before) the newer one.
	if myToken ~= refreshToken then
		return
	end

	clearEntries()
	local isSlotPicker = currentMode == "slotPicker"

	if isSlotPicker then
		title.Text = "Choose Player"
		statusLabel.Text = "Best earners are shown first for display slot " .. tostring(targetSlotIndex) .. "."
	else
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
		addStroke(tile, trimColor, 1.5, 0.35)

		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.08)),
				ColorSequenceKeypoint.new(0.52, secondaryColor),
				ColorSequenceKeypoint.new(1, darkColor),
			}),
			Rotation = 145,
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
			Size = UDim2.fromOffset(42, 22),
			BackgroundColor3 = Color3.fromRGB(7, 9, 14),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
		}, tile)
		addCorner(quantityBadge, 8)
		addStroke(quantityBadge, trimColor, 1, 0.45)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "x" .. tostring(card.quantity),
			TextColor3 = textColor,
			TextScaled = false,
			TextSize = 12,
			Font = Enum.Font.GothamBlack,
		}, quantityBadge)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 32),
			Size = UDim2.new(1, -20, 0, 18),
			Text = string.upper(tostring(card.position or "--")) .. "  •  " .. tostring(card.nation or "Unknown"),
			TextColor3 = Constants.UI.Muted,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, tile)

		local nameLabel = make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 52),
			Size = UDim2.new(1, -20, 0, 46),
			Text = card.name,
			TextColor3 = textColor,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
		}, tile)
		make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 24 }, nameLabel)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 101),
			Size = UDim2.new(1, -20, 0, 24),
			Text = formatShortNumber(incomePerSecond) .. " fans/s",
			TextColor3 = rarityColor,
			TextScaled = false,
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 123),
			Size = UDim2.new(1, -20, 0, 14),
			Text = isSlotPicker and "Ready for display" or ("Sell +" .. formatShortNumber(card.sellValue or 0) .. " each"),
			TextColor3 = Constants.UI.Muted,
			TextScaled = false,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, tile)

		local actionButton
		local sellAllButton
		if isSlotPicker then
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(0.84, 0, 0, 30),
				BackgroundColor3 = Color3.fromRGB(74, 185, 98),
				Text = "Place",
				TextColor3 = Constants.UI.Text,
				TextScaled = false,
				TextSize = 15,
				Font = Enum.Font.GothamBlack,
			}, tile)
		else
			local hasDuplicates = (card.quantity or 1) > 1
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0.08, 0, 1, -8),
				Size = hasDuplicates and UDim2.new(0.40, 0, 0, 30) or UDim2.new(0.84, 0, 0, 30),
				BackgroundColor3 = Constants.UI.Danger,
				Text = hasDuplicates and ("Sell 1\n+" .. formatShortNumber(card.sellValue or 0)) or ("Sell +" .. formatShortNumber(card.sellValue or 0)),
				TextColor3 = Constants.UI.Text,
				TextScaled = false,
				TextSize = hasDuplicates and 11 or 14,
				TextWrapped = true,
				Font = Enum.Font.GothamBlack,
			}, tile)
			if hasDuplicates then
				sellAllButton = make("TextButton", {
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(0.92, 0, 1, -8),
					Size = UDim2.new(0.40, 0, 0, 30),
					BackgroundColor3 = Color3.fromRGB(128, 45, 40),
					Text = "All\n+" .. formatShortNumber((card.sellValue or 0) * (card.quantity or 1)),
					TextColor3 = Constants.UI.Text,
					TextScaled = false,
					TextSize = 11,
					TextWrapped = true,
					Font = Enum.Font.GothamBlack,
				}, tile)
				addCorner(sellAllButton, 10)
			end
		end
		addCorner(actionButton, 10)

		actionButton.MouseButton1Click:Connect(function()
			if isSubmitting then
				return
			end

			isSubmitting = true

			if isSlotPicker then
				actionButton.Text = "Placing..."

				local result = PlaceInventoryCardInSlotFn:InvokeServer(targetSlotIndex, card.id)
				isSubmitting = false

				if result and result.success then
					closePanel()
					return
				end

				statusOverride = (result and result.error) or "Could not place that player."
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
