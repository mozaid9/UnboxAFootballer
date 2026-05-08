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
local REBIRTH_PURPLE = Color3.fromRGB(158, 78, 255)
local REBIRTH_GOLD = Color3.fromRGB(255, 211, 78)
local REBIRTH_GREEN = Color3.fromRGB(83, 214, 128)
local REBIRTH_RED = Color3.fromRGB(232, 88, 82)

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
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
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
	Position         = UDim2.fromScale(0.5, 0.44),
	Size             = UDim2.new(0, 560, 0, 540),
	BackgroundColor3 = UI.Panel,
	ClipsDescendants = true,
	ZIndex           = 2,
}, screenGui)
addCorner(panel, 16)
addStroke(panel, REBIRTH_PURPLE, 2, 0.15)

make("UISizeConstraint", {
	MinSize = Vector2.new(360, 440),
	MaxSize = Vector2.new(600, 620),
}, panel)

-- Purple/gold gradient header bar
local headerBar = make("Frame", {
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundColor3 = Color3.fromRGB(18, 12, 36),
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)
addCorner(headerBar, 16) -- top corners only; bottom is hidden under content

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(9, 7, 18)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(23, 12, 46)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 42, 16)),
	}),
	Rotation = 90,
}, headerBar)

-- Title
makeLabel({
	Text = "REBIRTH",
	Size = UDim2.new(1, -80, 0, 36),
	Position = UDim2.new(0, 16, 0, 6),
	Font = Enum.Font.GothamBlack,
	TextColor3 = REBIRTH_GOLD,
	TextSize = 24,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, headerBar)

local tierSubtitle = makeLabel({
	Text = "Tier 0  →  Tier 1",
	Size = UDim2.new(1, -80, 0, 20),
	Position = UDim2.new(0, 18, 0, 38),
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(200, 180, 255),
	TextSize = 14,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, headerBar)

local headerBadge = makeLabel({
	Text = "PERMANENT BOOST",
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.new(0, 142, 0, 26),
	Position = UDim2.new(1, -62, 0, 22),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(20, 15, 8),
	TextSize = 11,
	TextScaled = false,
	BackgroundColor3 = REBIRTH_GOLD,
	BackgroundTransparency = 0,
	ZIndex = 4,
}, headerBar)
addCorner(headerBadge, 13)

-- Close button
local closeBtn = make("TextButton", {
	Text = "X",
	Size = UDim2.new(0, 38, 0, 38),
	Position = UDim2.new(1, -46, 0, 16),
	BackgroundColor3 = Color3.fromRGB(180, 60, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	ZIndex = 5,
}, headerBar)
addCorner(closeBtn, 8)

-- ── Scrollable content area ───────────────────────────────────────────────────
local scroll = make("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -190),
	Position = UDim2.new(0, 0, 0, 70),
	BackgroundTransparency = 1,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = REBIRTH_PURPLE,
	ZIndex = 2,
}, panel)

local listLayout = make("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, scroll)

make("UIPadding", {
	PaddingTop    = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft   = UDim.new(0, 16),
	PaddingRight  = UDim.new(0, 16),
}, scroll)

-- ── Section factory ───────────────────────────────────────────────────────────
local function section(labelText, layoutOrder, heightHint)
	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, heightHint or 80),
		BackgroundColor3 = UI.PanelAlt,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		ZIndex = 3,
	}, scroll)
	addCorner(frame, 12)
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
local fansSection = section("FANS CHECK", 1, 72)

local fansCountLabel = makeLabel({
	Text = "0 / 1,000,000",
	Size = UDim2.new(1, -72, 0, 24),
	Position = UDim2.new(0, 10, 0, 25),
	Font = Enum.Font.GothamBold,
	TextColor3 = UI.Text,
	TextSize = 15,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, fansSection)

local barBg = make("Frame", {
	Size = UDim2.new(1, -16, 0, 12),
	Position = UDim2.new(0, 8, 0, 52),
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
		ColorSequenceKeypoint.new(0,   REBIRTH_PURPLE),
		ColorSequenceKeypoint.new(1,   REBIRTH_GOLD),
	}),
	Rotation = 0,
}, barFill)

