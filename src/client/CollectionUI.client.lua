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
local NationFlags = require(Shared:WaitForChild("NationFlags"))

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
	CellSize = UDim2.fromOffset(124, 134),
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

local rewardsTitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(10, 8),
	Size = UDim2.new(1, -20, 0, 20),
	Text = "Rewards",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, rewardsFrame)

local nextRewardCard = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(11, 16, 28),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(10, 34),
	Size = UDim2.new(1, -20, 0, 74),
}, rewardsFrame)
addCorner(nextRewardCard, 10)
addStroke(nextRewardCard, UI.Gold, 1, 0.54)

local nextRewardLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(8, 6),
	Size = UDim2.new(1, -16, 0, 18),
	Text = "Next reward",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 10,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, nextRewardCard)

local nextRewardValue = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(8, 24),
	Size = UDim2.new(1, -16, 0, 20),
	Text = "--",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, nextRewardCard)

local nextRewardProgress = make("Frame", {
	BackgroundColor3 = UI.PanelAlt,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(8, 48),
	Size = UDim2.new(1, -16, 0, 9),
}, nextRewardCard)
addCorner(nextRewardProgress, 8)

local nextRewardProgressFill = make("Frame", {
	BackgroundColor3 = UI.Gold,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(0, 1),
}, nextRewardProgress)
addCorner(nextRewardProgressFill, 8)

local nextRewardProgressText = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(8, 58),
	Size = UDim2.new(1, -16, 0, 12),
	Text = "",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 8,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, nextRewardCard)

local rewardsList = make("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(10, 118),
	Size = UDim2.new(1, -20, 1, -128),
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 4,
}, rewardsFrame)

