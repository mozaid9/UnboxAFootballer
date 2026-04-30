local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local PackConfig = require(Shared:WaitForChild("PackConfig"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local ClaimFreePackFn = Remotes:WaitForChild("ClaimFreePack")
local ClaimDailyRewardFn = Remotes:WaitForChild("ClaimDailyReward")

local UI = Constants.UI

local DAILY_REWARDS = Constants.DailyStreakRewards or {
	{ day = 1, packId = "GoldPack", label = "Gold Pack" },
	{ day = 2, packId = "RarePack", label = "Rare Pack" },
	{ day = 3, packId = "PremiumPack", label = "Premium Pack" },
	{ day = 4, packId = "DeluxePack", label = "Deluxe Pack" },
}

local PACK_INFO = {
	"GoldPack",
	"RarePack",
	"PremiumPack",
	"DeluxePack",
}

local RARITY_BAR_COLORS = {
	Color3.fromRGB(255, 216, 48),
	Color3.fromRGB(255, 152, 38),
	Color3.fromRGB(255, 239, 148),
	Color3.fromRGB(225, 54, 67),
	Color3.fromRGB(166, 86, 255),
	Color3.fromRGB(226, 248, 255),
	Color3.fromRGB(255, 208, 76),
}

local LIMITED_DEAL_DURATION = (4 * 60) + 32

local dailyRewardStreak = 0
local limitedDealRemaining = LIMITED_DEAL_DURATION

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
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function addPadding(parent, all, left, right, top, bottom)
	return make("UIPadding", {
		PaddingLeft = UDim.new(0, left or all or 0),
		PaddingRight = UDim.new(0, right or all or 0),
		PaddingTop = UDim.new(0, top or all or 0),
		PaddingBottom = UDim.new(0, bottom or all or 0),
	}, parent)
end

local function addHoverScale(guiObject, hoverScale)
	local scale = make("UIScale", { Scale = 1 }, guiObject)
	local hover = hoverScale or 1.025

	guiObject.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = hover,
		}):Play()
	end)

	guiObject.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end)

	if guiObject:IsA("GuiButton") then
		guiObject.MouseButton1Down:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 0.985,
			}):Play()
		end)
		guiObject.MouseButton1Up:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = hover,
			}):Play()
		end)
	end

	return scale
end

local function formatClock(seconds)
	local value = math.max(0, math.floor(seconds or 0))
	local hours = math.floor(value / 3600)
	local minutes = math.floor((value % 3600) / 60)
	local secs = value % 60

	if hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%d:%02d", minutes, secs)
end

local function formatNumber(numberValue)
	local source = tostring(math.floor(tonumber(numberValue) or 0))
	local result = source:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return result:match("^,(.+)$") or result
end

local function packDisplayName(packId)
	local packDef = packId and PackConfig.ById[packId]
	return packDef and packDef.displayName or "Pack"
end

local function packColor(packId)
	local packDef = packId and PackConfig.ById[packId]
	return packDef and packDef.color or UI.Gold
end

local function getNextDailyReward()
	if #DAILY_REWARDS == 0 then
		return nil, 0
	end
	local index = ((math.max(0, dailyRewardStreak) % #DAILY_REWARDS) + 1)
	return DAILY_REWARDS[index], index
end

local existingGui = playerGui:FindFirstChild("ShopUI")
if existingGui then
	existingGui:Destroy()
end

local screenGui = make("ScreenGui", {
	Name = "ShopUI",
	ResetOnSpawn = false,
	Enabled = false,
	DisplayOrder = 12,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

local isOpen = false
local freePackRemaining = Constants.FreePackCooldown
local dailyRemaining = Constants.DailyRewardCooldown
local canClaimFree = false
local canClaimDaily = false
local claimingFree = false
local claimingDaily = false
local queuedRewardCount = 0

local overlay = make("Frame", {
	Name = "Overlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.45,
	ZIndex = 1,
}, screenGui)

local overlayBtn = make("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	ZIndex = 2,
}, overlay)

local PANEL_W, PANEL_H = 560, 620

local panel = make("Frame", {
	Name = "ShopPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(PANEL_W, PANEL_H),
	BackgroundColor3 = UI.Background,
	ZIndex = 10,
}, screenGui)
addCorner(panel, 20)
addStroke(panel, UI.Gold, 2, 0.42)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 22, 42)),
		ColorSequenceKeypoint.new(0.58, UI.Background),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 7, 14)),
	}),
	Rotation = 130,
}, panel)

