local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetUpgradesFn = Remotes:WaitForChild("GetUpgrades")
local PurchaseUpgradeFn = Remotes:WaitForChild("PurchaseUpgrade")
local UpdateCoinsEvent = Remotes:WaitForChild("UpdateCoins")

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

local existingGui = playerGui:FindFirstChild("UpgradesUI")
if existingGui then
	existingGui:Destroy()
end

local screenGui = make("ScreenGui", {
	Name = "UpgradesUI",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

local panel = make("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.92, 0, 0.85, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = UI.Panel,
}, screenGui)
addCorner(panel, 18)
addStroke(panel, UI.Gold, 2, 0.35)

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(320, 360)
panelSize.MaxSize = Vector2.new(560, 460)
panelSize.Parent = panel

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 38),
	Position = UDim2.new(0, 16, 0, 12),
	Text = "Club Upgrades",
	TextColor3 = UI.Text,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local coinsHeader = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 220, 0, 24),
	Position = UDim2.new(1, -236, 0, 18),
	Text = "0 coins",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Right,
}, panel)

local closeButton = make("TextButton", {
	Size = UDim2.fromOffset(32, 32),
	Position = UDim2.new(1, -44, 0, 46),
	BackgroundColor3 = UI.PanelAlt,
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
}, panel)
addCorner(closeButton, 8)

local scrolling = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -24, 1, -92),
	Position = UDim2.new(0, 12, 0, 82),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, panel)

local layout = make("UIListLayout", {
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scrolling)

local function formatValue(entry)
	if entry.key == "PackSpawnRate" then
		return string.format("%.1f%s", entry.currentValue, entry.valueSuffix)
	elseif entry.key == "PadLuck" then
		return string.format("+%d%%%s", entry.currentValue, "")
	elseif entry.key == "MoveSpeed" then
		return string.format("%d studs/s", entry.currentValue)
	end
	return string.format("%s%s", tostring(entry.currentValue), entry.valueSuffix or "")
end

local function formatNextValue(entry)
	if entry.key == "PackSpawnRate" then
		return string.format("%.1fs", entry.nextValue)
	elseif entry.key == "PadLuck" then
		return string.format("+%d%%", entry.nextValue)
	elseif entry.key == "MoveSpeed" then
		return string.format("%d studs/s", entry.nextValue)
	end
	return tostring(entry.nextValue)
end

local rows = {}

local function clearRows()
	for _, row in ipairs(rows) do
		if row.frame.Parent then
			row.frame:Destroy()
		end
	end
	rows = {}
end

local function buildRow(entry, index)
	local row = make("Frame", {
		LayoutOrder = index,
		BackgroundColor3 = UI.PanelAlt,
		Size = UDim2.new(1, -12, 0, 96),
	}, scrolling)
	addCorner(row, 14)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(0.6, 0, 0, 22),
		Text = entry.displayName,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 32),
		Size = UDim2.new(0.6, 0, 0, 18),
		Text = entry.description,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, row)

	local levelText
	if entry.maxed then
		levelText = string.format("Lv %d / %d MAX", entry.level, entry.maxLevel)
	else
		levelText = string.format("Lv %d / %d  •  Now: %s  →  Next: %s", entry.level, entry.maxLevel, formatValue(entry), formatNextValue(entry))
	end

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 58),
		Size = UDim2.new(0.65, 0, 0, 30),
		Text = levelText,
		TextColor3 = UI.Gold,
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local buyButton = make("TextButton", {
		Size = UDim2.fromOffset(148, 56),
		Position = UDim2.new(1, -160, 0.5, -28),
		BackgroundColor3 = entry.maxed and UI.PanelAlt or UI.Gold,
		Text = entry.maxed and "MAX" or ("Buy  •  " .. Utils.FormatNumber(entry.nextCost)),
		TextColor3 = entry.maxed and UI.Muted or Color3.fromRGB(18, 12, 6),
		TextScaled = false,
		TextSize = 16,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = not entry.maxed,
		Active = not entry.maxed,
	}, row)
	addCorner(buyButton, 12)

	table.insert(rows, { frame = row, entry = entry, buyButton = buyButton })
	return row, buyButton
end

local refreshing = false
local pendingPayload

local function renderPayload(payload)
	if not payload then
		return
	end
	pendingPayload = payload
	coinsHeader.Text = Utils.FormatNumber(payload.coins or 0) .. " coins"
	clearRows()

	for index, entry in ipairs(payload.upgrades or {}) do
		local _, buyButton = buildRow(entry, index)
		local key = entry.key
		local cost = entry.nextCost
		buyButton.MouseButton1Click:Connect(function()
			if entry.maxed or refreshing then
				return
			end
			if cost and (payload.coins or 0) < cost then
				buyButton.Text = "Not enough coins"
				task.delay(0.8, function()
					if buyButton.Parent then
						buyButton.Text = "Buy  •  " .. Utils.FormatNumber(cost)
					end
				end)
				return
			end

			refreshing = true
			buyButton.Text = "..."
			local result = PurchaseUpgradeFn:InvokeServer(key)
			refreshing = false
			if result and result.success then
				renderPayload(result)
			else
				buyButton.Text = (result and result.error) or "Failed"
				task.delay(1.2, function()
					if buyButton.Parent then
						buyButton.Text = "Buy  •  " .. Utils.FormatNumber(cost)
					end
				end)
			end
		end)
	end

	task.defer(function()
		scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

local function refresh()
	local payload = GetUpgradesFn:InvokeServer()
	renderPayload(payload)
end

local function setVisible(visible)
	panel.Visible = visible
	if visible then
		refresh()
	end
end

closeButton.MouseButton1Click:Connect(function()
	setVisible(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		setVisible(false)
	end
end)

toggleEvent.Event:Connect(function()
	setVisible(not panel.Visible)
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins)
	if pendingPayload then
		pendingPayload.coins = coins
	end
	coinsHeader.Text = Utils.FormatNumber(coins or 0) .. " coins"
end)
