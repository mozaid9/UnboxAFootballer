local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils     = require(Shared:WaitForChild("Utils"))

local OpenRebirthUIEvent = Remotes:WaitForChild("OpenRebirthUI")
local RequestRebirthFn   = Remotes:WaitForChild("RequestRebirth")

local UI            = Constants.UI
local RarityStyles  = Constants.RarityStyles

-- ── helpers ──────────────────────────────────────────────────────────────────

local function make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function addCorner(parent, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function addStroke(parent, color, thickness, transp)
	make("UIStroke", {
		Color = color or Color3.fromRGB(255,255,255),
		Thickness = thickness or 1.5,
		Transparency = transp or 0,
	}, parent)
end

local function makeLabel(props, parent)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or UI.Text
	props.TextScaled = props.TextScaled ~= false
	return make("TextLabel", props, parent)
end

local function fmt(n)
	return Utils.FormatNumber(n)
end

-- ── screen gui ───────────────────────────────────────────────────────────────

local existingGui = playerGui:FindFirstChild("RebirthUI")
if existingGui then existingGui:Destroy() end

local screenGui = make("ScreenGui", {
	Name          = "RebirthUI",
	ResetOnSpawn  = false,
	Enabled       = true,
	DisplayOrder  = 50,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- Dim backdrop
local dimmer = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 1,
}, screenGui)

-- Main panel
local panel = make("Frame", {
	Visible          = false,
	AnchorPoint      = Vector2.new(0.5, 0.5),
	Position         = UDim2.fromScale(0.5, 0.5),
	Size             = UDim2.new(0, 400, 0, 560),
	BackgroundColor3 = UI.Panel,
	ClipsDescendants = true,
	ZIndex           = 2,
}, screenGui)
addCorner(panel, 16)
addStroke(panel, Color3.fromRGB(130, 55, 240), 2, 0.15)

make("UISizeConstraint", {
	MinSize = Vector2.new(300, 420),
	MaxSize = Vector2.new(460, 640),
}, panel)

-- Purple/gold gradient header bar
local headerBar = make("Frame", {
	Size = UDim2.new(1, 0, 0, 64),
	BackgroundColor3 = Color3.fromRGB(18, 12, 36),
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)
addCorner(headerBar, 16) -- top corners only; bottom is hidden under content

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(90, 30, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 15, 120)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(120, 60, 20)),
	}),
	Rotation = 90,
}, headerBar)

-- Title
makeLabel({
	Text = "⚡  REBIRTH",
	Size = UDim2.new(1, -80, 0, 36),
	Position = UDim2.new(0, 16, 0, 8),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(255, 230, 90),
	TextSize = 24,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, headerBar)

local tierSubtitle = makeLabel({
	Text = "Tier 0  →  Tier 1",
	Size = UDim2.new(1, -80, 0, 20),
	Position = UDim2.new(0, 18, 0, 40),
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(200, 180, 255),
	TextSize = 14,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, headerBar)

-- Close button
local closeBtn = make("TextButton", {
	Text = "✕",
	Size = UDim2.new(0, 38, 0, 38),
	Position = UDim2.new(1, -46, 0, 12),
	BackgroundColor3 = Color3.fromRGB(180, 60, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	ZIndex = 5,
}, headerBar)
addCorner(closeBtn, 8)

-- ── Scrollable content area ───────────────────────────────────────────────────
local scroll = make("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -64),
	Position = UDim2.new(0, 0, 0, 64),
	BackgroundTransparency = 1,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Color3.fromRGB(130, 55, 240),
	ZIndex = 2,
}, panel)

local listLayout = make("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 12),
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, scroll)

make("UIPadding", {
	PaddingTop    = UDim.new(0, 14),
	PaddingBottom = UDim.new(0, 14),
	PaddingLeft   = UDim.new(0, 16),
	PaddingRight  = UDim.new(0, 16),
}, scroll)

-- ── Section factory ───────────────────────────────────────────────────────────
local function section(labelText, layoutOrder, heightHint)
	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, heightHint or 80),
		BackgroundColor3 = UI.PanelAlt,
		LayoutOrder = layoutOrder,
		ZIndex = 3,
	}, scroll)
	addCorner(frame, 10)
	makeLabel({
		Text = labelText,
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 10, 0, 8),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(180, 160, 240),
		TextSize = 12,
		TextScaled = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, frame)
	return frame