local header = make("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 68),
	BackgroundColor3 = Color3.fromRGB(8, 12, 24),
	ZIndex = 11,
}, panel)
addCorner(header, 20)

make("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundColor3 = Color3.fromRGB(8, 12, 24),
	BorderSizePixel = 0,
	ZIndex = 11,
}, header)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 22, 0, 0),
	Size = UDim2.new(1, -96, 1, 0),
	Text = "SHOP",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 26,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, header)

local closeBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -18, 0.5, 0),
	Size = UDim2.fromOffset(42, 42),
	BackgroundColor3 = UI.Danger,
	Text = "X",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 12,
}, header)
addCorner(closeBtn, 12)
addHoverScale(closeBtn, 1.05)

local scroll = make("ScrollingFrame", {
	Name = "ContentScroll",
	Position = UDim2.new(0, 0, 0, 68),
	Size = UDim2.new(1, 0, 1, -68),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = Color3.fromRGB(255, 217, 76),
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 10,
}, panel)

local content = make("Frame", {
	Name = "Content",
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ZIndex = 10,
}, scroll)
addPadding(content, 16)

local contentLayout = make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, contentLayout.AbsoluteContentSize.Y + 36)
end)

local function sectionLabel(text, layoutOrder)
	return make("TextLabel", {
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
	}, content)
end

sectionLabel("FREE REWARDS", 1)

local freeCard = make("Frame", {
	LayoutOrder = 2,
	Size = UDim2.new(1, 0, 0, 124),
	BackgroundColor3 = Color3.fromRGB(12, 21, 30),
	ClipsDescendants = true,
	ZIndex = 11,
}, content)
addCorner(freeCard, 18)
local freeStroke = addStroke(freeCard, UI.Success, 2, 0.56)
local freeCardScale = addHoverScale(freeCard, 1.01)

local freeGradient = make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 31, 23)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 31)),
	}),
	Rotation = 15,
}, freeCard)

local freeShine = make("Frame", {
	Position = UDim2.new(-0.24, 0, -0.16, 0),
	Size = UDim2.new(0, 72, 1.32, 0),
	Rotation = 12,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.7,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 12,
}, freeCard)
make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Rotation = 0,
}, freeShine)

local freeIcon = make("Frame", {
	Position = UDim2.new(0, 18, 0, 22),
	Size = UDim2.fromOffset(62, 62),
	BackgroundColor3 = Color3.fromRGB(20, 69, 34),
	ZIndex = 12,
}, freeCard)
addCorner(freeIcon, 31)

make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "F",
	TextColor3 = Color3.fromRGB(84, 224, 111),
	TextScaled = false,
	TextSize = 32,
	Font = Enum.Font.GothamBlack,
	ZIndex = 13,
}, freeIcon)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 98, 0, 22),
	Size = UDim2.new(1, -260, 0, 28),
	Text = "FREE GOLD PACK",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, freeCard)

local freeSubLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 98, 0, 52),
	Size = UDim2.new(1, -260, 0, 22),
	Text = "One free pull every 4 hours",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, freeCard)

local freeProgressBack = make("Frame", {
	Position = UDim2.new(0, 98, 0, 84),
	Size = UDim2.new(1, -288, 0, 12),
	BackgroundColor3 = Color3.fromRGB(25, 31, 48),
	BorderSizePixel = 0,
	ZIndex = 12,
}, freeCard)
addCorner(freeProgressBack, 6)

local freeProgressFill = make("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(76, 220, 105),
	BorderSizePixel = 0,
	ZIndex = 14,
}, freeProgressBack)
addCorner(freeProgressFill, 6)

local freeClaimBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -18, 0, 51),
	Size = UDim2.fromOffset(150, 50),
	BackgroundColor3 = Color3.fromRGB(35, 140, 65),
	Text = "CLAIM",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = 14,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = false,
	ZIndex = 12,
}, freeCard)
addCorner(freeClaimBtn, 14)
addHoverScale(freeClaimBtn, 1.045)
local freeReadyPulseScale = make("UIScale", { Scale = 1 }, freeClaimBtn)

local freeStatusLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 82),
	Size = UDim2.fromOffset(146, 18),
	Text = "",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 12,
}, freeCard)

local returnHookLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 101),
	Size = UDim2.fromOffset(250, 16),
	Text = "",
	TextColor3 = Color3.fromRGB(152, 246, 172),
	TextScaled = false,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 12,
}, freeCard)

local dailyCard = make("Frame", {
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, 166),
	BackgroundColor3 = UI.Panel,
	ZIndex = 11,
}, content)
addCorner(dailyCard, 18)
local dailyStroke = addStroke(dailyCard, UI.Gold, 2, 0.58)
addHoverScale(dailyCard, 1.01)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 28, 5)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 31)),
	}),
	Rotation = 18,
}, dailyCard)

local dailyIcon = make("Frame", {
	Position = UDim2.new(0, 18, 0, 20),
	Size = UDim2.fromOffset(58, 58),
	BackgroundColor3 = Color3.fromRGB(86, 72, 0),
	ZIndex = 12,
}, dailyCard)
addCorner(dailyIcon, 29)

make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "D",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 30,
	Font = Enum.Font.GothamBlack,
	ZIndex = 13,
}, dailyIcon)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 94, 0, 20),
	Size = UDim2.new(1, -266, 0, 26),
	Text = "DAILY STREAK",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, dailyCard)

local dailySubLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 94, 0, 49),
	Size = UDim2.new(1, -282, 0, 38),
	Text = "Claim to queue your next reward pack",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	ZIndex = 12,
}, dailyCard)

local dailyClaimBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 24),
	Size = UDim2.fromOffset(164, 48),
	BackgroundColor3 = Color3.fromRGB(140, 102, 8),
	Text = "CLAIM",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = false,
	ZIndex = 12,
}, dailyCard)
addCorner(dailyClaimBtn, 14)
addHoverScale(dailyClaimBtn, 1.045)

local dailyRewardRow = make("Frame", {
	Position = UDim2.new(0, 18, 1, -74),
	Size = UDim2.new(1, -36, 0, 54),
	BackgroundTransparency = 1,
	ZIndex = 12,
}, dailyCard)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, dailyRewardRow)

local dailyCells = {}
for index, reward in ipairs(DAILY_REWARDS) do
	local color = packColor(reward.packId)
	local cell = make("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(0.25, -7, 1, 0),
		BackgroundColor3 = Color3.fromRGB(19, 24, 39),
		ZIndex = 12,
	}, dailyRewardRow)
	addCorner(cell, 12)
	local stroke = addStroke(cell, color, 1.5, 0.72)
	local scale = make("UIScale", { Scale = 1 }, cell)

	local dayLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 6),
		Size = UDim2.new(1, -16, 0, 14),
		Text = "DAY " .. tostring(reward.day or index),
		TextColor3 = color,
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	}, cell)

	local packLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 24),
		Size = UDim2.new(1, -16, 0, 20),
		Text = reward.label or packDisplayName(reward.packId),
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	}, cell)

	dailyCells[index] = {
		frame = cell,
		stroke = stroke,
		scale = scale,
		dayLabel = dayLabel,
		packLabel = packLabel,
		color = color,
	}
end

sectionLabel("LIMITED OFFERS", 4)

local limitedCard = make("Frame", {
	LayoutOrder = 5,
	Size = UDim2.new(1, 0, 0, 92),
	BackgroundColor3 = Color3.fromRGB(22, 15, 32),
	ZIndex = 11,
}, content)
addCorner(limitedCard, 16)
local limitedStroke = addStroke(limitedCard, Color3.fromRGB(190, 112, 255), 2, 0.34)
addHoverScale(limitedCard, 1.01)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(57, 28, 82)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 31)),
	}),
	Rotation = 24,
}, limitedCard)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 14),
	Size = UDim2.new(1, -300, 0, 22),
	Text = "LIMITED DEAL",
	TextColor3 = Color3.fromRGB(220, 180, 255),
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, limitedCard)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 37),
	Size = UDim2.new(1, -210, 0, 24),
	Text = "Premium Pack x3",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 17,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, limitedCard)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 64),
	Size = UDim2.new(1, -210, 0, 16),
	Text = "+10% Pack Luck (5 min)",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, limitedCard)

local limitedUrgencyLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 118, 0, 14),
	Size = UDim2.fromOffset(90, 22),
	Text = "ENDS SOON",
	TextColor3 = Color3.fromRGB(255, 206, 113),
	TextScaled = false,
	TextSize = 10,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, limitedCard)

local limitedTimer = make("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 15),
	Size = UDim2.fromOffset(132, 24),
	BackgroundTransparency = 1,
	Text = "04:32 LEFT",
	TextColor3 = Color3.fromRGB(255, 221, 130),
	TextScaled = false,
	TextSize = 14,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 12,
}, limitedCard)

local bestValueBadge = make("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -158, 0, 14),
	Size = UDim2.fromOffset(96, 24),
	BackgroundColor3 = Color3.fromRGB(255, 213, 91),
	Text = "BEST VALUE",
	TextColor3 = Color3.fromRGB(31, 22, 8),
	TextScaled = false,
	TextSize = 10,
	Font = Enum.Font.GothamBlack,
	ZIndex = 12,
}, limitedCard)
addCorner(bestValueBadge, 10)

local limitedBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 45),
	Size = UDim2.fromOffset(132, 34),
	BackgroundColor3 = Color3.fromRGB(49, 38, 69),
	Text = "REBIRTH 1 REQUIRED\nUnlock powerful deals",
	TextColor3 = Color3.fromRGB(190, 174, 210),
	TextScaled = false,
	TextSize = 9,
	TextWrapped = true,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = false,
	Active = false,
	ZIndex = 12,
}, limitedCard)
addCorner(limitedBtn, 10)

sectionLabel("PACKS", 6)

local packGrid = make("Frame", {
	LayoutOrder = 7,
	Size = UDim2.new(1, 0, 0, 222),
	BackgroundTransparency = 1,
	ZIndex = 11,
}, content)

local gridLayout = make("UIGridLayout", {
	CellPadding = UDim2.fromOffset(10, 10),
	CellSize = UDim2.new(0.5, -5, 0, 106),
	FillDirectionMaxCells = 2,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, packGrid)
_ = gridLayout

for index, packId in ipairs(PACK_INFO) do
	local packDef = PackConfig.ById[packId]
	local color = packDef and packDef.color or UI.Gold
	local card = make("Frame", {
		LayoutOrder = index,
		BackgroundColor3 = Color3.fromRGB(15, 19, 32),
		ZIndex = 11,
	}, packGrid)
	addCorner(card, 14)
	addStroke(card, color, 1.4, 0.58)
	addHoverScale(card, 1.015)

	make("Frame", {
		Position = UDim2.new(0, 10, 0, 12),
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = color:Lerp(Color3.fromRGB(0, 0, 0), 0.55),
		ZIndex = 12,
	}, card)
	addCorner(card:FindFirstChildOfClass("Frame"), 10)

	local icon = card:FindFirstChildOfClass("Frame")
	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = string.sub(packDef and packDef.displayName or "P", 1, 1),
		TextColor3 = color,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		ZIndex = 13,
	}, icon)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 0, 10),
		Size = UDim2.new(1, -132, 0, 18),
		Text = packDef and packDef.displayName or packId,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 13,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, card)

	make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(72, 18),
		Text = tostring(formatNumber(packDef and packDef.futureCost or 0)) .. " Fans",
		TextColor3 = color,
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 12,
	}, card)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 0, 31),
		Size = UDim2.new(1, -66, 0, 26),
		Text = packDef and packDef.description or "Pack odds improve by tier.",
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextWrapped = true,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 12,
	}, card)

	local rarityBar = make("Frame", {
		Position = UDim2.new(0, 56, 1, -30),
		Size = UDim2.new(1, -66, 0, 6),
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 12,
	}, card)
	addCorner(rarityBar, 3)

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, rarityBar)

	local weights = packDef and packDef.tierWeights or {}
	for rarityIndex, weight in ipairs(weights) do
		if weight > 0 then
			local segment = make("Frame", {
				LayoutOrder = rarityIndex,
				Size = UDim2.new(math.max(weight / 100, 0.012), 0, 1, 0),
				BackgroundColor3 = RARITY_BAR_COLORS[rarityIndex] or color,
				BorderSizePixel = 0,
				ZIndex = 13,
			}, rarityBar)
			if rarityIndex == 1 then
				addCorner(segment, 3)
			end
		end
	end

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 1, -21),
		Size = UDim2.new(1, -66, 0, 12),
		Text = "Gold   Rare   Elite",
		TextColor3 = Color3.fromRGB(160, 152, 126),
		TextScaled = false,
		TextSize = 9,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, card)
