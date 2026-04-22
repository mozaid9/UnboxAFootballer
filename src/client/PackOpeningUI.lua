local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, child in ipairs(script.Parent:GetChildren()) do
	if child:IsA("LocalScript") and child ~= script and child.Name == script.Name then
		child.Disabled = true
	end
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetPlayerDataFn = Remotes:WaitForChild("GetPlayerData")
local UpdateCoinsEvent = Remotes:WaitForChild("UpdateCoins")
local PackOpenedEvent = Remotes:WaitForChild("PackOpened")
local PackOpenFailedEvent = Remotes:WaitForChild("PackOpenFailed")
local PromptPackShopEvent = Remotes:WaitForChild("PromptPackShop")

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

local existingGui = playerGui:FindFirstChild("PackOpeningUI")
if existingGui then
	existingGui:Destroy()
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local screenGui = make("ScreenGui", {
	Name = "PackOpeningUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local hudDock = make("Frame", {
	Name = "HudDock",
	Size = UDim2.fromOffset(184, 148),
	Position = UDim2.new(0, 24, 0, 118),
	BackgroundTransparency = 1,
}, screenGui)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 8),
}, hudDock)

local coinPill = make("Frame", {
	LayoutOrder = 1,
	Size = UDim2.fromOffset(176, 38),
	BackgroundColor3 = UI.Panel,
}, hudDock)
addCorner(coinPill, 12)
addStroke(coinPill, UI.Gold, 2, 0.15)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 24, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
	}),
	Rotation = 90,
}, coinPill)

local coinIcon = make("TextLabel", {
	Size = UDim2.fromOffset(22, 22),
	Position = UDim2.new(0, 8, 0.5, -11),
	BackgroundColor3 = Color3.fromRGB(35, 30, 10),
	Text = "C",
	TextColor3 = UI.Gold,
	TextScaled = false,
	TextSize = 17,
	Font = Enum.Font.GothamBlack,
}, coinPill)
addCorner(coinIcon, 8)

make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 38, 0, 3),
	Size = UDim2.new(1, -44, 0, 10),
	Text = "Coins",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 10,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local coinsLabel = make("TextLabel", {
	Name = "CoinsLabel",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 38, 0, 12),
	Size = UDim2.new(1, -44, 0, 18),
	Text = "0",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 19,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
}, coinPill)

local openShopButton = make("TextButton", {
	LayoutOrder = 2,
	Size = UDim2.fromOffset(176, 38),
	BackgroundColor3 = UI.Gold,
	Text = "Upgrades",
	TextColor3 = Color3.fromRGB(20, 14, 8),
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
}, hudDock)
addCorner(openShopButton, 12)

local hintLabel = make("TextLabel", {
	LayoutOrder = 3,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(184, 54),
	Text = "Pitchfork packs open one player. They auto-fill your green displays first.",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 12,
	TextWrapped = true,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
}, hudDock)

local toastHolder = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -20, 0, 92),
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(320, 420),
}, screenGui)

make("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 10),
}, toastHolder)

local function setCoinsDisplay(coins)
	coinsLabel.Text = Utils.FormatNumber(coins or 0)
end

local function showToast(text, accent)
	local toast = make("Frame", {
		BackgroundColor3 = UI.PanelAlt,
		Size = UDim2.new(1, 0, 0, 58),
	}, toastHolder)
	addCorner(toast, 16)
	addStroke(toast, accent, 2, 0.25)

	make("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 6, 1, -12),
		Position = UDim2.new(0, 8, 0, 6),
	}, toast)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Text = text,
		TextColor3 = UI.Text,
		TextWrapped = true,
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, toast)

	toast.BackgroundTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.18), {
		BackgroundTransparency = 0,
	}):Play()

	task.delay(3.2, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.2), {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
			}):Play()
			task.wait(0.22)
			if toast.Parent then
				toast:Destroy()
			end
		end
	end)
end

local function refreshStatus()
	local data = GetPlayerDataFn:InvokeServer()
	if not data then
		return
	end

	setCoinsDisplay(data.coins)
end

openShopButton.MouseButton1Click:Connect(function()
	showToast("Upgrades are next: pad luck, pack quality, and pitchfork power.", UI.Gold)
end)

openShopButton.MouseEnter:Connect(function()
	TweenService:Create(openShopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(255, 229, 70),
	}):Play()
end)

openShopButton.MouseLeave:Connect(function()
	TweenService:Create(openShopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = UI.Gold,
	}):Play()
end)

UpdateCoinsEvent.OnClientEvent:Connect(function(coins)
	setCoinsDisplay(coins)
end)

PackOpenedEvent.OnClientEvent:Connect(function(payload)
	if not payload or not payload.success then
		return
	end

	setCoinsDisplay(payload.newCoins)

	if payload.card then
		local targetText
		if payload.storedInInventory then
			targetText = payload.card.name .. " went to inventory because your displays are full."
		else
			targetText = payload.card.name .. " is now on display slot " .. tostring(payload.slotIndex) .. " earning +" .. tostring(payload.coinsPerSecond or 0) .. "/s."
		end
		showToast(targetText, Utils.GetRarityColor(payload.card.rarity))
	end
end)

PackOpenFailedEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end

	showToast(payload.error or "Pack could not be opened.", UI.Danger)
end)

PromptPackShopEvent.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end

	if payload.message then
		hintLabel.Text = payload.message
	end

	if payload.coins ~= nil then
		setCoinsDisplay(payload.coins)
	end
end)

task.spawn(function()
	task.wait(1)
	refreshStatus()
end)