end

-- ── 1. FANS section ────────────────────────────────────────────────────────────
local fansSection = section("FANS REQUIRED", 1, 86)

local fansCountLabel = makeLabel({
	Text = "0 / 1,000,000",
	Size = UDim2.new(1, -16, 0, 20),
	Position = UDim2.new(0, 10, 0, 30),
	Font = Enum.Font.GothamBold,
	TextColor3 = UI.Text,
	TextSize = 14,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, fansSection)

local barBg = make("Frame", {
	Size = UDim2.new(1, -16, 0, 12),
	Position = UDim2.new(0, 8, 0, 54),
	BackgroundColor3 = Color3.fromRGB(28, 22, 48),
	BorderSizePixel = 0,
	ZIndex = 4,
}, fansSection)
addCorner(barBg, 6)

local barFill = make("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(130, 55, 240),
	BorderSizePixel = 0,
	ZIndex = 5,
}, barBg)
addCorner(barFill, 6)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(100, 40, 200)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(210, 130, 255)),
	}),
	Rotation = 0,
}, barFill)

local fansCheckLabel = makeLabel({
	Text = "",
	Size = UDim2.new(0, 24, 0, 20),
	Position = UDim2.new(1, -28, 0, 30),
	Font = Enum.Font.GothamBlack,
	TextSize = 16,
	TextScaled = false,
	ZIndex = 4,
}, fansSection)

-- ── 2. REQUIRED PLAYERS section ───────────────────────────────────────────────
local cardSection = section("REQUIRED PLAYERS", 2, 90)

-- Card requirement slot (built dynamically in populate())
local cardSlotContainer = make("Frame", {
	Size = UDim2.new(1, -16, 0, 52),
	Position = UDim2.new(0, 8, 0, 30),
	BackgroundTransparency = 1,
	ZIndex = 4,
}, cardSection)

local cardSlotFrame = make("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(30, 22, 50),
	ZIndex = 4,
}, cardSlotContainer)
addCorner(cardSlotFrame, 8)

local cardSlotIcon = makeLabel({
	Text = "?",
	Size = UDim2.new(0, 46, 1, -8),
	Position = UDim2.new(0, 4, 0, 4),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(120, 100, 160),
	TextSize = 22,
	TextScaled = false,
	BackgroundColor3 = Color3.fromRGB(22, 16, 38),
	BackgroundTransparency = 0,
	ZIndex = 5,
}, cardSlotFrame)
addCorner(cardSlotIcon, 6)

local cardSlotName = makeLabel({
	Text = "Not owned",
	Size = UDim2.new(1, -60, 0, 22),
	Position = UDim2.new(0, 56, 0, 5),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(150, 130, 190),
	TextSize = 13,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, cardSlotFrame)

local cardSlotCount = makeLabel({
	Text = "0 / 1",
	Size = UDim2.new(1, -60, 0, 18),
	Position = UDim2.new(0, 56, 0, 28),
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(130, 110, 170),
	TextSize = 12,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, cardSlotFrame)

local cardSlotCheck = makeLabel({
	Text = "",
	Size = UDim2.new(0, 28, 1, -8),
	Position = UDim2.new(1, -32, 0, 4),
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextScaled = false,
	ZIndex = 5,
}, cardSlotFrame)

-- ── 3. LOSE / GAIN section ────────────────────────────────────────────────────
local infoSection = section("REBIRTH INFO", 3, 100)

makeLabel({
	Text = "⚠  You will LOSE all fans and inventory cards",
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 10, 0, 30),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(235, 100, 80),
	TextSize = 12,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	ZIndex = 4,
}, infoSection)

local gainMultiplierLabel = makeLabel({
	Text = "✅  Fan multiplier: 1.0× → 1.2×",
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 10, 0, 54),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(90, 200, 130),
	TextSize = 12,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, infoSection)

local gainSlotsLabel = makeLabel({
	Text = "✅  Display slots: 6 → 7",
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 10, 0, 74),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(90, 200, 130),
	TextSize = 12,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, infoSection)

-- ── 4. Status banner ──────────────────────────────────────────────────────────
local statusBanner = make("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Color3.fromRGB(35, 28, 58),
	LayoutOrder = 4,
	ZIndex = 3,
}, scroll)
addCorner(statusBanner, 10)