end

local packHint = make("TextLabel", {
	LayoutOrder = 8,
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = Color3.fromRGB(12, 16, 27),
	Text = "Higher packs unlock stronger players and faster income. Fan prices are for future direct buys.",
	TextColor3 = Color3.fromRGB(192, 186, 165),
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextWrapped = true,
	ZIndex = 11,
}, content)
addCorner(packHint, 10)
addStroke(packHint, UI.Gold, 1, 0.88)

local futureCard = make("Frame", {
	LayoutOrder = 9,
	Size = UDim2.new(1, 0, 0, 58),
	BackgroundColor3 = UI.PanelAlt,
	ZIndex = 11,
}, content)
addCorner(futureCard, 14)
addStroke(futureCard, UI.Muted, 1, 0.86)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 8),
	Size = UDim2.new(1, -36, 0, 20),
	Text = "UNLOCK AT 1 REBIRTH",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, futureCard)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 30),
	Size = UDim2.new(1, -36, 0, 18),
	Text = "Stadium skins and card effects",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, futureCard)

local footerHookLabel = make("TextLabel", {
	LayoutOrder = 10,
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(146, 236, 164),
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamBlack,
	ZIndex = 11,
}, content)

local function setProgress(fill, percent)
	local target = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
	TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = target,
	}):Play()
end

local freeReadyGlowTween
local freeReadyBounceTween
local freeCardPulseTween
local freeShineTween
local freeReadyPulseOn = false

local function stopTween(tween)
	if tween then
		tween:Cancel()
	end
end

local function setFreeReadyPulse(enabled)
	if freeReadyPulseOn == enabled then
		return
	end
	freeReadyPulseOn = enabled

	stopTween(freeReadyGlowTween)
	stopTween(freeReadyBounceTween)
	stopTween(freeCardPulseTween)
	stopTween(freeShineTween)
	freeReadyGlowTween = nil
	freeReadyBounceTween = nil
	freeCardPulseTween = nil
	freeShineTween = nil
	freeReadyPulseScale.Scale = 1
	freeCardScale.Scale = 1
	freeShine.Visible = false
	freeShine.Position = UDim2.new(-0.24, 0, -0.16, 0)

	if enabled then
		freeShine.Visible = true
		freeReadyGlowTween = TweenService:Create(
			freeStroke,
			TweenInfo.new(0.58, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.02 }
		)
		freeReadyBounceTween = TweenService:Create(
			freeReadyPulseScale,
			TweenInfo.new(0.54, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.035 }
		)
		freeCardPulseTween = TweenService:Create(
			freeCardScale,
			TweenInfo.new(0.82, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = 1.015 }
		)
		freeShineTween = TweenService:Create(
			freeShine,
			TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.25),
			{ Position = UDim2.new(1.14, 0, -0.16, 0) }
		)
		freeReadyGlowTween:Play()
		freeReadyBounceTween:Play()
		freeCardPulseTween:Play()
		freeShineTween:Play()
	end
end

TweenService:Create(
	limitedStroke,
	TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Transparency = 0.12 }
):Play()

TweenService:Create(
	limitedTimer,
	TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ TextColor3 = Color3.fromRGB(255, 246, 190) }
):Play()

