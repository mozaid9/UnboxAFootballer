local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local ClaimFreePackFn = Remotes:WaitForChild("ClaimFreePack")
local ClaimDailyRewardFn = Remotes:WaitForChild("ClaimDailyReward")

local UI = Constants.UI

-- ── Helpers ────────────────────────────────────────────────────────────────────

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
end

local function addStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────

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

-- BindableEvent so PackOpeningUI can toggle us via fireGuiToggle("ShopUI")
local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

-- ── State ─────────────────────────────────────────────────────────────────────

local isOpen = false
local freePackRemaining = Constants.FreePackCooldown
local dailyRemaining = Constants.DailyRewardCooldown
local canClaimFree = false
local canClaimDaily = false
local claimingFree = false
local claimingDaily = false

-- ── Dark overlay ───────────────────────────────────────────────────────────────

local overlay = make("Frame", {
	Name = "Overlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.42,
	ZIndex = 1,
}, screenGui)

-- Clicking outside the panel closes the Shop
local overlayBtn = make("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	ZIndex = 2,
}, overlay)

-- ── Main panel ────────────────────────────────────────────────────────────────

local PANEL_W, PANEL_H = 430, 380

local panel = make("Frame", {
	Name = "ShopPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(PANEL_W, PANEL_H),
	BackgroundColor3 = UI.Background,
	ZIndex = 10,
}, screenGui)
addCorner(panel, 18)
addStroke(panel, UI.Gold, 1.5, 0.52)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 20, 38)),
		ColorSequenceKeypoint.new(1, UI.Background),
	}),
	Rotation = 130,
}, panel)

-- ── Header ───────────────────────────────────────────────────────────────────

local header = make("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = Color3.fromRGB(10, 14, 27),
	ZIndex = 11,
}, panel)
addCorner(header, 18)

-- Solid rectangle covers only the bottom two rounded corners so the top stays curved
make("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundColor3 = Color3.fromRGB(10, 14, 27),
	BorderSizePixel = 0,
	ZIndex = 11,
}, header)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 18, 0, 0),
	Size = UDim2.new(1, -60, 1, 0),
	Text = "SHOP",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 22,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
}, header)

local closeBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = UI.Danger,
	Text = "✕",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
	ZIndex = 12,
}, header)
addCorner(closeBtn, 10)

-- ── Content area ─────────────────────────────────────────────────────────────

local content = make("Frame", {
	Name = "Content",
	Position = UDim2.new(0, 0, 0, 54),
	Size = UDim2.new(1, 0, 1, -54),
	BackgroundTransparency = 1,
	ZIndex = 10,
}, panel)

make("UIPadding", {
	PaddingTop = UDim.new(0, 14),
	PaddingBottom = UDim.new(0, 14),
	PaddingLeft = UDim.new(0, 14),
	PaddingRight = UDim.new(0, 14),
}, content)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

-- Section label
make("TextLabel", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	Text = "FREE REWARDS",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
}, content)

-- ── Reward card helper ────────────────────────────────────────────────────────

local function makeRewardCard(layoutOrder, iconText, iconColor, titleText, subtitleDefault)
	local card = make("Frame", {
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, 82),
		BackgroundColor3 = UI.Panel,
		ZIndex = 11,
	}, content)
	addCorner(card, 14)
	addStroke(card, iconColor, 1.5, 0.72)

	-- Left accent bar
	make("Frame", {
		Size = UDim2.new(0, 4, 1, -16),
		Position = UDim2.new(0, 0, 0, 8),
		BackgroundColor3 = iconColor,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, card)
	addCorner(card:FindFirstChildOfClass("Frame"), 4)

	-- Icon circle
	local iconCircle = make("Frame", {
		Position = UDim2.new(0, 14, 0.5, -22),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.70),
		ZIndex = 12,
	}, card)
	addCorner(iconCircle, 22)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = iconText,
		TextColor3 = iconColor,
		TextScaled = false,
		TextSize = 22,
		Font = Enum.Font.GothamBlack,
		ZIndex = 13,
	}, iconCircle)

	-- Title
	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0, 15),
		Size = UDim2.new(1, -220, 0, 22),
		Text = titleText,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 16,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, card)

	-- Subtitle (mutable)
	local subLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0, 38),
		Size = UDim2.new(1, -220, 0, 17),
		Text = subtitleDefault,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, card)

	-- Action button (right side)
	local btn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(136, 38),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.32),
		Text = "CLAIM",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 14,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = true,
		ZIndex = 12,
	}, card)
	addCorner(btn, 10)

	return card, subLabel, btn
end

local _, freeSubLabel, freeClaimBtn =
	makeRewardCard(2, "F", Color3.fromRGB(74, 185, 98), "FREE PACK", "One Gold Pack pull  ·  4 h cooldown")

local _, dailySubLabel, dailyClaimBtn =
	makeRewardCard(3, "D", UI.Gold, "DAILY REWARD", "+1,000 Fans  ·  24 h cooldown")

