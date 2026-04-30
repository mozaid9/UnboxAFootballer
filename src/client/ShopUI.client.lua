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

local dailyRewardStreak = 0

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
	ZIndex = 11,
}, content)
addCorner(freeCard, 18)
local freeStroke = addStroke(freeCard, UI.Success, 2, 0.56)
addHoverScale(freeCard, 1.01)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 31, 23)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 17, 31)),
	}),
	Rotation = 15,
}, freeCard)

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
	ZIndex = 13,
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
	Size = UDim2.new(1, -266, 0, 22),
	Text = "Claim to queue your next reward pack",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, dailyCard)

local dailyClaimBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 24),
	Size = UDim2.fromOffset(150, 48),
	BackgroundColor3 = Color3.fromRGB(140, 102, 8),
	Text = "CLAIM",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = 14,
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
addStroke(limitedCard, Color3.fromRGB(180, 92, 255), 1.5, 0.48)
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
	Size = UDim2.new(1, -210, 0, 22),
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
	Text = "Premium Pack x3 + 10% Luck",
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
	Text = "Unlocks after first rebirth",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, limitedCard)

local limitedTimer = make("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 15),
	Size = UDim2.fromOffset(132, 24),
	BackgroundTransparency = 1,
	Text = "04:32 left",
	TextColor3 = Color3.fromRGB(255, 221, 130),
	TextScaled = false,
	TextSize = 14,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 12,
}, limitedCard)
_ = limitedTimer

local limitedBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 45),
	Size = UDim2.fromOffset(132, 34),
	BackgroundColor3 = Color3.fromRGB(49, 38, 69),
	Text = "LOCKED",
	TextColor3 = Color3.fromRGB(190, 174, 210),
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = false,
	Active = false,
	ZIndex = 12,
}, limitedCard)
addCorner(limitedBtn, 10)

sectionLabel("PACKS", 6)

local packGrid = make("Frame", {
	LayoutOrder = 7,
	Size = UDim2.new(1, 0, 0, 158),
	BackgroundTransparency = 1,
	ZIndex = 11,
}, content)

local gridLayout = make("UIGridLayout", {
	CellPadding = UDim2.fromOffset(10, 10),
	CellSize = UDim2.new(0.5, -5, 0, 74),
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
		Size = UDim2.new(1, -66, 0, 18),
		Text = packDef and packDef.displayName or packId,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 13,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, card)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 0, 31),
		Size = UDim2.new(1, -66, 0, 30),
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
end

local futureCard = make("Frame", {
	LayoutOrder = 8,
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

local function setProgress(fill, percent)
	local target = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
	TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = target,
	}):Play()
end

local function updateFreePackBtn()
	local progress = 1 - (math.clamp(freePackRemaining, 0, Constants.FreePackCooldown) / Constants.FreePackCooldown)
	if canClaimFree then
		progress = 1
	end
	setProgress(freeProgressFill, progress)

	if canClaimFree then
		freeClaimBtn.Text = "CLAIM FREE PACK"
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(34, 155, 70)
		freeClaimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		freeClaimBtn.Active = true
		freeSubLabel.Text = "Ready now - opens a Gold Pack"
		freeSubLabel.TextColor3 = Color3.fromRGB(97, 238, 125)
		freeStatusLabel.Text = "READY"
		freeStatusLabel.TextColor3 = Color3.fromRGB(97, 238, 125)
		freeStroke.Transparency = 0.18
	elseif freePackRemaining <= 60 then
		freeClaimBtn.Text = "READY IN " .. formatClock(freePackRemaining)
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(41, 53, 38)
		freeClaimBtn.TextColor3 = Color3.fromRGB(222, 255, 218)
		freeClaimBtn.Active = false
		freeSubLabel.Text = "Nearly ready"
		freeSubLabel.TextColor3 = Color3.fromRGB(216, 255, 190)
		freeStatusLabel.Text = "UNDER 1 MIN"
		freeStatusLabel.TextColor3 = Color3.fromRGB(216, 255, 190)
		freeStroke.Transparency = 0.25
	else
		freeClaimBtn.Text = "READY IN " .. formatClock(freePackRemaining)
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		freeClaimBtn.TextColor3 = UI.Muted
		freeClaimBtn.Active = false
		freeSubLabel.Text = "One free pull every 4 hours"
		freeSubLabel.TextColor3 = UI.Muted
		freeStatusLabel.Text = math.floor(progress * 100) .. "% filled"
		freeStatusLabel.TextColor3 = UI.Muted
		freeStroke.Transparency = 0.56
	end
end

local function updateDailyCells(nextIndex)
	local cycleProgress = dailyRewardStreak % math.max(1, #DAILY_REWARDS)
	if not canClaimDaily and cycleProgress == 0 and dailyRewardStreak > 0 then
		cycleProgress = #DAILY_REWARDS
	end

	for index, cell in ipairs(dailyCells) do
		local claimed = index <= cycleProgress
		local isNext = index == nextIndex and canClaimDaily

		if claimed then
			cell.frame.BackgroundColor3 = cell.color:Lerp(Color3.fromRGB(0, 0, 0), 0.62)
			cell.stroke.Transparency = 0.2
			cell.dayLabel.Text = "DAY " .. tostring(index) .. " DONE"
			cell.packLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		elseif isNext then
			cell.frame.BackgroundColor3 = cell.color:Lerp(Color3.fromRGB(14, 18, 31), 0.48)
			cell.stroke.Transparency = 0.05
			cell.dayLabel.Text = "DAY " .. tostring(index) .. " NEXT"
			cell.packLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			cell.frame.BackgroundColor3 = Color3.fromRGB(19, 24, 39)
			cell.stroke.Transparency = 0.72
			cell.dayLabel.Text = "DAY " .. tostring(index)
			cell.packLabel.TextColor3 = UI.Muted
		end
	end
end

local function updateDailyBtn()
	local reward, nextIndex = getNextDailyReward()
	local rewardName = reward and (reward.label or packDisplayName(reward.packId)) or "Reward Pack"

	updateDailyCells(nextIndex)

	if canClaimDaily then
		dailyClaimBtn.Text = "CLAIM DAY " .. tostring(nextIndex)
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(151, 108, 9)
		dailyClaimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		dailyClaimBtn.Active = true
		dailySubLabel.Text = "Queues " .. rewardName .. " for your next pack spawn"
		dailySubLabel.TextColor3 = UI.Gold
		dailyStroke.Transparency = 0.18
	else
		dailyClaimBtn.Text = "READY IN " .. formatClock(dailyRemaining)
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		dailyClaimBtn.TextColor3 = UI.Muted
		dailyClaimBtn.Active = false
		dailySubLabel.Text = "Come back tomorrow for Day " .. tostring(nextIndex) .. ": " .. rewardName
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