local rewardsLayout = make("UIListLayout", {
	Padding = UDim.new(0, 11),
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
local newTileEntries = {}
local pendingViewedCards = {}

local RARITY_RANK = {
	["Gold"] = 1,
	["Rare Gold"] = 2,
	["Premium Gold"] = 3,
	["Talisman"] = 4,
	["Maestro"] = 5,
	["Immortal"] = 6,
	["Player of the Year"] = 7,
}

local COLLECTION_SKINS = {
	["Gold"] = {
		bgA = Color3.fromRGB(112, 68, 12),
		bgB = Color3.fromRGB(192, 124, 28),
		trim = Color3.fromRGB(255, 210, 78),
		text = Color3.fromRGB(255, 250, 226),
		glow = Color3.fromRGB(255, 220, 92),
	},
	["Rare Gold"] = {
		bgA = Color3.fromRGB(96, 22, 6),
		bgB = Color3.fromRGB(214, 58, 14),
		trim = Color3.fromRGB(255, 160, 46),
		text = Color3.fromRGB(255, 242, 222),
		glow = Color3.fromRGB(255, 112, 28),
	},
	["Premium Gold"] = {
		bgA = Color3.fromRGB(172, 108, 12),
		bgB = Color3.fromRGB(255, 204, 58),
		trim = Color3.fromRGB(255, 236, 116),
		text = Color3.fromRGB(36, 22, 4),
		glow = Color3.fromRGB(255, 234, 118),
	},
	["Talisman"] = {
		bgA = Color3.fromRGB(42, 10, 86),
		bgB = Color3.fromRGB(130, 44, 218),
		trim = Color3.fromRGB(202, 84, 255),
		text = Color3.fromRGB(248, 230, 255),
		glow = Color3.fromRGB(214, 116, 255),
	},
	["Maestro"] = {
		bgA = Color3.fromRGB(5, 22, 86),
		bgB = Color3.fromRGB(26, 86, 212),
		trim = Color3.fromRGB(255, 204, 70),
		text = Color3.fromRGB(238, 246, 255),
		glow = Color3.fromRGB(88, 154, 255),
	},
	["Immortal"] = {
		bgA = Color3.fromRGB(24, 118, 170),
		bgB = Color3.fromRGB(116, 218, 255),
		trim = Color3.fromRGB(220, 252, 255),
		text = Color3.fromRGB(245, 255, 255),
		glow = Color3.fromRGB(210, 248, 255),
	},
	["Player of the Year"] = {
		bgA = Color3.fromRGB(0, 0, 0),
		bgB = Color3.fromRGB(42, 32, 6),
		trim = Color3.fromRGB(255, 226, 74),
		text = Color3.fromRGB(255, 246, 210),
		glow = Color3.fromRGB(255, 226, 88),
	},
}

local LOCKED_STYLES = {
	["Gold"] = {
		hints = { "Found in Gold Packs", "Starter album card", "Common pack find", "Early collection piece" },
		bgA = Color3.fromRGB(38, 26, 10),
		bgB = Color3.fromRGB(86, 57, 14),
		trim = Color3.fromRGB(150, 116, 42),
		text = Color3.fromRGB(178, 156, 108),
	},
	["Rare Gold"] = {
		hints = { "Found in Rare Packs+", "Better pack find", "Uncommon pull", "Rising tier" },
		bgA = Color3.fromRGB(42, 14, 6),
		bgB = Color3.fromRGB(96, 38, 8),
		trim = Color3.fromRGB(178, 114, 34),
		text = Color3.fromRGB(204, 146, 80),
	},
	["Premium Gold"] = {
		hints = { "Premium-tier player", "Strong pack pull", "Mid-game target", "High-value find" },
		bgA = Color3.fromRGB(60, 38, 6),
		bgB = Color3.fromRGB(116, 74, 12),
		trim = Color3.fromRGB(210, 176, 78),
		text = Color3.fromRGB(232, 204, 124),
	},
	["Talisman"] = {
		hints = { "Star player", "Club leader", "Rare headline pull", "Main man" },
		bgA = Color3.fromRGB(22, 6, 48),
		bgB = Color3.fromRGB(58, 20, 108),
		trim = Color3.fromRGB(150, 74, 210),
		text = Color3.fromRGB(200, 152, 236),
	},
	["Maestro"] = {
		hints = { "Legendary playmaker", "Elite technician", "Rare creator", "Masterclass tier" },
		bgA = Color3.fromRGB(4, 12, 46),
		bgB = Color3.fromRGB(12, 42, 108),
		trim = Color3.fromRGB(88, 128, 208),
		text = Color3.fromRGB(162, 190, 236),
	},
	["Immortal"] = {
		hints = { "Extremely rare", "All-time legend", "Legacy card", "Iconic pull" },
		bgA = Color3.fromRGB(10, 44, 68),
		bgB = Color3.fromRGB(42, 112, 150),
		trim = Color3.fromRGB(160, 228, 242),
		text = Color3.fromRGB(202, 238, 244),
	},
	["Player of the Year"] = {
		hints = { "Seasonal special", "Award winner", "Top performer", "Limited drop", "Elite tier" },
		bgA = Color3.fromRGB(3, 3, 4),
		bgB = Color3.fromRGB(58, 44, 10),
		trim = Color3.fromRGB(220, 184, 64),
		text = Color3.fromRGB(228, 204, 112),
	},
}

local function chooseHint(hints, cardId)
	if type(hints) ~= "table" or #hints == 0 then
		return nil
	end
	local numericId = tonumber(cardId) or 1
	return hints[((numericId - 1) % #hints) + 1]
end

local function getRarityHint(rarity, cardId)
	local lockedStyle = LOCKED_STYLES[rarity]
	if lockedStyle then
		return chooseHint(lockedStyle.hints, cardId) or lockedStyle.hint
	end
	return "Open packs to unlock"
end

local function clearCards()
	newTileEntries = {}
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

	local nextReward = nil
	for _, reward in ipairs(payload.rewards or {}) do
		if not reward.claimed then
			nextReward = reward
			break
		end
	end

	if nextReward then
		local requiredCards = math.max(1, nextReward.requiredCards or 1)
		local progress = math.clamp(nextReward.progress or payload.unlockedCount or 0, 0, requiredCards)
		local progressRatio = progress / requiredCards
		nextRewardLabel.Text = nextReward.canClaim and "Ready to claim" or "Next reward"
		nextRewardLabel.TextColor3 = nextReward.canClaim and UI.Gold or UI.Muted
		nextRewardValue.Text = tostring(nextReward.label or "Reward") .. " -> " .. tostring(nextReward.reward or "")
		nextRewardProgressText.Text = tostring(progress) .. "/" .. tostring(requiredCards) .. " cards"
		nextRewardCard.BackgroundColor3 = nextReward.canClaim and Color3.fromRGB(30, 26, 10) or Color3.fromRGB(11, 16, 28)
		TweenService:Create(nextRewardProgressFill, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
			Size = UDim2.fromScale(progressRatio, 1),
		}):Play()
	else
		nextRewardLabel.Text = "Album rewards complete"
		nextRewardLabel.TextColor3 = UI.Success
		nextRewardValue.Text = "All rewards claimed"
		nextRewardProgressText.Text = "Nice."
		nextRewardCard.BackgroundColor3 = Color3.fromRGB(11, 28, 18)
		TweenService:Create(nextRewardProgressFill, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
			Size = UDim2.fromScale(1, 1),
		}):Play()
	end

	for index, reward in ipairs(payload.rewards or {}) do
		local requiredCards = math.max(1, reward.requiredCards or 1)
		local progress = math.clamp(reward.progress or payload.unlockedCount or 0, 0, requiredCards)
		local progressRatio = progress / requiredCards
		local locked = (not reward.claimed) and (not reward.canClaim)
		local rowColor = reward.claimed and Color3.fromRGB(12, 30, 20)
			or (reward.canClaim and Color3.fromRGB(34, 27, 8) or UI.Panel)
		local strokeColor = reward.claimed and UI.Success or (reward.canClaim and UI.Gold or UI.Muted)
		local fillColor = reward.claimed and UI.Success or (reward.canClaim and UI.Gold or Color3.fromRGB(96, 104, 118))
		local row = make("Frame", {
			LayoutOrder = index,
			BackgroundColor3 = rowColor,
			Size = UDim2.new(1, 0, 0, 84),
		}, rewardsList)
		addCorner(row, 10)
		local rowStroke = addStroke(row, strokeColor, reward.canClaim and 1.4 or 1, reward.canClaim and 0.16 or 0.62)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.new(1, -16, 0, 16),
			Text = reward.label .. " -> " .. reward.reward,
			TextColor3 = locked and Color3.fromRGB(180, 184, 194) or UI.Text,
			TextScaled = false,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)

		local progressBack = make("Frame", {
			BackgroundColor3 = UI.PanelAlt,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 28),
			Size = UDim2.new(1, -16, 0, 10),
		}, row)
		addCorner(progressBack, 8)

		local progressFill = make("Frame", {
			BackgroundColor3 = fillColor,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(progressRatio, 1),
		}, progressBack)
		addCorner(progressFill, 8)

		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 40),
			Size = UDim2.new(1, -16, 0, 12),
			Text = tostring(progress) .. "/" .. tostring(requiredCards) .. " cards",
			TextColor3 = UI.Muted,
			TextScaled = false,
			TextSize = 9,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)

		local stateText = reward.claimed and "CLAIMED" or (reward.canClaim and "CLAIM REWARD" or "LOCKED")
		local stateColor = reward.claimed and UI.Success or (reward.canClaim and UI.Gold or UI.Muted)
		local button = make("TextButton", {
			Position = UDim2.fromOffset(8, 56),
			Size = UDim2.new(1, -16, 0, 22),
			BackgroundColor3 = reward.canClaim and UI.Gold or (reward.claimed and Color3.fromRGB(20, 44, 30) or Color3.fromRGB(31, 34, 45)),
			Text = stateText,
			TextColor3 = reward.canClaim and Color3.fromRGB(18, 12, 6) or stateColor,
			TextScaled = false,
			TextSize = 11,
			Font = Enum.Font.GothamBlack,
			AutoButtonColor = reward.canClaim,
		}, row)
		addCorner(button, 8)
		local buttonStroke = addStroke(button, reward.canClaim and UI.Gold or UI.Muted, reward.canClaim and 1.2 or 1, reward.canClaim and 0.18 or 0.78)

		if reward.canClaim then
			TweenService:Create(rowStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = 0.08,
			}):Play()
			TweenService:Create(buttonStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = 0.02,
			}):Play()
		end

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
		rewardsList.CanvasSize = UDim2.new(0, 0, 0, rewardsLayout.AbsoluteContentSize.Y + 12)
	end)