local function updateLimitedDeal()
	limitedTimer.Text = formatClock(limitedDealRemaining) .. " LEFT"

	if limitedDealRemaining <= 60 then
		limitedStroke.Color = Color3.fromRGB(255, 84, 105)
		limitedTimer.TextColor3 = Color3.fromRGB(255, 112, 128)
		limitedUrgencyLabel.Text = "ENDS NOW"
		limitedUrgencyLabel.TextColor3 = Color3.fromRGB(255, 112, 128)
	elseif limitedDealRemaining <= 180 then
		limitedStroke.Color = Color3.fromRGB(255, 182, 96)
		limitedTimer.TextColor3 = Color3.fromRGB(255, 226, 150)
		limitedUrgencyLabel.Text = "ENDS SOON"
		limitedUrgencyLabel.TextColor3 = Color3.fromRGB(255, 206, 113)
	else
		limitedStroke.Color = Color3.fromRGB(190, 112, 255)
		limitedTimer.TextColor3 = Color3.fromRGB(255, 221, 130)
		limitedUrgencyLabel.Text = "FLASH DEAL"
		limitedUrgencyLabel.TextColor3 = Color3.fromRGB(220, 180, 255)
	end
end

local function updateFreePackBtn()
	local progress = 1 - (math.clamp(freePackRemaining, 0, Constants.FreePackCooldown) / Constants.FreePackCooldown)
	if canClaimFree then
		progress = 1
	end
	setProgress(freeProgressFill, progress)

	if canClaimFree then
		setFreeReadyPulse(true)
		freeCard.BackgroundColor3 = Color3.fromRGB(9, 40, 23)
		freeGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(21, 92, 42)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 19, 28)),
		})
		freeStroke.Color = Color3.fromRGB(108, 255, 137)
		freeProgressFill.BackgroundColor3 = Color3.fromRGB(110, 255, 139)
		freeClaimBtn.Text = "CLAIM FREE PACK"
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(35, 185, 78)
		freeClaimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		freeClaimBtn.Active = true
		freeSubLabel.Text = "Tap to open your free reward"
		freeSubLabel.TextColor3 = Color3.fromRGB(97, 238, 125)
		freeStatusLabel.Text = "CLAIM NOW"
		freeStatusLabel.TextColor3 = Color3.fromRGB(97, 238, 125)
		if not freeReadyPulseOn then
			freeStroke.Transparency = 0.18
		end
		returnHookLabel.Text = "Free Pack is ready"
		footerHookLabel.Text = "Free Pack ready - claim before opening more packs."
	elseif freePackRemaining <= 60 then
		setFreeReadyPulse(false)
		freeCard.BackgroundColor3 = Color3.fromRGB(24, 30, 19)
		freeGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 63, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 31)),
		})
		freeStroke.Color = Color3.fromRGB(216, 255, 140)
		freeProgressFill.BackgroundColor3 = Color3.fromRGB(216, 255, 140)
		freeClaimBtn.Text = "READY IN " .. formatClock(freePackRemaining)
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(41, 53, 38)
		freeClaimBtn.TextColor3 = Color3.fromRGB(222, 255, 218)
		freeClaimBtn.Active = false
		freeSubLabel.Text = "1 free pack every 4 hours"
		freeSubLabel.TextColor3 = Color3.fromRGB(216, 255, 190)
		freeStatusLabel.Text = "FINAL MINUTE"
		freeStatusLabel.TextColor3 = Color3.fromRGB(216, 255, 190)
		freeStroke.Transparency = 0.25
		returnHookLabel.Text = "Almost ready"
		footerHookLabel.Text = "Free pack almost ready..."
	elseif freePackRemaining <= 600 then
		setFreeReadyPulse(false)
		freeCard.BackgroundColor3 = Color3.fromRGB(24, 24, 18)
		freeGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(54, 43, 13)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 31)),
		})
		freeStroke.Color = Color3.fromRGB(255, 222, 106)
		freeProgressFill.BackgroundColor3 = Color3.fromRGB(255, 222, 106)
		freeClaimBtn.Text = "READY IN " .. formatClock(freePackRemaining)
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(44, 40, 26)
		freeClaimBtn.TextColor3 = Color3.fromRGB(255, 231, 139)
		freeClaimBtn.Active = false
		freeSubLabel.Text = "1 free pack every 4 hours"
		freeSubLabel.TextColor3 = Color3.fromRGB(221, 202, 132)
		freeStatusLabel.Text = "UNDER 10 MIN"
		freeStatusLabel.TextColor3 = Color3.fromRGB(255, 231, 139)
		freeStroke.Transparency = 0.32
		returnHookLabel.Text = "Nearly ready"
		footerHookLabel.Text = "Next Free Pack in " .. formatClock(freePackRemaining)
	else
		setFreeReadyPulse(false)
		freeCard.BackgroundColor3 = Color3.fromRGB(12, 21, 30)
		freeGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 31, 23)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 31)),
		})
		freeStroke.Color = UI.Success
		freeProgressFill.BackgroundColor3 = Color3.fromRGB(76, 220, 105)
		freeClaimBtn.Text = "READY IN " .. formatClock(freePackRemaining)
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		freeClaimBtn.TextColor3 = UI.Muted
		freeClaimBtn.Active = false
		freeSubLabel.Text = "1 free pack every 4 hours"
		freeSubLabel.TextColor3 = UI.Muted
		freeStatusLabel.Text = ""
		freeStatusLabel.TextColor3 = UI.Muted
		freeStroke.Transparency = 0.56
		if freePackRemaining <= 1800 then
			returnHookLabel.Text = "Next Free Pack in " .. formatClock(freePackRemaining)
			footerHookLabel.Text = "Next Free Pack in " .. formatClock(freePackRemaining)
		else
			returnHookLabel.Text = ""
			footerHookLabel.Text = ""
		end
	end