local statusLabel = makeLabel({
	Text = "Requirements not met",
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(200, 140, 80),
	TextSize = 15,
	TextScaled = false,
	ZIndex = 4,
}, statusBanner)

-- ── 5. Rebirth button ─────────────────────────────────────────────────────────
local rebirthBtn = make("TextButton", {
	Text = "REBIRTH NOW",
	Size = UDim2.new(1, 0, 0, 52),
	BackgroundColor3 = Color3.fromRGB(60, 40, 120),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(200, 180, 255),
	TextSize = 18,
	LayoutOrder = 5,
	AutoButtonColor = false,
	ZIndex = 3,
}, scroll)
addCorner(rebirthBtn, 12)
addStroke(rebirthBtn, Color3.fromRGB(130, 55, 240), 1.5, 0.4)

-- ── State ─────────────────────────────────────────────────────────────────────
local currentStatus = nil
local isBusy        = false

-- ── populate UI from status table ────────────────────────────────────────────
local function populate(status)
	currentStatus = status
	if not status then return end

	local tier     = status.rebirthTier or 0
	local nextTier = tier + 1
	tierSubtitle.Text = "Tier " .. tier .. "  →  Tier " .. nextTier

	-- Fans
	local curFans  = status.currentFans  or 0
	local reqFans  = status.requiredFans or 1
	local fanPct   = math.clamp(curFans / math.max(1, reqFans), 0, 1)
	fansCountLabel.Text = fmt(curFans) .. " / " .. fmt(reqFans) .. " fans"
	TweenService:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
		Size = UDim2.new(fanPct, 0, 1, 0),
	}):Play()

	local enoughFans = (curFans >= reqFans)
	fansCheckLabel.Text = enoughFans and "✅" or "❌"
	fansCheckLabel.TextColor3 = enoughFans and Color3.fromRGB(90, 210, 130) or Color3.fromRGB(220, 80, 60)

	-- Card requirement (first group, or combined if multiple)
	local cardGroups = status.cardStatus or {}
	if #cardGroups > 0 then
		local g       = cardGroups[1]
		local rarStyle = RarityStyles[g.rarity] or RarityStyles["Talisman"]
		local met      = g.met
		local example  = g.example  -- { name, rarity, id } or nil

		-- Slot background colour: grey if not met, rarity primary if met
		cardSlotFrame.BackgroundColor3 = met
			and rarStyle.dark
			or  Color3.fromRGB(30, 22, 50)

		-- Icon background + text
		cardSlotIcon.BackgroundColor3 = met
			and rarStyle.secondary
			or  Color3.fromRGB(22, 16, 38)
		cardSlotIcon.Text      = met and "★" or "?"
		cardSlotIcon.TextColor3 = met and rarStyle.primary or Color3.fromRGB(120, 100, 160)

		-- Player name
		cardSlotName.Text = met and (example and example.name or "Requirement met") or "Not owned"
		cardSlotName.TextColor3 = met and rarStyle.text or Color3.fromRGB(150, 130, 190)

		-- Count / rarity label
		cardSlotCount.Text = g.owned .. " / " .. g.needed .. "  " .. g.rarity .. "+"
		cardSlotCount.TextColor3 = met
			and rarStyle.primary
			or  Color3.fromRGB(130, 110, 170)

		-- Tick
		cardSlotCheck.Text       = met and "✅" or "❌"
		cardSlotCheck.TextColor3 = met
			and Color3.fromRGB(90, 210, 130)
			or  Color3.fromRGB(220, 80, 60)

		if met then
			addStroke(cardSlotFrame, rarStyle.primary, 1.5, 0.3)
		else
			-- Remove any existing stroke
			for _, child in ipairs(cardSlotFrame:GetChildren()) do
				if child:IsA("UIStroke") then child:Destroy() end
			end
		end
	end

	-- Gain info
	local curMult  = status.currentMultiplier or 1
	local nextMult = status.nextMultiplier    or curMult
	gainMultiplierLabel.Text = string.format("✅  Fan multiplier: %.2g×  →  %.2g×", curMult, nextMult)

	local curSlots  = status.baseSlots     or 6
	local nextSlots = status.nextBaseSlots or curSlots
	if nextSlots > curSlots then
		gainSlotsLabel.Text = "✅  Display slots: " .. curSlots .. " → " .. nextSlots
	else
		gainSlotsLabel.Text = "ℹ️  Display slots: " .. curSlots .. " (already at max)"
	end

	-- Status banner + button
	local canRebirth = status.canRebirth
	if canRebirth then
		statusBanner.BackgroundColor3 = Color3.fromRGB(15, 50, 22)
		statusLabel.Text       = "🏆  REBIRTH READY!"
		statusLabel.TextColor3 = Color3.fromRGB(100, 230, 140)

		rebirthBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		rebirthBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		for _, c in ipairs(rebirthBtn:GetChildren()) do
			if c:IsA("UIStroke") then c.Color = Color3.fromRGB(60, 220, 110) end
		end
	else
		statusBanner.BackgroundColor3 = Color3.fromRGB(50, 25, 18)
		statusLabel.Text       = status.reason or "Requirements not met"
		statusLabel.TextColor3 = Color3.fromRGB(200, 100, 70)

		rebirthBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
		rebirthBtn.TextColor3       = Color3.fromRGB(140, 120, 180)
		for _, c in ipairs(rebirthBtn:GetChildren()) do
			if c:IsA("UIStroke") then c.Color = Color3.fromRGB(100, 70, 160) end
		end
	end