end

local function playNewCardFeedback(tileScale)
	if tileScale then
		TweenService:Create(tileScale, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.045,
		}):Play()
		task.delay(0.15, function()
			if tileScale.Parent then
				TweenService:Create(tileScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
					Scale = 1,
				}):Play()
			end
		end)
	end
end

local function markNewTileSeen(cardId)
	if not currentPayload then
		return
	end

	currentPayload.viewed = currentPayload.viewed or {}
	currentPayload.viewed[tostring(cardId)] = true
	local result = MarkCollectionCardViewedFn:InvokeServer(cardId)
	if result and result.success and result.collection then
		currentPayload = result.collection
	end
end

local function isTileVisible(tile)
	if not tile or not tile.Parent or not panel.Visible then
		return false
	end

	local viewportTop = gridFrame.AbsolutePosition.Y + 4
	local viewportBottom = gridFrame.AbsolutePosition.Y + gridFrame.AbsoluteSize.Y - 4
	local tileTop = tile.AbsolutePosition.Y
	local tileBottom = tileTop + tile.AbsoluteSize.Y
	return tileBottom > viewportTop and tileTop < viewportBottom
end

local function updateVisibleNewCards()
	for cardId, entry in pairs(newTileEntries) do
		if not pendingViewedCards[cardId] and isTileVisible(entry.tile) then
			pendingViewedCards[cardId] = true
			playNewCardFeedback(entry.scale)

			task.delay(0.75, function()
				if newTileEntries[cardId] ~= entry then
					pendingViewedCards[cardId] = nil
					task.defer(updateVisibleNewCards)
					return
				end
				if not isTileVisible(entry.tile) then
					pendingViewedCards[cardId] = nil
					return
				end

				if entry.pulseTween then
					entry.pulseTween:Cancel()
				end
				markNewTileSeen(cardId)
				pendingViewedCards[cardId] = nil
				refreshCollection(false)
			end)
		end
	end