end

local function updateDailyCells(nextIndex)
	local cycleProgress = dailyRewardStreak % math.max(1, #DAILY_REWARDS)
	if not canClaimDaily and cycleProgress == 0 and dailyRewardStreak > 0 then
		cycleProgress = #DAILY_REWARDS
	end
	local todayIndex = canClaimDaily and nextIndex or math.max(1, cycleProgress)

	for index, cell in ipairs(dailyCells) do
		local claimed = index <= cycleProgress
		local isNext = index == nextIndex and canClaimDaily
		local isToday = index == todayIndex

		if claimed then
			cell.frame.BackgroundColor3 = cell.color:Lerp(Color3.fromRGB(0, 0, 0), 0.62)
			cell.stroke.Transparency = isToday and 0.08 or 0.28
			cell.dayLabel.Text = isToday and "TODAY CLAIMED" or ("DAY " .. tostring(index) .. " CLAIMED")
			cell.packLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			cell.scale.Scale = isToday and 1.04 or 1
		elseif isNext then
			cell.frame.BackgroundColor3 = cell.color:Lerp(Color3.fromRGB(14, 18, 31), 0.48)
			cell.stroke.Transparency = 0.05
			cell.dayLabel.Text = "TODAY"
			cell.packLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			cell.scale.Scale = 1.04
		else
			cell.frame.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
			cell.stroke.Transparency = 0.84
			cell.dayLabel.Text = "DAY " .. tostring(index)
			cell.packLabel.TextColor3 = Color3.fromRGB(112, 108, 98)
			cell.scale.Scale = 1
		end
	end
end

local function updateDailyBtn()
	local reward, nextIndex = getNextDailyReward()
	local rewardName = reward and (reward.label or packDisplayName(reward.packId)) or "Reward Pack"
	local todayRewardName = rewardName
	if not canClaimDaily and #DAILY_REWARDS > 0 then
		local currentIndex = dailyRewardStreak % #DAILY_REWARDS
		if currentIndex == 0 and dailyRewardStreak > 0 then
			currentIndex = #DAILY_REWARDS
		elseif currentIndex == 0 then
			currentIndex = nextIndex
		end
		local todayReward = DAILY_REWARDS[currentIndex]
		todayRewardName = todayReward and (todayReward.label or packDisplayName(todayReward.packId)) or rewardName
	end

	updateDailyCells(nextIndex)

	if canClaimDaily then
		dailyClaimBtn.Text = "CLAIM DAY " .. tostring(nextIndex) .. " REWARD"
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(151, 108, 9)
		dailyClaimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		dailyClaimBtn.Active = true
		dailySubLabel.Text = "STREAK: " .. tostring(dailyRewardStreak) .. " DAYS\nTODAY: " .. rewardName
		dailySubLabel.TextColor3 = UI.Gold
		dailyStroke.Transparency = 0.18
	else
		dailyClaimBtn.Text = "READY IN " .. formatClock(dailyRemaining)
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		dailyClaimBtn.TextColor3 = UI.Muted
		dailyClaimBtn.Active = false
		dailySubLabel.Text = "STREAK: " .. tostring(dailyRewardStreak) .. " DAYS\nTODAY: " .. todayRewardName .. "  |  NEXT: " .. rewardName
		dailySubLabel.TextColor3 = UI.Muted
		dailyStroke.Transparency = 0.58
	end
end

local function applyData(data)
	if not data then
		return
	end

	freePackRemaining = data.freePackRemaining or Constants.FreePackCooldown
	canClaimFree = data.canClaimFreePack == true

	dailyRemaining = data.dailyRewardRemaining or Constants.DailyRewardCooldown
	canClaimDaily = data.canClaimDailyReward == true
	dailyRewardStreak = data.dailyRewardStreak or dailyRewardStreak or 0
	queuedRewardCount = data.queuedRewardCount or queuedRewardCount or 0

	updateFreePackBtn()
	updateDailyBtn()
end

local function runCountdown()
	while isOpen and screenGui.Enabled do
		task.wait(1)
		if not isOpen then
			break
		end

		if not canClaimFree then
			freePackRemaining = math.max(0, freePackRemaining - 1)
			if freePackRemaining <= 0 then
				canClaimFree = true
			end
		end

		if not canClaimDaily then
			dailyRemaining = math.max(0, dailyRemaining - 1)
			if dailyRemaining <= 0 then
				canClaimDaily = true
			end
		end

		limitedDealRemaining = math.max(0, limitedDealRemaining - 1)
		if limitedDealRemaining <= 0 then
			limitedDealRemaining = LIMITED_DEAL_DURATION
		end

		updateLimitedDeal()
		updateFreePackBtn()
		updateDailyBtn()
	end
end

local panelScale = make("UIScale", { Scale = 0.88 }, panel)

local function openShop()
	if isOpen then
		return
	end
	isOpen = true
	screenGui.Enabled = true

	task.spawn(function()
		local data = GetPlayerDataFn:InvokeServer()
		if isOpen then
			applyData(data)
		end
	end)

	panelScale.Scale = 0.88
	TweenService:Create(panelScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	task.spawn(runCountdown)
end

local function closeShop()
	if not isOpen then
		return
	end
	isOpen = false

	TweenService:Create(panelScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.88,
	}):Play()
	task.delay(0.16, function()
		screenGui.Enabled = false
	end)
end

closeBtn.MouseButton1Click:Connect(closeShop)
overlayBtn.MouseButton1Click:Connect(closeShop)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape and isOpen then
		closeShop()
	end
end)