end

-- ── open / close ──────────────────────────────────────────────────────────────
local function openUI(status)
	populate(status)
	panel.Visible  = true
	dimmer.Visible = true

	panel.Size = UDim2.new(0, 360, 0, 500)
	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 560),
	}):Play()
	TweenService:Create(dimmer, TweenInfo.new(0.18), {
		BackgroundTransparency = 0.5,
	}):Play()
end

local function closeUI()
	TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 360, 0, 500),
	}):Play()
	TweenService:Create(dimmer, TweenInfo.new(0.16), {
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.18, function()
		panel.Visible  = false
		dimmer.Visible = false
	end)
end

-- ── button handlers ───────────────────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(closeUI)
dimmer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		closeUI()
	end
end)

rebirthBtn.MouseButton1Click:Connect(function()
	if isBusy then return end
	if not currentStatus or not currentStatus.canRebirth then return end

	isBusy = true
	rebirthBtn.Text = "Rebirthing…"
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 55)

	local ok, result = pcall(function()
		return RequestRebirthFn:InvokeServer()
	end)

	isBusy = false

	if ok and result and result.success then
		-- Refresh status from the returned status table
		populate(result.status)
		closeUI()
	else
		local errMsg = (ok and result and result.error) or "Something went wrong."
		rebirthBtn.Text = errMsg
		task.delay(2.5, function()
			rebirthBtn.Text = "REBIRTH NOW"
			populate(currentStatus)
		end)
	end
end)

-- Hover effects on rebirth button
rebirthBtn.MouseEnter:Connect(function()
	if currentStatus and currentStatus.canRebirth and not isBusy then
		TweenService:Create(rebirthBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(55, 210, 105),
		}):Play()
	end
end)
rebirthBtn.MouseLeave:Connect(function()
	if currentStatus and currentStatus.canRebirth and not isBusy then
		TweenService:Create(rebirthBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(40, 180, 90),
		}):Play()
	end
end)

-- ── listen for server trigger ─────────────────────────────────────────────────
OpenRebirthUIEvent.OnClientEvent:Connect(function(status)
	openUI(status)
end)
