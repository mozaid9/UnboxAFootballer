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

local screenGui = make("ScreenGui", {
	Name = "InventoryUI",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggle = make("TextButton", {
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
panelSize.MaxSize = Vector2.new(620, 500)
panelSize.Parent = panel

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -72, 0, 36),
	Position = UDim2.new(0, 12, 0, 10),
	Text = "Club Inventory",
	TextColor3 = Constants.UI.Text,
	TextScaled = true,
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
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold,
}, panel)

local scrolling = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -24, 1, -94),
	Position = UDim2.new(0, 12, 0, 82),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, panel)

local layout = make("UIGridLayout", {
	CellSize = UDim2.fromOffset(126, 190),
	CellPadding = UDim2.fromOffset(12, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scrolling)

local currentMode = "inventory"
local targetSlotIndex = nil
local isSubmitting = false
local statusOverride = nil
local refreshToken = 0

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
					rating = card.rating,
					rarity = card.rarity,
					quantity = tonumber(card.quantity) or 1,
					sellValue = card.sellValue,
				}
				byId[cardId] = entry
				table.insert(merged, entry)
			end
		end
	end

	table.sort(merged, function(a, b)
		if a.rating == b.rating then
			return a.name < b.name
		end
		return a.rating > b.rating
	end)

	return merged
end

local function refreshInventory()
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
		statusLabel.Text = "Pick a stored player for display slot " .. tostring(targetSlotIndex) .. "."
	else
		title.Text = "Club Inventory"
		statusLabel.Text = #inventory > 0 and "Stored players earn money when placed on green display slots." or "Stored players will appear here when your displays are full."
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
		local tile = make("Frame", {
			LayoutOrder = index,
			BackgroundColor3 = Constants.UI.PanelAlt,
		}, scrolling)
		addCorner(tile, 14)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 8),
			Size = UDim2.new(0, 30, 0, 22),
			Text = tostring(card.rating),
			TextColor3 = Utils.GetRarityColor(card.rarity),
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.44, 0),
			Size = UDim2.new(0.84, 0, 0.18, 0),
			Text = card.name,
			TextColor3 = Constants.UI.Text,
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBlack,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.68, 0),
			Size = UDim2.new(0.84, 0, 0.12, 0),
			Text = card.position .. " • " .. card.nation,
			TextColor3 = Constants.UI.Muted,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, tile)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.08, 0, 0.73, 0),
			Size = UDim2.new(0.84, 0, 0.07, 0),
			Text = "Stored x" .. tostring(card.quantity) .. " • +" .. tostring(Utils.GetPassiveIncome(card.rating)) .. "/s",
			TextColor3 = Utils.GetRarityColor(card.rarity),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, tile)

		local actionButton
		if isSlotPicker then
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(0.82, 0, 0, 30),
				BackgroundColor3 = Color3.fromRGB(74, 185, 98),
				Text = card.quantity > 1 and ("Place x" .. tostring(card.quantity)) or "Place",
				TextColor3 = Constants.UI.Text,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
			}, tile)
		else
			actionButton = make("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(0.82, 0, 0, 30),
				BackgroundColor3 = Constants.UI.Danger,
				Text = "Sell 1 +" .. tostring(card.sellValue),
				TextColor3 = Constants.UI.Text,
				TextScaled = true,
				Font = Enum.Font.GothamBlack,
			}, tile)
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
				statusOverride = card.name .. " sold for +" .. tostring(result.coinsEarned or card.sellValue) .. " coins."
				refreshInventory()
				return
			end

			statusOverride = (result and result.error) or "Could not sell that player."
			refreshInventory()
		end)
	end

	task.defer(function()
		scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

toggle.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		currentMode = "inventory"
		targetSlotIndex = nil
		statusOverride = nil
		refreshInventory()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)

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