end

gridFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateVisibleNewCards)
gridFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateVisibleNewCards)
gridFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateVisibleNewCards)

local function makeCardTile(card, packedCount, index, payload)
	local unlocked = packedCount > 0
	local style = Utils.GetRarityStyle(card.rarity)
	local skin = COLLECTION_SKINS[card.rarity]
	local lockedStyle = LOCKED_STYLES[card.rarity] or LOCKED_STYLES.Gold
	local trim = (skin and skin.trim) or style.trim or style.primary or UI.Gold
	local dark = (skin and skin.bgA) or style.dark or UI.PanelAlt
	local secondary = (skin and skin.bgB) or style.secondary or dark
	local textColor = (skin and skin.text) or style.text or UI.Text
	local glow = (skin and skin.glow) or style.glow or trim
	local viewed = payload and payload.viewed or {}
	local isNew = unlocked and viewed[tostring(card.id)] ~= true
	local tileTrim = unlocked and trim or (lockedStyle.trim or UI.Muted)
	local tileText = unlocked and textColor or (lockedStyle.text or UI.Muted)

	local tile = make("Frame", {
		LayoutOrder = index,
		Active = true,
		BackgroundColor3 = unlocked and dark or (lockedStyle.bgA or Color3.fromRGB(10, 12, 20)),
	}, gridFrame)
	local tileScale = make("UIScale", {
		Scale = 1,
	}, tile)
	addCorner(tile, 12)
	local stroke = addStroke(tile, tileTrim, unlocked and 1.2 or 1, isNew and 0.12 or (unlocked and 0.34 or 0.62))

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, unlocked and secondary or (lockedStyle.bgB or Color3.fromRGB(18, 21, 34))),
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
	addStroke(statusPill, isNew and glow or tileTrim, 1, isNew and 0.25 or 0.68)

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
		Size = UDim2.new(1, -16, 0, 32),
		Text = unlocked and card.name or ("Mystery " .. (style.label or card.rarity)),
		TextColor3 = tileText,
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBlack,
	}, tile)

	local packedBadge = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = unlocked and Color3.fromRGB(24, 26, 34) or UI.PanelAlt,
		Position = UDim2.new(0.5, 0, 0, 68),
		Size = UDim2.fromOffset(88, 20),
	}, tile)
	addCorner(packedBadge, 9)
	addStroke(packedBadge, tileTrim, 1, unlocked and 0.45 or 0.7)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = unlocked and ("Packed x" .. tostring(packedCount)) or "???",
		TextColor3 = unlocked and glow or tileText,
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, packedBadge)

	local flagId = unlocked and NationFlags[card.nation]
	if flagId then
		make("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = flagId,
			ScaleType = Enum.ScaleType.Fit,
			Position = UDim2.fromOffset(8, 101),
			Size = UDim2.fromOffset(22, 14),
		}, tile)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(34, 94),
			Size = UDim2.new(1, -42, 0, 14),
			Text = (card.rating and (tostring(card.rating) .. " | ") or "") .. card.position .. " | " .. card.nation,
			TextColor3 = UI.Muted,
			TextScaled = false,
			TextSize = 9,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, tile)
	else
		make("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 94),
			Size = UDim2.new(1, -16, 0, 14),
			Text = unlocked and ((card.rating and (tostring(card.rating) .. " | ") or "") .. card.position .. " | " .. card.nation) or getRarityHint(card.rarity, card.id),
			TextColor3 = unlocked and UI.Muted or tileText,
			TextScaled = false,
			TextSize = 9,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, tile)
	end

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 112),
		Size = UDim2.new(1, -16, 0, 14),
		Text = unlocked and "Collected in album" or "Open packs to reveal",
		TextColor3 = unlocked and UI.Text or UI.Muted,
		TextScaled = false,
		TextSize = 9,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, tile)

	if isNew then
		local pulseTween = TweenService:Create(stroke, TweenInfo.new(0.72, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Transparency = 0.04,
			Thickness = 1.8,
		})
		pulseTween:Play()
		newTileEntries[card.id] = {
			tile = tile,
			scale = tileScale,
			pulseTween = pulseTween,
		}
	end

	local function showHover()
		TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			Transparency = unlocked and 0.08 or 0.34,
			Thickness = unlocked and 1.6 or 1.3,
		}):Play()
	end

	local function hideHover()
		if isNew then
			return
		end
		TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			Transparency = unlocked and 0.34 or 0.62,
			Thickness = unlocked and 1.2 or 1,
		}):Play()
	end

	local function selectTile()
		if unlocked then
			summaryLabel.Text = card.name .. " | " .. card.rarity .. " | Packed " .. tostring(packedCount) .. " times"
		else
			summaryLabel.Text = (style.label or card.rarity) .. " | " .. getRarityHint(card.rarity, card.id)
		end
	end

	local clickLayer = make("TextButton", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	}, tile)
	clickLayer.MouseEnter:Connect(showHover)
	clickLayer.MouseLeave:Connect(hideHover)
	clickLayer.MouseButton1Click:Connect(selectTile)
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
		updateVisibleNewCards()
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
