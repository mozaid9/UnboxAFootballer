local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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

local watchedPlots = {}

local function getOwnedPlot()
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	if not basesFolder then
		return nil
	end

	for _, child in ipairs(basesFolder:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == player.UserId then
			return child
		end
	end

	return nil
end

local function snapCameraToOwnedBase(character)
	local camera = Workspace.CurrentCamera
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local plotModel = getOwnedPlot()
	local packPad = plotModel and plotModel:FindFirstChild("PackPad")
	if not camera or not rootPart or not humanoid or not packPad then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid

	local lookTarget = packPad.Position + Vector3.new(0, 3, 0)
	local forward = (lookTarget - rootPart.Position)
	if forward.Magnitude < 0.1 then
		return
	end
	forward = forward.Unit

	local cameraPosition = rootPart.Position - (forward * 12) + Vector3.new(0, 5, 0)
	camera.CFrame = CFrame.lookAt(cameraPosition, lookTarget)
end

local function applyPlotPadVisibility(plotModel)
	if not plotModel or not plotModel.Parent then
		return
	end

	local packPad = plotModel:FindFirstChild("PackPad")
	local padGui = packPad and packPad:FindFirstChild("PadGui")
	if padGui and padGui:IsA("BillboardGui") then
		padGui.Enabled = plotModel:GetAttribute("OwnerUserId") == player.UserId
	end
end

local function watchPlot(plotModel)
	if watchedPlots[plotModel] or not plotModel:IsA("Model") then
		return
	end

	watchedPlots[plotModel] = true
	applyPlotPadVisibility(plotModel)

	plotModel:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		applyPlotPadVisibility(plotModel)
	end)

	local packPad = plotModel:FindFirstChild("PackPad")
	if packPad then
		packPad.ChildAdded:Connect(function(child)
			if child.Name == "PadGui" then
				applyPlotPadVisibility(plotModel)
			end
		end)
	end
end

task.spawn(function()
	local basesFolder = Workspace:WaitForChild("PlayerBases", 10)
	if not basesFolder then
		return
	end

	for _, child in ipairs(basesFolder:GetChildren()) do
		watchPlot(child)
	end

	basesFolder.ChildAdded:Connect(function(child)
		watchPlot(child)
	end)
end)

local sidebar = make("Frame", {
	Name = "Sidebar",
	AnchorPoint = Vector2.new(0, 1),
	Size = UDim2.fromOffset(168, 188),
	Position = UDim2.new(0, 20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.12,
}, screenGui)
addCorner(sidebar, 16)
addStroke(sidebar, UI.Gold, 1.25, 0.72)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 22, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 18)),
	}),
	Rotation = 90,
}, sidebar)

local sidebarPadding = make("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, sidebar)
_ = sidebarPadding

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local walletDock = make("Frame", {
	Name = "WalletDock",
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(218, 98),
	Position = UDim2.new(1, -20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(8, 12, 22),
	BackgroundTransparency = 0.1,
}, screenGui)
addCorner(walletDock, 16)
addStroke(walletDock, UI.Gold, 1.25, 0.72)

local walletPadding = make("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, walletDock)
_ = walletPadding

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, walletDock)

local function createWalletRow(parent, order, labelText, iconText, iconColor)
	local row = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = UI.Panel,
	}, parent)
	addCorner(row, 10)
	addStroke(row, iconColor, 1.5, 0.7)

	local icon = make("TextLabel", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 8, 0.5, -13),
		BackgroundColor3 = iconColor:Lerp(Color3.fromRGB(0, 0, 0), 0.72),
		Text = iconText,
		TextColor3 = iconColor,
		TextScaled = false,
		TextSize = 17,
		Font = Enum.Font.GothamBlack,
	}, row)
	addCorner(icon, 9)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 42, 0, 3),
		Size = UDim2.new(1, -82, 0, 12),
		Text = labelText,
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local valueLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 42, 0, 14),
		Size = UDim2.new(1, -82, 0, 22),
		Text = "0",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local plusButton = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(32, 128, 55),
		Text = "+",
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
	}, row)
	addCorner(plusButton, 8)

	return valueLabel, plusButton
end

local fansLabel, addFansButton = createWalletRow(walletDock, 1, "Fans", "F", UI.Gold)
local gemsLabel, addGemsButton = createWalletRow(walletDock, 2, "Gems", "D", Color3.fromRGB(69, 207, 255))

local function createMenuButton(order, text, accentColor)
	local button = make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = accentColor,
		Text = text,
		TextColor3 = accentColor == UI.Gold and Color3.fromRGB(20, 14, 8) or UI.Text,
		TextScaled = false,
		TextSize = 15,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = true,
	}, sidebar)
	addCorner(button, 9)
	return button
end

local inventoryButton = createMenuButton(1, "Inventory", UI.PanelAlt)
local upgradesButton = createMenuButton(2, "Upgrades", UI.Gold)
local questsButton = createMenuButton(3, "Quests", Color3.fromRGB(42, 54, 126))
local shopButton = createMenuButton(4, "Shop", Color3.fromRGB(25, 118, 55))

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
	fansLabel.Text = Utils.FormatNumber(coins or 0)
end

local function setGemsDisplay(gems)
	gemsLabel.Text = Utils.FormatNumber(gems or 0)
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

local function fireGuiToggle(guiName)
	local targetGui = playerGui:FindFirstChild(guiName)
	if not targetGui then
		targetGui = playerGui:WaitForChild(guiName, 3)
	end

	local toggleEvent = targetGui and targetGui:FindFirstChild("ToggleEvent")
	if toggleEvent then
		toggleEvent:Fire()
		return true
	end

	return false
end

local function refreshStatus()
	local data = GetPlayerDataFn:InvokeServer()
	if not data then
		return
	end

	setCoinsDisplay(data.coins)
	setGemsDisplay(data.gems)
end

inventoryButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("InventoryUI") then
		showToast("Inventory UI is still loading. Try again in a second.", UI.Gold)
	end
end)

upgradesButton.MouseButton1Click:Connect(function()
	if not fireGuiToggle("UpgradesUI") then
		showToast("Upgrades UI is still loading. Try again in a second.", UI.Gold)
	end
end)

questsButton.MouseButton1Click:Connect(function()
	showToast("Quests are coming soon. This button is ready for the next system.", Color3.fromRGB(110, 130, 255))
end)

shopButton.MouseButton1Click:Connect(function()
	showToast("Shop is coming soon. Pack tiers and cosmetics will live here.", Color3.fromRGB(74, 185, 98))
end)

addFansButton.MouseButton1Click:Connect(function()
	showToast("Fans come from displayed players. Future boosts will help you grow faster.", UI.Gold)
end)

addGemsButton.MouseButton1Click:Connect(function()
	showToast("Gems are planned for premium packs and cosmetics later.", Color3.fromRGB(69, 207, 255))
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
			targetText = payload.card.name .. " is now on display slot " .. tostring(payload.slotIndex) .. " earning +" .. tostring(payload.coinsPerSecond or 0) .. " Fans/s."
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

	if payload.coins ~= nil then
		setCoinsDisplay(payload.coins)
	end
end)

task.spawn(function()
	task.wait(1)
	refreshStatus()
end)

local function onCharacterAdded(character)
	task.delay(0.25, function()
		if player.Parent and character.Parent then
			snapCameraToOwnedBase(character)
		end
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
