local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local CardData = require(Shared:WaitForChild("CardData"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetCollectionFn = Remotes:WaitForChild("GetCollection")
local ClaimCollectionRewardFn = Remotes:WaitForChild("ClaimCollectionReward")
local MarkCollectionCardViewedFn = Remotes:WaitForChild("MarkCollectionCardViewed")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")

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

local existingGui = playerGui:FindFirstChild("CollectionUI")
if existingGui then
	existingGui:Destroy()
end

local screenGui = make("ScreenGui", {
	Name = "CollectionUI",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 11,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

local panel = make("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.94, 0, 0.88, 0),
	BackgroundColor3 = UI.Panel,
}, screenGui)
addCorner(panel, 16)
addStroke(panel, UI.Gold, 1.5, 0.44)

local panelSize = make("UISizeConstraint", {
	MinSize = Vector2.new(360, 390),
	MaxSize = Vector2.new(980, 600),
}, panel)
_ = panelSize

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 10),
	Size = UDim2.new(1, -72, 0, 36),
	Text = "Collection Book",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 28,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = UI.PanelAlt,
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
}, panel)
addCorner(closeButton, 10)

local summaryLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 50),
	Size = UDim2.new(1, -32, 0, 22),
	Text = "",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 14,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local completionBarBack = make("Frame", {
	BackgroundColor3 = UI.PanelAlt,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(16, 76),
	Size = UDim2.new(1, -32, 0, 8),
}, panel)
addCorner(completionBarBack, 6)
addStroke(completionBarBack, UI.Gold, 1, 0.78)

local completionBarFill = make("Frame", {
	BackgroundColor3 = UI.Gold,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(0, 1),
}, completionBarBack)
addCorner(completionBarFill, 6)

local filterBar = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 96),
	Size = UDim2.new(1, -32, 0, 28),
}, panel)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, filterBar)

local searchBox = make("TextBox", {
	Position = UDim2.fromOffset(16, 132),
	Size = UDim2.new(1, -32, 0, 32),
	BackgroundColor3 = UI.PanelAlt,
	PlaceholderText = "Search player...",
	Text = "",
	TextColor3 = UI.Text,
	PlaceholderColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
}, panel)
addCorner(searchBox, 10)
addStroke(searchBox, UI.Gold, 1, 0.72)
make("UIPadding", {
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, searchBox)

local gridFrame = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(16, 174),
	Size = UDim2.new(1, -244, 1, -190),
	CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 6,
}, panel)

local gridLayout = make("UIGridLayout", {
	CellSize = UDim2.fromOffset(124, 148),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, gridFrame)

local rewardsFrame = make("Frame", {
	BackgroundColor3 = UI.PanelAlt,
	Position = UDim2.new(1, -212, 0, 174),
	Size = UDim2.new(0, 196, 1, -190),
}, panel)
addCorner(rewardsFrame, 12)
addStroke(rewardsFrame, UI.Gold, 1, 0.58)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(10, 8),
	Size = UDim2.new(1, -20, 0, 22),
	Text = "Rewards",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, rewardsFrame)

local rewardsList = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(10, 38),
	Size = UDim2.new(1, -20, 1, -48),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 4,
}, rewardsFrame)

local rewardsLayout = make("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, rewardsList)

local gridTopFade = make("Frame", {
	BackgroundColor3 = UI.Panel,
	BackgroundTransparency = 0.24,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(16, 174),
	Size = UDim2.new(1, -244, 0, 18),
	ZIndex = 5,
}, panel)
make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Rotation = 90,
}, gridTopFade)

local gridBottomFade = make("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	BackgroundColor3 = UI.Panel,
	BackgroundTransparency = 0.18,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.new(1, -244, 0, 24),
	ZIndex = 5,
}, panel)
make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	}),
	Rotation = 90,
}, gridBottomFade)

local function updateGridFades()
	local maxScroll = math.max(0, gridFrame.AbsoluteCanvasSize.Y - gridFrame.AbsoluteSize.Y)
	gridTopFade.Visible = maxScroll > 2 and gridFrame.CanvasPosition.Y > 2
	gridBottomFade.Visible = maxScroll > 2 and gridFrame.CanvasPosition.Y < maxScroll - 2
end

gridFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateGridFades)
gridFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateGridFades)
gridFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateGridFades)

local rarityFilters = {
	{ label = "All", mode = "All" },
	{ label = "Gold", mode = "Gold" },
	{ label = "Rare", mode = "Rare Gold" },
	{ label = "Premium", mode = "Premium Gold" },
	{ label = "Talisman", mode = "Talisman" },
	{ label = "Maestro", mode = "Maestro" },
	{ label = "Immortal", mode = "Immortal" },
	{ label = "POTY", mode = "Player of the Year" },
}

