local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local OpenRebirthVaultUIEvent = Remotes:WaitForChild("OpenRebirthVaultUI")
local GetRebirthVaultFn = Remotes:WaitForChild("GetRebirthVault")
local SetRebirthVaultFn = Remotes:WaitForChild("SetRebirthVault")

local UI = Constants.UI
local RarityStyles = Constants.RarityStyles

local function make(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function addCorner(parent, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function addStroke(parent, color, thickness, transparency)
	make("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	}, parent)
end

local function makeLabel(props, parent)
	props.BackgroundTransparency = props.BackgroundTransparency == nil and 1 or props.BackgroundTransparency
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or UI.Text
	props.TextScaled = props.TextScaled ~= false
	return make("TextLabel", props, parent)
end

local existingGui = playerGui:FindFirstChild("RebirthVaultUI")
if existingGui then
	existingGui:Destroy()
end

local screenGui = make("ScreenGui", {
	Name = "RebirthVaultUI",
	ResetOnSpawn = false,
	Enabled = true,
	DisplayOrder = 52,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local dimmer = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 1,
}, screenGui)

local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 460, 0, 610),
	BackgroundColor3 = UI.Panel,
	Visible = false,
	ClipsDescendants = true,
	ZIndex = 2,
}, screenGui)
addCorner(panel, 16)
addStroke(panel, Color3.fromRGB(90, 215, 255), 2, 0.12)
make("UISizeConstraint", {
	MinSize = Vector2.new(320, 460),
	MaxSize = Vector2.new(520, 680),
}, panel)

local header = make("Frame", {
	Size = UDim2.new(1, 0, 0, 78),
	BackgroundColor3 = Color3.fromRGB(8, 16, 32),
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)
addCorner(header, 16)
make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 70, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 42)),
	}),
	Rotation = 90,
}, header)

