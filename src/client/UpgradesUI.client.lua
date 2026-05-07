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
	Text = "0 Fans",
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
	if entry.key == "PitchforkDamage" then
		return string.format("%.2g× per swing", entry.currentValue)
	elseif entry.key == "PackSpawnLuck" then
		return string.format("%d%% better packs", entry.currentValue)
	elseif entry.key == "CardPullLuck" then
		return string.format("%d%% pull luck", entry.currentValue)
	end
	return string.format("%s%s", tostring(entry.currentValue), entry.valueSuffix or "")
end

local function formatNextValue(entry)
	if entry.key == "PitchforkDamage" then
		return string.format("%.2g×", entry.nextValue)
	elseif entry.key == "PackSpawnLuck" or entry.key == "CardPullLuck" then
		return string.format("%d%%", entry.nextValue)
	end
	return tostring(entry.nextValue)
end

local UPGRADE_META = {
	PitchforkDamage = {
		tag = "PACK SPEED",
		accent = Color3.fromRGB(255, 213, 74),
		dark = Color3.fromRGB(32, 27, 12),
	},
	PackSpawnLuck = {
		tag = "PACK QUALITY",
		accent = Color3.fromRGB(255, 184, 74),
		dark = Color3.fromRGB(31, 22, 12),
	},
	CardPullLuck = {
		tag = "CARD QUALITY",
		accent = Color3.fromRGB(91, 190, 255),
		dark = Color3.fromRGB(12, 26, 36),
	},
	MoveSpeed = {
		tag = "MOVEMENT",
		accent = Color3.fromRGB(106, 230, 128),
		dark = Color3.fromRGB(13, 31, 19),
	},
}

local function getUpgradeMeta(entry)
	return UPGRADE_META[entry.key] or {
		tag = "UPGRADE",
		accent = UI.Gold,
		dark = Color3.fromRGB(28, 24, 12),
	}
end

local function getBuyButtonText(entry)
	if entry.maxed then
		return "MAX"
	end
	return "Buy  •  " .. Utils.FormatNumber(entry.nextCost or 0)
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

local function buildRow(entry, index, availableFans)
	local meta = getUpgradeMeta(entry)
	local progress = entry.maxLevel > 0 and math.clamp((entry.level or 0) / entry.maxLevel, 0, 1) or 0
	local affordable = not entry.maxed and (availableFans or 0) >= (entry.nextCost or math.huge)
	local buttonColor = entry.maxed and UI.PanelAlt or (affordable and UI.Gold or Color3.fromRGB(72, 61, 32))
	local buttonTextColor = entry.maxed and UI.Muted or (affordable and Color3.fromRGB(18, 12, 6) or Color3.fromRGB(218, 201, 142))

	local row = make("Frame", {
		LayoutOrder = index,
		BackgroundColor3 = Color3.fromRGB(12, 17, 31),
		Size = UDim2.new(1, -10, 0, 82),
	}, scrolling)
	addCorner(row, 12)
	addStroke(row, meta.accent, 1.1, affordable and 0.72 or 0.86)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 23, 41)),
			ColorSequenceKeypoint.new(1, meta.dark),
		}),
		Rotation = 0,
	}, row)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(0.38, 0, 0, 20),
		Text = entry.displayName,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 16,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local tag = make("TextLabel", {
		BackgroundColor3 = meta.accent,
		BackgroundTransparency = 0.08,
		Position = UDim2.new(0.40, 0, 0, 9),
		Size = UDim2.fromOffset(104, 18),
		Text = meta.tag,
		TextColor3 = Color3.fromRGB(12, 9, 3),
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, row)
	addCorner(tag, 8)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 30),
		Size = UDim2.new(0.62, -14, 0, 18),
		Text = entry.description,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, row)

	local progressBack = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(6, 9, 18),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 14, 0, 57),
		Size = UDim2.new(0.22, 0, 0, 7),
	}, row)
	addCorner(progressBack, 5)

	local progressFill = make("Frame", {
		BackgroundColor3 = meta.accent,
		BorderSizePixel = 0,
		Size = UDim2.new(progress, 0, 1, 0),
	}, progressBack)
	addCorner(progressFill, 5)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.25, 0, 0, 50),
		Size = UDim2.new(0.40, 0, 0, 22),
		Text = entry.maxed
			and string.format("Lv %d/%d  •  MAX", entry.level, entry.maxLevel)
			or string.format("Lv %d/%d  •  %s  →  %s", entry.level, entry.maxLevel, formatValue(entry), formatNextValue(entry)),
		TextColor3 = UI.Gold,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local buyButton = make("TextButton", {
		Size = UDim2.fromOffset(132, 44),
		Position = UDim2.new(1, -146, 0.5, -22),
		BackgroundColor3 = buttonColor,
		Text = getBuyButtonText(entry),
		TextColor3 = buttonTextColor,
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = not entry.maxed,
		Active = not entry.maxed,
	}, row)
	addCorner(buyButton, 11)
	addStroke(buyButton, affordable and Color3.fromRGB(255, 246, 178) or meta.accent, 1, affordable and 0.48 or 0.74)

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
	coinsHeader.Text = Utils.FormatNumber(payload.coins or 0) .. " Fans"
	clearRows()

	for index, entry in ipairs(payload.upgrades or {}) do
		local _, buyButton = buildRow(entry, index, payload.coins or 0)
		local key = entry.key
		local cost = entry.nextCost
		buyButton.MouseButton1Click:Connect(function()
			if entry.maxed or refreshing then
				return
			end
			if cost and (payload.coins or 0) < cost then
				buyButton.Text = "Not enough Fans"
				task.delay(0.8, function()
					if buyButton.Parent then
						buyButton.Text = getBuyButtonText(entry)
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
						buyButton.Text = getBuyButtonText(entry)
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
	coinsHeader.Text = Utils.FormatNumber(coins or 0) .. " Fans"
end)