local currentFilter = "All"
local currentPayload
local filterButtons = {}
local refreshCollection

local RARITY_RANK = {
	["Gold"] = 1,
	["Rare Gold"] = 2,
	["Premium Gold"] = 3,
	["Talisman"] = 4,
	["Maestro"] = 5,
	["Immortal"] = 6,
	["Player of the Year"] = 7,
}

local LOCKED_STYLES = {
	["Gold"] = {
		hint = "Found in Gold Packs",
		bgA = Color3.fromRGB(38, 26, 10),
		bgB = Color3.fromRGB(86, 57, 14),
		trim = Color3.fromRGB(150, 116, 42),
		text = Color3.fromRGB(178, 156, 108),
	},
	["Rare Gold"] = {
		hint = "Found in Rare Packs+",
		bgA = Color3.fromRGB(42, 14, 6),
		bgB = Color3.fromRGB(96, 38, 8),
		trim = Color3.fromRGB(178, 114, 34),
		text = Color3.fromRGB(204, 146, 80),
	},
	["Premium Gold"] = {
		hint = "Premium-tier player",
		bgA = Color3.fromRGB(3, 3, 5),
		bgB = Color3.fromRGB(30, 24, 10),
		trim = Color3.fromRGB(196, 166, 72),
		text = Color3.fromRGB(222, 196, 116),
	},
	["Talisman"] = {
		hint = "Star player",
		bgA = Color3.fromRGB(34, 4, 8),
		bgB = Color3.fromRGB(84, 12, 14),
		trim = Color3.fromRGB(184, 62, 48),
		text = Color3.fromRGB(218, 128, 116),
	},
	["Maestro"] = {
		hint = "Legendary playmaker",
		bgA = Color3.fromRGB(18, 8, 42),
		bgB = Color3.fromRGB(56, 22, 104),
		trim = Color3.fromRGB(150, 96, 222),
		text = Color3.fromRGB(196, 158, 236),
	},
	["Immortal"] = {
		hint = "Extremely rare",
		bgA = Color3.fromRGB(20, 28, 42),
		bgB = Color3.fromRGB(72, 102, 130),
		trim = Color3.fromRGB(178, 218, 235),
		text = Color3.fromRGB(198, 228, 238),
	},
	["Player of the Year"] = {
		hint = "Seasonal special",
		bgA = Color3.fromRGB(3, 3, 4),
		bgB = Color3.fromRGB(58, 44, 10),
		trim = Color3.fromRGB(220, 184, 64),
		text = Color3.fromRGB(228, 204, 112),
	},
}

local function getRarityHint(rarity)
	local lockedStyle = LOCKED_STYLES[rarity]
	if lockedStyle then
		return lockedStyle.hint
	end
	return "Open packs to unlock"
end

local function clearCards()
	for _, child in ipairs(gridFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function clearRewards()
	for _, child in ipairs(rewardsList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function setFilter(mode)
	currentFilter = mode
	for _, entry in ipairs(filterButtons) do
		local selected = entry.mode == currentFilter
		entry.button.BackgroundColor3 = selected and UI.Gold or UI.PanelAlt
		entry.button.TextColor3 = selected and Color3.fromRGB(18, 12, 6) or UI.Text
	end
	if panel.Visible then
		refreshCollection(false)
	end
end

local function createFilterButton(order, label, mode)
	local button = make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(label == "Premium" and 70 or 58, 24),
		BackgroundColor3 = UI.PanelAlt,
		Text = label,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 9,
		Font = Enum.Font.GothamBlack,
	}, filterBar)
	addCorner(button, 8)
	table.insert(filterButtons, { mode = mode, button = button })
	button.MouseButton1Click:Connect(function()
		setFilter(mode)
	end)
end

for index, entry in ipairs(rarityFilters) do
	createFilterButton(index, entry.label, entry.mode)
end

local function renderSummary(payload)
	local total = payload.totalCards or #CardData.Pool
	local unlocked = payload.unlockedCount or 0
	local completionRatio = total > 0 and math.clamp(unlocked / total, 0, 1) or 0
	local completion = math.floor(completionRatio * 100 + 0.5)
	summaryLabel.Text = string.format(
		"Progress: %d/%d cards | Completion: %d%% | Rewards claimed: %d/%d",
		unlocked,
		total,
		completion,
		payload.claimedRewardCount or 0,
		payload.totalRewardCount or 0
	)
	TweenService:Create(completionBarFill, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(completionRatio, 1),
	}):Play()
end