toggleEvent.Event:Connect(function()
	if isOpen then
		closeShop()
	else
		openShop()
	end
end)

freeClaimBtn.MouseButton1Click:Connect(function()
	if not canClaimFree or claimingFree then
		return
	end
	claimingFree = true
	freeClaimBtn.Text = "OPENING..."
	freeClaimBtn.Active = false

	local result = ClaimFreePackFn:InvokeServer()
	claimingFree = false

	if result and result.success then
		canClaimFree = false
		freePackRemaining = result.freePackRemaining or Constants.FreePackCooldown
		updateFreePackBtn()
		closeShop()
	else
		freeClaimBtn.Text = result and result.error or "ERROR"
		task.delay(2, function()
			updateFreePackBtn()
		end)
	end
end)

dailyClaimBtn.MouseButton1Click:Connect(function()
	if not canClaimDaily or claimingDaily then
		return
	end
	claimingDaily = true
	dailyClaimBtn.Text = "QUEUING..."
	dailyClaimBtn.Active = false

	local result = ClaimDailyRewardFn:InvokeServer()
	claimingDaily = false

	if result and result.success then
		canClaimDaily = false
		dailyRemaining = result.dailyRewardRemaining or Constants.DailyRewardCooldown
		dailyRewardStreak = result.dailyRewardStreak or dailyRewardStreak
		queuedRewardCount = result.queuedRewardCount or queuedRewardCount
		updateDailyBtn()

		dailyClaimBtn.Text = "PACK QUEUED"
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 65)
		task.delay(1.6, function()
			if not canClaimDaily then
				updateDailyBtn()
			end
		end)
	else
		dailyClaimBtn.Text = result and result.error or "ERROR"
		task.delay(2, function()
			updateDailyBtn()
		end)
	end
end)

updateFreePackBtn()
updateDailyBtn()
updateLimitedDeal()