local fansCheckLabel = makeLabel({
	Text = "",
	Size = UDim2.new(0, 42, 0, 34),
	Position = UDim2.new(1, -52, 0, 20),
	Font = Enum.Font.GothamBlack,
	TextSize = 28,
	TextScaled = false,
	ZIndex = 4,
}, fansSection)

-- ── 2. REQUIRED PLAYERS section ───────────────────────────────────────────────
-- Height auto-expands via AutomaticSize so multiple card slots fit cleanly.
local cardSection = section("PLAYER CHECK", 2, 36)
cardSection.AutomaticSize = Enum.AutomaticSize.Y

-- Dynamic container — rows are created/destroyed in populate()
local cardSlotContainer = make("Frame", {
	Size = UDim2.new(1, -16, 0, 0),
	Position = UDim2.new(0, 8, 0, 30),
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 4,
}, cardSection)

make("UIListLayout", {
	SortOrder        = Enum.SortOrder.LayoutOrder,
	Padding          = UDim.new(0, 6),
	FillDirection    = Enum.FillDirection.Vertical,
}, cardSlotContainer)

make("UIPadding", { PaddingBottom = UDim.new(0, 8) }, cardSection)

-- ── 3. LOSE / GAIN section ────────────────────────────────────────────────────
local infoSection = section("WHAT CHANGES", 3, 160)

local function changeRow(y, accent, iconText, titleText, bodyText)
	local row = make("Frame", {
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.new(0, 8, 0, y),
		BackgroundColor3 = Color3.fromRGB(12, 14, 24),
		BorderSizePixel = 0,
		ZIndex = 4,
	}, infoSection)
	addCorner(row, 9)
	addStroke(row, accent, 1, 0.72)

	makeLabel({
		Text = iconText,
		Size = UDim2.new(0, 24, 1, 0),
		Position = UDim2.new(0, 7, 0, 0),
		Font = Enum.Font.GothamBlack,
		TextColor3 = accent,
		TextSize = 15,
		TextScaled = false,
		ZIndex = 5,
	}, row)

	makeLabel({
		Text = titleText,
		Size = UDim2.new(0.38, -16, 1, 0),
		Position = UDim2.new(0, 34, 0, 0),
		Font = Enum.Font.GothamBlack,
		TextColor3 = UI.Text,
		TextSize = 11,
		TextScaled = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, row)

	local body = makeLabel({
		Text = bodyText,
		Size = UDim2.new(0.62, -34, 1, 0),
		Position = UDim2.new(0.38, 10, 0, 0),
		Font = Enum.Font.GothamBold,
		TextColor3 = accent,
		TextSize = 11,
		TextScaled = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, row)

	return body
end

changeRow(29, REBIRTH_RED, "!", "RESETS", "Fans + non-vaulted inventory")
local gainMultiplierLabel = changeRow(57, REBIRTH_GREEN, "+", "MULTIPLIER", "1.0x -> 1.2x")
local gainSlotsLabel = changeRow(85, REBIRTH_GOLD, "+", "DISPLAY SLOTS", "6 -> 7")
local vaultSlotsLabel = changeRow(113, Color3.fromRGB(125, 208, 255), "i", "VAULT", "Unlocks at Rebirth 3")

local startingFansLabel = makeLabel({
	Text = "START AFTER REBIRTH: 5,000 FANS",
	Size = UDim2.new(1, -16, 0, 18),
	Position = UDim2.new(0, 8, 0, 140),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(22, 16, 8),
	TextSize = 10,
	TextScaled = false,
	BackgroundColor3 = REBIRTH_GOLD,
	BackgroundTransparency = 0,
	ZIndex = 5,
}, infoSection)
addCorner(startingFansLabel, 10)

-- ── 4. Status banner ──────────────────────────────────────────────────────────
local footer = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -32),
	Size = UDim2.new(1, -32, 0, 88),
	BackgroundTransparency = 1,
	ZIndex = 6,
}, panel)