local function renderRewards(payload)
	clearRewards()

	for index, reward in ipairs(payload.rewards or {}) do
		local requiredCards = math.max(1, reward.requiredCards or 1)
		local progress = math.clamp(reward.progress or payload.unlockedCount or 0, 0, requiredCards)
		local progressRatio = progress / requiredCards
		local row = make("Frame", {
			LayoutOrder = index,
			BackgroundColor3 = UI.Panel,
			Size = UDim2.new(1, 0, 0, 74),
		}, rewardsList)
		addCorner(row, 10)
		addStroke(row, reward.canClaim and UI.Gold or UI.Muted, 1, reward.canClaim and 0.3 or 0.7)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.new(1, -16, 0, 16),
			Text = reward.label .. " -> " .. reward.reward,
			TextColor3 = UI.Text,
			TextScaled = false,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)

		local progressBack = make("Frame", {
			BackgroundColor3 = UI.PanelAlt,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 26),
			Size = UDim2.new(1, -16, 0, 10),
		}, row)
		addCorner(progressBack, 8)

		local progressFill = make("Frame", {
			BackgroundColor3 = reward.claimed and UI.Success or (reward.canClaim and UI.Gold or UI.Muted),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(progressRatio, 1),
		}, progressBack)
		addCorner(progressFill, 8)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 37),
			Size = UDim2.new(1, -16, 0, 12),
			Text = tostring(progress) .. "/" .. tostring(requiredCards) .. " cards",
			TextColor3 = UI.Muted,
			TextScaled = false,
			TextSize = 9,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)

		local stateText = reward.claimed and "CLAIMED" or (reward.canClaim and "CLAIM" or "LOCKED")
		local stateColor = reward.claimed and UI.Success or (reward.canClaim and UI.Gold or UI.Muted)
		local button = make("TextButton", {
			Position = UDim2.fromOffset(8, 50),
			Size = UDim2.new(1, -16, 0, 20),
			BackgroundColor3 = reward.canClaim and UI.Gold or UI.PanelAlt,
			Text = stateText,
			TextColor3 = reward.canClaim and Color3.fromRGB(18, 12, 6) or stateColor,
			TextScaled = false,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			AutoButtonColor = reward.canClaim,
		}, row)
		addCorner(button, 8)

		button.MouseButton1Click:Connect(function()
			if not reward.canClaim then
				return
			end
			button.Text = "CLAIMING..."
			local result = ClaimCollectionRewardFn:InvokeServer(reward.id)
			if result and result.success then
				currentPayload = result.collection
				refreshCollection(false)
			else
				summaryLabel.Text = (result and result.error) or "Could not claim reward."
			end
		end)
	end

	task.defer(function()
		rewardsList.CanvasSize = UDim2.new(0, 0, 0, rewardsLayout.AbsoluteContentSize.Y + 8)
	end)
end