makeLabel({
	Text = "REBIRTH VAULT",
	Size = UDim2.new(1, -78, 0, 34),
	Position = UDim2.new(0, 18, 0, 10),
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(178, 245, 255),
	TextSize = 24,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, header)

local subtitle = makeLabel({
	Text = "Keep players through rebirth",
	Size = UDim2.new(1, -78, 0, 22),
	Position = UDim2.new(0, 20, 0, 44),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(220, 238, 255),
	TextSize = 13,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, header)

local closeBtn = make("TextButton", {
	Text = "X",
	Size = UDim2.new(0, 40, 0, 40),
	Position = UDim2.new(1, -50, 0, 18),
	BackgroundColor3 = Color3.fromRGB(185, 60, 64),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	AutoButtonColor = false,
	ZIndex = 5,
}, header)
addCorner(closeBtn, 8)

local status = makeLabel({
	Text = "",
	Size = UDim2.new(1, -32, 0, 42),
	Position = UDim2.new(0, 16, 0, 92),
	BackgroundColor3 = Color3.fromRGB(12, 18, 32),
	BackgroundTransparency = 0,
	TextColor3 = Color3.fromRGB(220, 238, 255),
	TextSize = 13,
	TextScaled = false,
	TextWrapped = true,
	ZIndex = 3,
}, panel)
addCorner(status, 10)

local scroll = make("ScrollingFrame", {
	Size = UDim2.new(1, -32, 1, -154),
	Position = UDim2.new(0, 16, 0, 142),
	BackgroundTransparency = 1,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = Color3.fromRGB(90, 215, 255),
	ZIndex = 3,
}, panel)

local list = make("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
}, scroll)
make("UIPadding", {
	PaddingBottom = UDim.new(0, 12),
}, scroll)

local currentPayload
local selectedIds = {}
local render

local function containsSelected(cardId)
	for _, selectedId in ipairs(selectedIds) do
		if selectedId == cardId then
			return true
		end
	end
	return false
end

local function removeSelected(cardId)
	local nextIds = {}
	for _, selectedId in ipairs(selectedIds) do
		if selectedId ~= cardId then
			table.insert(nextIds, selectedId)
		end
	end
	selectedIds = nextIds
end

local function syncSelectedFromPayload(payload)
	selectedIds = {}
	for _, card in ipairs(payload and payload.vault or {}) do
		table.insert(selectedIds, card.id)
	end
end

local function clearRows()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function makeSectionTitle(text, order)
	makeLabel({
		Text = text,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(170, 230, 255),
		TextSize = 13,
		TextScaled = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, scroll)
end

local function makeCardRow(card, order, mode)
	local rarityStyle = RarityStyles[card.rarity] or RarityStyles["Gold"]
	local disabled = mode == "displayed"
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 66),
		BackgroundColor3 = disabled and Color3.fromRGB(28, 28, 34) or Color3.fromRGB(12, 18, 32),
		LayoutOrder = order,
		ZIndex = 4,
	}, scroll)
	addCorner(row, 10)
	addStroke(row, disabled and Color3.fromRGB(80, 80, 88) or rarityStyle.primary, 1.2, disabled and 0.55 or 0.22)

	local icon = makeLabel({
		Text = string.upper(string.sub(card.name or "P", 1, 1)),
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(0, 9, 0, 9),
		BackgroundColor3 = rarityStyle.dark or Color3.fromRGB(24, 18, 8),
		BackgroundTransparency = 0,
		TextColor3 = rarityStyle.text or Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextScaled = false,
		ZIndex = 5,
	}, row)
	addCorner(icon, 8)

	makeLabel({
		Text = string.upper(card.name or "Player"),
		Size = UDim2.new(1, -190, 0, 22),
		Position = UDim2.new(0, 66, 0, 9),
		TextColor3 = disabled and Color3.fromRGB(160, 160, 168) or UI.Text,
		TextSize = 13,
		TextScaled = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, row)

	makeLabel({
		Text = (card.position or "--") .. " | " .. (card.rarity or "Card") .. " | +" .. Utils.FormatNumber(card.fansPerSecond or 0) .. "/s",
		Size = UDim2.new(1, -190, 0, 20),
		Position = UDim2.new(0, 66, 0, 34),
		TextColor3 = disabled and Color3.fromRGB(130, 130, 138) or Color3.fromRGB(190, 205, 220),
		TextSize = 11,
		TextScaled = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, row)

	local buttonText = "ADD"
	local buttonColor = Color3.fromRGB(42, 150, 90)
	if mode == "vault" then
		buttonText = "REMOVE"
		buttonColor = Color3.fromRGB(170, 72, 72)
	elseif mode == "selected" then
		buttonText = "SELECTED"
		buttonColor = Color3.fromRGB(74, 112, 150)
	elseif mode == "displayed" then
		buttonText = "ON SLOT"
		buttonColor = Color3.fromRGB(66, 66, 76)
	end

	local action = make("TextButton", {
		Text = buttonText,
		Size = UDim2.new(0, 96, 0, 36),
		Position = UDim2.new(1, -108, 0, 15),
		BackgroundColor3 = buttonColor,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		AutoButtonColor = not disabled,
		ZIndex = 5,
	}, row)
	addCorner(action, 8)

	if disabled then
		action.Active = false
	elseif mode == "vault" or mode == "selected" then
		action.MouseButton1Click:Connect(function()
			removeSelected(card.id)
			local result = SetRebirthVaultFn:InvokeServer(selectedIds)
			currentPayload = result and result.vault or currentPayload
			if result and result.error then
				status.Text = result.error
			end
			syncSelectedFromPayload(currentPayload)
			render(currentPayload)
		end)
	else
		action.MouseButton1Click:Connect(function()
			if #selectedIds >= (currentPayload.maxSlots or 0) then
				status.Text = "Vault is full. Remove a player first."
				return
			end
			table.insert(selectedIds, card.id)
			local result = SetRebirthVaultFn:InvokeServer(selectedIds)
			currentPayload = result and result.vault or currentPayload
			if result and result.error then
				status.Text = result.error
			end
			syncSelectedFromPayload(currentPayload)
			render(currentPayload)
		end)
	end
end

render = function(payload)
	currentPayload = payload
	clearRows()

	if not payload or payload.success == false then
		status.Text = payload and payload.error or "Vault unavailable."
		return
	end

	local maxSlots = payload.maxSlots or 0
	if maxSlots <= 0 then
		status.Text = "Vault unlocks at Rebirth 3. It will keep 1 stored player through rebirth."
	else
		status.Text = string.format("%d / %d vaulted. %s", #(payload.vault or {}), maxSlots, payload.note or "")
	end
	subtitle.Text = maxSlots > 0 and ("Rebirth " .. tostring(payload.rebirthTier or 0) .. " | " .. tostring(maxSlots) .. " slot(s)") or "Unlocks at Rebirth 3"

	makeSectionTitle("VAULT", 1)
	if #(payload.vault or {}) == 0 then
		makeLabel({
			Text = maxSlots > 0 and "No players vaulted yet." or "Reach Rebirth 3 to use the vault.",
			Size = UDim2.new(1, 0, 0, 36),
			LayoutOrder = 2,
			TextColor3 = Color3.fromRGB(180, 195, 210),
			TextSize = 12,
			TextScaled = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
		}, scroll)
	else
		for index, card in ipairs(payload.vault) do
			makeCardRow(card, 10 + index, "vault")
		end
	end

	makeSectionTitle("STORED PLAYERS", 1000)
	for index, card in ipairs(payload.inventory or {}) do
		local mode = containsSelected(card.id) and "selected" or "inventory"
		makeCardRow(card, 1010 + index, mode)
	end

	makeSectionTitle("ON DISPLAY - REMOVE FROM GREEN SLOT FIRST", 3000)
	if #(payload.displayed or {}) == 0 then
		makeLabel({
			Text = "No displayed players.",
			Size = UDim2.new(1, 0, 0, 32),
			LayoutOrder = 3010,
			TextColor3 = Color3.fromRGB(160, 174, 190),
			TextSize = 12,
			TextScaled = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
		}, scroll)
	else
		for index, card in ipairs(payload.displayed) do
			makeCardRow(card, 3010 + index, "displayed")
		end
	end
end

local function openUI(payload)
	syncSelectedFromPayload(payload)
	render(payload)
	panel.Visible = true
	dimmer.Visible = true
	panel.Size = UDim2.new(0, 420, 0, 560)
	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 460, 0, 610),
	}):Play()
	TweenService:Create(dimmer, TweenInfo.new(0.16), {
		BackgroundTransparency = 0.48,
	}):Play()
end

local function closeUI()
	TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 420, 0, 560),
	}):Play()
	TweenService:Create(dimmer, TweenInfo.new(0.14), {
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.16, function()
		panel.Visible = false
		dimmer.Visible = false
	end)
end

closeBtn.MouseButton1Click:Connect(closeUI)
dimmer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		closeUI()
	end
end)

OpenRebirthVaultUIEvent.OnClientEvent:Connect(function(payload)
	openUI(payload)
end)

task.spawn(function()
	local ok, payload = pcall(function()
		return GetRebirthVaultFn:InvokeServer()
	end)
	if ok and payload then
		currentPayload = payload
		syncSelectedFromPayload(payload)
	end
end)