local statusBanner = make("Frame", {
	Position = UDim2.new(0, 0, 0, 52),
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = Color3.fromRGB(35, 28, 58),
	BorderSizePixel = 0,
	ZIndex = 6,
}, footer)
addCorner(statusBanner, 10)

local statusLabel = makeLabel({
	Text = "Requirements not met",
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(200, 140, 80),
	TextSize = 12,
	TextScaled = false,
	TextWrapped = true,
	ZIndex = 7,
}, statusBanner)

-- ── 5. Rebirth button ─────────────────────────────────────────────────────────
local rebirthBtn = make("TextButton", {
	Text = "REBIRTH NOW",
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = Color3.fromRGB(60, 40, 120),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(200, 180, 255),
	TextSize = 16,
	AutoButtonColor = false,
	ZIndex = 6,
}, footer)
addCorner(rebirthBtn, 12)
addStroke(rebirthBtn, REBIRTH_PURPLE, 1.5, 0.4)

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
	fansCheckLabel.Text = enoughFans and "OK" or "X"
	fansCheckLabel.TextColor3 = enoughFans and REBIRTH_GREEN or REBIRTH_RED

	-- Card requirements — one row per required slot so "need 2 Immortals"
	-- shows two separate rows, each named individually.
	for _, child in ipairs(cardSlotContainer:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local cardGroups = status.cardStatus or {}
	for gi, g in ipairs(cardGroups) do
		local rarStyle = RarityStyles[g.rarity] or RarityStyles["Talisman"]
		local examples = g.examples or (g.example and { g.example } or {})

		for i = 1, g.needed do
			local ex     = examples[i]          -- may be nil if slot not filled yet
			local slotMet = ex ~= nil

			local row = make("Frame", {
				Size             = UDim2.new(1, 0, 0, 50),
				BackgroundColor3 = slotMet and rarStyle.dark or Color3.fromRGB(30, 22, 50),
				BorderSizePixel  = 0,
				LayoutOrder      = (gi - 1) * 100 + i,
				ZIndex           = 4,
			}, cardSlotContainer)
			addCorner(row, 10)
			if slotMet then
				addStroke(row, rarStyle.primary, 1.5, 0.3)
			end

			-- Badge (OK / slot number)
			local badge = makeLabel({
				Text             = slotMet and "OK" or tostring(i),
				Size             = UDim2.new(0, 38, 1, -10),
				Position         = UDim2.new(0, 5, 0, 5),
				Font             = Enum.Font.GothamBlack,
				TextColor3       = slotMet and rarStyle.primary or Color3.fromRGB(120, 100, 160),
				TextSize         = 13,
				TextScaled       = false,
				BackgroundColor3 = slotMet and rarStyle.secondary or Color3.fromRGB(22, 16, 38),
				BackgroundTransparency = 0,
				ZIndex           = 5,
			}, row)
			addCorner(badge, 6)

			-- Player name
			makeLabel({
				Text             = slotMet and ex.name or ("Need " .. g.rarity .. "+"),
				Size             = UDim2.new(1, -124, 0, 24),
				Position         = UDim2.new(0, 58, 0, 5),
				Font             = Enum.Font.GothamBlack,
				TextColor3       = slotMet and rarStyle.text or Color3.fromRGB(150, 130, 190),
				TextSize         = 14,
				TextScaled       = false,
				TextXAlignment   = Enum.TextXAlignment.Left,
				ZIndex           = 5,
			}, row)

			-- Sub-label: rarity or "card N of M"
			makeLabel({
				Text           = slotMet and ex.rarity
				                 or ("Card " .. i .. " of " .. g.needed .. "  •  " .. g.rarity .. "+"),
				Size           = UDim2.new(1, -124, 0, 18),
				Position       = UDim2.new(0, 58, 0, 28),
				Font           = Enum.Font.Gotham,
				TextColor3     = slotMet and rarStyle.primary or Color3.fromRGB(130, 110, 170),
				TextSize       = 12,
				TextScaled     = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex         = 5,
			}, row)

			-- OK / X check
			makeLabel({
				Text       = slotMet and "OK" or "✗",
				Size       = UDim2.new(0, 38, 1, -10),
				Position   = UDim2.new(1, -44, 0, 5),
				Font       = Enum.Font.GothamBlack,
				TextColor3 = slotMet and REBIRTH_GREEN or REBIRTH_RED,
				TextSize   = slotMet and 18 or 24,
				TextScaled = false,
				ZIndex     = 5,
			}, row)
		end
	end

	-- Gain info
	local curMult  = status.currentMultiplier or 1
	local nextMult = status.nextMultiplier    or curMult
	gainMultiplierLabel.Text = string.format("%.2gx -> %.2gx", curMult, nextMult)

	local curSlots  = status.baseSlots     or 6
	local nextSlots = status.nextBaseSlots or curSlots
	if nextSlots > curSlots then
		gainSlotsLabel.Text = tostring(curSlots) .. " -> " .. tostring(nextSlots)
	else
		gainSlotsLabel.Text = tostring(curSlots) .. " slots (max)"
	end

	local curVaultSlots = status.vaultSlots or 0
	local nextVaultSlots = status.nextVaultSlots or curVaultSlots
	if nextVaultSlots > curVaultSlots then
		vaultSlotsLabel.Text = tostring(curVaultSlots) .. " -> " .. tostring(nextVaultSlots)
	elseif curVaultSlots > 0 then
		vaultSlotsLabel.Text = tostring(curVaultSlots) .. " slots"
	else
		vaultSlotsLabel.Text = "Unlocks at Rebirth 3"
	end

	startingFansLabel.Text = "START AFTER REBIRTH: " .. string.upper(fmt(status.startingFansAfterRebirth or 5000)) .. " FANS"

	-- Status banner + button
	local canRebirth = status.canRebirth
	rebirthBtn.Text = "REBIRTH NOW"
	if canRebirth then
		statusBanner.BackgroundColor3 = Color3.fromRGB(15, 50, 22)
		statusLabel.Text       = "REBIRTH READY"
		statusLabel.TextColor3 = REBIRTH_GREEN

		rebirthBtn.BackgroundColor3 = REBIRTH_GREEN
		rebirthBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		for _, c in ipairs(rebirthBtn:GetChildren()) do
			if c:IsA("UIStroke") then c.Color = Color3.fromRGB(60, 220, 110) end
		end
	else
		statusBanner.BackgroundColor3 = Color3.fromRGB(50, 25, 18)
		statusLabel.Text       = status.reason or "Requirements not met"
		statusLabel.TextColor3 = Color3.fromRGB(225, 130, 94)

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

	panel.Size = UDim2.new(0, 510, 0, 500)
	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 560, 0, 540),
	}):Play()
	TweenService:Create(dimmer, TweenInfo.new(0.18), {
		BackgroundTransparency = 0.52,
	}):Play()
end

local function closeUI()
	TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 510, 0, 500),
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
			BackgroundColor3 = Color3.fromRGB(98, 230, 144),
		}):Play()
	end
end)
rebirthBtn.MouseLeave:Connect(function()
	if currentStatus and currentStatus.canRebirth and not isBusy then
		TweenService:Create(rebirthBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = REBIRTH_GREEN,
		}):Play()
	end
end)

-- ── listen for server trigger ─────────────────────────────────────────────────
OpenRebirthUIEvent.OnClientEvent:Connect(function(status)
	openUI(status)
end)