-- Coming-soon footer
local comingSoon = make("TextLabel", {
	LayoutOrder = 4,
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = UI.PanelAlt,
	Text = "Premium packs · Cosmetics · More  —  coming soon",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamMedium,
	ZIndex = 11,
}, content)
addCorner(comingSoon, 10)
addStroke(comingSoon, UI.Muted, 1, 0.90)
_ = comingSoon

-- ── Button state helper ────────────────────────────────────────────────────────

local function updateFreePackBtn()
	if canClaimFree then
		freeClaimBtn.Text = "CLAIM FREE PACK"
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 65)
		freeClaimBtn.Active = true
		freeClaimBtn.AutoButtonColor = true
		freeSubLabel.Text = "One Gold Pack pull  ·  Ready now!"
		freeSubLabel.TextColor3 = Color3.fromRGB(74, 185, 98)
	else
		freeClaimBtn.Text = Utils.FormatCountdown(freePackRemaining)
		freeClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		freeClaimBtn.Active = false
		freeClaimBtn.AutoButtonColor = false
		freeSubLabel.Text = "Next free pack in " .. Utils.FormatCountdown(freePackRemaining)
		freeSubLabel.TextColor3 = UI.Muted
	end
end

local function updateDailyBtn()
	if canClaimDaily then
		dailyClaimBtn.Text = "CLAIM  +1,000"
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(140, 100, 10)
		dailyClaimBtn.Active = true
		dailyClaimBtn.AutoButtonColor = true
		dailySubLabel.Text = "+1,000 Fans  ·  Ready to collect!"
		dailySubLabel.TextColor3 = UI.Gold
	else
		dailyClaimBtn.Text = Utils.FormatCountdown(dailyRemaining)
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		dailyClaimBtn.Active = false
		dailyClaimBtn.AutoButtonColor = false
		dailySubLabel.Text = "Claimed on login · Next in " .. Utils.FormatCountdown(dailyRemaining)
		dailySubLabel.TextColor3 = UI.Muted
	end
end

-- ── Populate from server data ─────────────────────────────────────────────────

local function applyData(data)
	if not data then
		return
	end

	freePackRemaining = data.freePackRemaining or Constants.FreePackCooldown
	canClaimFree = data.canClaimFreePack == true

	dailyRemaining = data.dailyRewardRemaining or Constants.DailyRewardCooldown
	canClaimDaily = data.canClaimDailyReward == true

	updateFreePackBtn()
	updateDailyBtn()
end

-- ── Live countdown loop (runs while panel is open) ────────────────────────────

local function runCountdown()
	while isOpen and screenGui.Enabled do
		task.wait(1)
		if not isOpen then
			break
		end

		-- Decrement locally between server refreshes
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

-- ── Open / close ──────────────────────────────────────────────────────────────

local panelScale = make("UIScale", { Scale = 0.88 }, panel)

local function openShop()
	if isOpen then
		return
	end
	isOpen = true
	screenGui.Enabled = true

	-- Fetch fresh state from server
	task.spawn(function()
		local data = GetPlayerDataFn:InvokeServer()
		if isOpen then
			applyData(data)
		end
	end)

	-- Pop-in animation
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

-- ── Wire buttons ──────────────────────────────────────────────────────────────

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

-- ── Free Pack claim ───────────────────────────────────────────────────────────

freeClaimBtn.MouseButton1Click:Connect(function()
	if not canClaimFree or claimingFree then
		return
	end
	claimingFree = true
	freeClaimBtn.Text = "Opening..."
	freeClaimBtn.Active = false

	local result = ClaimFreePackFn:InvokeServer()
	claimingFree = false

	if result and result.success then
		-- PackOpenedEvent fires server-side → card reveal appears automatically.
		-- Reset our local timer so the button shows the new cooldown immediately.
		canClaimFree = false
		freePackRemaining = result.freePackRemaining or Constants.FreePackCooldown
		updateFreePackBtn()
		-- Close the shop so the card reveal is unobstructed
		closeShop()
	else
		-- Show error briefly on the button then restore
		freeClaimBtn.Text = result and result.error or "Error"
		task.delay(2, function()
			if not canClaimFree then
				updateFreePackBtn()
			end
		end)
	end
end)

-- ── Daily Reward claim ────────────────────────────────────────────────────────

dailyClaimBtn.MouseButton1Click:Connect(function()
	if not canClaimDaily or claimingDaily then
		return
	end
	claimingDaily = true
	dailyClaimBtn.Text = "Claiming..."
	dailyClaimBtn.Active = false

	local result = ClaimDailyRewardFn:InvokeServer()
	claimingDaily = false

	if result and result.success then
		canClaimDaily = false
		dailyRemaining = result.dailyRewardRemaining or Constants.DailyRewardCooldown
		updateDailyBtn()

		-- Brief green flash on the button to celebrate
		dailyClaimBtn.Text = "+1,000 Fans!"
		dailyClaimBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 65)
		task.delay(1.8, function()
			if not canClaimDaily then
				updateDailyBtn()
			end
		end)
	else
		dailyClaimBtn.Text = result and result.error or "Error"
		task.delay(2, function()
			if not canClaimDaily then
				updateDailyBtn()
			end
		end)
	end
end)