local function makeCardTile(card, packedCount, index, payload)
	local unlocked = packedCount > 0
	local style = Utils.GetRarityStyle(card.rarity)
	local lockedStyle = LOCKED_STYLES[card.rarity] or LOCKED_STYLES.Gold
	local trim = style.trim or style.primary or UI.Gold
	local dark = style.dark or UI.PanelAlt
	local textColor = style.text or UI.Text
	local viewed = payload and payload.viewed or {}
	local isNew = unlocked and viewed[tostring(card.id)] ~= true
	local tileTrim = unlocked and trim or (lockedStyle.trim or UI.Muted)
	local tileText = unlocked and textColor or (lockedStyle.text or UI.Muted)

	local tile = make("Frame", {
		LayoutOrder = index,
		Active = true,
		BackgroundColor3 = unlocked and dark or (lockedStyle.bgA or Color3.fromRGB(10, 12, 20)),
	}, gridFrame)
	addCorner(tile, 12)
	local stroke = addStroke(tile, tileTrim, unlocked and 1.2 or 1, isNew and 0.12 or (unlocked and 0.34 or 0.62))

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, unlocked and (style.secondary or dark) or (lockedStyle.bgB or Color3.fromRGB(18, 21, 34))),
			ColorSequenceKeypoint.new(1, unlocked and dark or (lockedStyle.bgA or Color3.fromRGB(6, 8, 14))),
		}),
		Rotation = 35,
	}, tile)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 7),
		Size = UDim2.new(1, -72, 0, 14),
		Text = unlocked and string.upper(style.label or card.rarity) or string.upper(style.label or card.rarity),
		TextColor3 = tileText,
		TextScaled = false,
		TextSize = 8,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, tile)

	local statusPill = make("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 6),
		Size = UDim2.fromOffset(isNew and 34 or 54, 17),
		BackgroundColor3 = isNew and UI.Gold or (unlocked and Color3.fromRGB(26, 58, 38) or UI.PanelAlt),
	}, tile)
	addCorner(statusPill, 7)
	addStroke(statusPill, isNew and (style.glow or trim) or tileTrim, 1, isNew and 0.25 or 0.68)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = isNew and "NEW" or (unlocked and "Collected" or "Locked"),
		TextColor3 = isNew and Color3.fromRGB(18, 12, 6) or (unlocked and UI.Success or UI.Muted),
		TextScaled = false,
		TextSize = 8,
		Font = Enum.Font.GothamBlack,
	}, statusPill)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 31),
		Size = UDim2.new(1, -16, 0, 36),
		Text = unlocked and card.name or ("Mystery " .. (style.label or card.rarity)),
		TextColor3 = tileText,
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
	}, tile)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 72),
		Size = UDim2.new(1, -16, 0, 20),
		Text = unlocked and (Utils.FormatNumber(Utils.CalculateFansPerSecond(card)) .. " fans/s") or "???",
		TextColor3 = unlocked and (style.glow or trim) or tileText,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, tile)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 96),
		Size = UDim2.new(1, -16, 0, 14),
		Text = unlocked and (card.position .. " | " .. card.nation) or getRarityHint(card.rarity),
		TextColor3 = unlocked and UI.Muted or tileText,
		TextScaled = false,
		TextSize = 9,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, tile)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 116),
		Size = UDim2.new(1, -16, 0, 20),
		Text = unlocked and ("Packed " .. tostring(packedCount) .. "x") or "Keep opening packs",
		TextColor3 = unlocked and UI.Text or UI.Muted,
		TextScaled = false,
		TextSize = 10,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, tile)

	if isNew then
		TweenService:Create(stroke, TweenInfo.new(0.72, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Transparency = 0.04,
			Thickness = 1.8,
		}):Play()
	end

	tile.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			Transparency = unlocked and 0.08 or 0.34,
			Thickness = unlocked and 1.6 or 1.3,
		}):Play()
	end)

	tile.MouseLeave:Connect(function()
		if isNew then
			return
		end
		TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			Transparency = unlocked and 0.34 or 0.62,
			Thickness = unlocked and 1.2 or 1,
		}):Play()
	end)

	tile.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if unlocked then
			summaryLabel.Text = card.name .. " | " .. card.rarity .. " | Packed " .. tostring(packedCount) .. " times"
			if isNew then
				local result = MarkCollectionCardViewedFn:InvokeServer(card.id)
				if result and result.success and result.collection then
					currentPayload = result.collection
					refreshCollection(false)
				end
			end
		else
			summaryLabel.Text = (style.label or card.rarity) .. " | " .. getRarityHint(card.rarity)
		end
	end)
end

local function renderCards(payload)
	clearCards()

	local counts = payload.counts or {}
	local search = string.lower(searchBox.Text or "")
	local cards = {}

	for _, card in ipairs(CardData.Pool) do
		local matchesFilter = currentFilter == "All" or card.rarity == currentFilter
		local matchesSearch = search == ""
			or string.find(string.lower(card.name), search, 1, true)
			or string.find(string.lower(card.nation), search, 1, true)
		if matchesFilter and matchesSearch then
			table.insert(cards, card)
		end
	end

	table.sort(cards, function(a, b)
		local aUnlocked = (tonumber(counts[tostring(a.id)]) or 0) > 0
		local bUnlocked = (tonumber(counts[tostring(b.id)]) or 0) > 0
		if aUnlocked ~= bUnlocked then
			return aUnlocked
		end
		local ar = RARITY_RANK[a.rarity] or 0
		local br = RARITY_RANK[b.rarity] or 0
		if ar ~= br then
			return ar > br
		end
		return a.name < b.name
	end)

	for index, card in ipairs(cards) do
		makeCardTile(card, tonumber(counts[tostring(card.id)]) or 0, index, payload)
	end

	task.defer(function()
		gridFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 12)
		updateGridFades()
	end)
end

function refreshCollection(fetch)
	if fetch ~= false then
		currentPayload = GetCollectionFn:InvokeServer()
	end
	if not currentPayload then
		return
	end

	renderSummary(currentPayload)
	renderCards(currentPayload)
	renderRewards(currentPayload)
end

local function openPanel()
	panel.Visible = true
	refreshCollection(true)
end

local function closePanel()
	panel.Visible = false
end

closeButton.MouseButton1Click:Connect(closePanel)

toggleEvent.Event:Connect(function()
	if panel.Visible then
		closePanel()
	else
		openPanel()
	end
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if panel.Visible then
		refreshCollection(false)
	end
end)

PackOpenedEvent.OnClientEvent:Connect(function()
	if panel.Visible then
		refreshCollection(true)
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

setFilter("All")
