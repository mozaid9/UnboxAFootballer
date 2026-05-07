local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Constants = require(Shared:WaitForChild("Constants"))
local Utils = require(Shared:WaitForChild("Utils"))

local GetQuestsFn = Remotes:WaitForChild("GetQuests")
local ClaimQuestFn = Remotes:WaitForChild("ClaimQuest")
local QuestUpdatedEvent = Remotes:WaitForChild("QuestUpdated")

local UI = Constants.UI

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local existingGui = playerGui:FindFirstChild("QuestsUI")
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

local screenGui = make("ScreenGui", {
	Name = "QuestsUI",
	ResetOnSpawn = false,
	Enabled = false,
	DisplayOrder = 11,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = screenGui

local overlay = make("Frame", {
	Name = "Overlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.46,
	ZIndex = 1,
}, screenGui)

local overlayButton = make("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	ZIndex = 2,
}, overlay)

local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.78, 0, 0.78, 0),
	BackgroundColor3 = UI.Panel,
	BorderSizePixel = 0,
	ZIndex = 3,
}, screenGui)
addCorner(panel, 18)
addStroke(panel, Color3.fromRGB(205, 88, 255), 2, 0.22)
make("UISizeConstraint", {
	MinSize = Vector2.new(420, 430),
	MaxSize = Vector2.new(780, 680),
}, panel)

local panelScale = make("UIScale", { Scale = 0.92 }, panel)

local header = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 20, 0, 16),
	Size = UDim2.new(1, -40, 0, 72),
	ZIndex = 4,
}, panel)

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, -80, 0, 34),
	Text = "QUESTS",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 26,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, header)

local subtitle = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 36),
	Size = UDim2.new(1, -80, 0, 24),
	Text = "Daily objectives",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, header)

local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = UI.PanelAlt,
	Text = "X",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
	ZIndex = 5,
}, header)
addCorner(closeButton, 12)
addStroke(closeButton, UI.Muted, 1, 0.72)

local summaryBar = make("Frame", {
	Position = UDim2.new(0, 20, 0, 92),
	Size = UDim2.new(1, -40, 0, 48),
	BackgroundColor3 = UI.PanelAlt,
	BorderSizePixel = 0,
	ZIndex = 4,
}, panel)
addCorner(summaryBar, 14)

local summaryLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0, 0),
	Size = UDim2.new(0.42, -16, 1, 0),
	Text = "0 ready",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 15,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, summaryBar)

local timerLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -124, 0, 0),
	Size = UDim2.new(0.3, 0, 1, 0),
	Text = "Resets in --",
	TextColor3 = Color3.fromRGB(218, 200, 255),
	TextScaled = false,
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 5,
}, summaryBar)

local claimAllButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(104, 32),
	BackgroundColor3 = Color3.fromRGB(40, 150, 78),
	Text = "CLAIM ALL",
	TextColor3 = UI.Text,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBlack,
	Active = false,
	AutoButtonColor = false,
	ZIndex = 5,
}, summaryBar)
addCorner(claimAllButton, 10)

local filtersBar = make("Frame", {
	Position = UDim2.new(0, 20, 0, 148),
	Size = UDim2.new(1, -40, 0, 32),
	BackgroundTransparency = 1,
	ZIndex = 4,
}, panel)

local filtersLayout = make("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, filtersBar)

local statusLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 1, -34),
	Size = UDim2.new(1, -48, 0, 20),
	Text = "",
	TextColor3 = UI.Muted,
	TextScaled = false,
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, panel)

local scroll = make("ScrollingFrame", {
	Position = UDim2.new(0, 20, 0, 190),
	Size = UDim2.new(1, -40, 1, -232),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = Color3.fromRGB(205, 88, 255),
	CanvasSize = UDim2.fromOffset(0, 0),
	ZIndex = 4,
}, panel)

local listLayout = make("UIListLayout", {
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)
end)

local questPayload = nil
local claimingQuestId = nil
local selectedFilter = "all"
local filterButtons = {}
local isOpen = false
local renderQuestList

local function clearQuestRows()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local QUEST_FILTERS = {
	{ key = "all", label = "ALL" },
	{ key = "ready", label = "READY" },
	{ key = "progress", label = "IN PROGRESS" },
	{ key = "claimed", label = "CLAIMED" },
}

local function getQuestState(quest)
	if quest.claimed == true then
		return "claimed"
	end
	if quest.claimable == true then
		return "ready"
	end
	return "progress"
end

local function matchesSelectedFilter(quest)
	return selectedFilter == "all" or getQuestState(quest) == selectedFilter
end

local function setFilterButtonStyle(button, selected)
	button.BackgroundColor3 = selected and Color3.fromRGB(205, 88, 255) or UI.PanelAlt
	button.TextColor3 = selected and Color3.fromRGB(10, 8, 18) or UI.Text
	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = selected and Color3.fromRGB(245, 214, 255) or Color3.fromRGB(205, 88, 255)
		stroke.Transparency = selected and 0.28 or 0.72
	end
end

local function updateFilterButtons()
	for key, button in pairs(filterButtons) do
		setFilterButtonStyle(button, key == selectedFilter)
	end
end

for index, filter in ipairs(QUEST_FILTERS) do
	local width = 78
	if filter.key == "all" then
		width = 70
	elseif filter.key == "progress" then
		width = 104
	elseif filter.key == "claimed" then
		width = 82
	end

	local button = make("TextButton", {
		LayoutOrder = index,
		Size = UDim2.fromOffset(width, 30),
		BackgroundColor3 = UI.PanelAlt,
		Text = filter.label,
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBlack,
		AutoButtonColor = true,
		ZIndex = 5,
	}, filtersBar)
	addCorner(button, 10)
	addStroke(button, Color3.fromRGB(205, 88, 255), 1.2, 0.72)
	filterButtons[filter.key] = button

	button.MouseButton1Click:Connect(function()
		if selectedFilter == filter.key then
			return
		end
		selectedFilter = filter.key
		scroll.CanvasPosition = Vector2.new(0, 0)
		updateFilterButtons()
		renderQuestList()
	end)
end

local function renderQuestRow(quest, index)
	local ready = quest.claimable == true
	local claimed = quest.claimed == true
	local progress = math.clamp(tonumber(quest.progress) or 0, 0, tonumber(quest.target) or 1)
	local target = math.max(1, tonumber(quest.target) or 1)
	local alpha = math.clamp(progress / target, 0, 1)
	local accent = claimed and UI.Success or (ready and Color3.fromRGB(205, 88, 255) or UI.Gold)

	local row = make("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(1, -4, 0, 98),
		BackgroundColor3 = UI.PanelAlt,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, scroll)
	addCorner(row, 14)
	addStroke(row, accent, 1.4, ready and 0.24 or 0.62)

	local marker = make("Frame", {
		Position = UDim2.new(0, 12, 0, 14),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = accent:Lerp(Color3.fromRGB(0, 0, 0), 0.54),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, row)
	addCorner(marker, 12)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = claimed and "OK" or tostring(index),
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 15,
		Font = Enum.Font.GothamBlack,
		ZIndex = 7,
	}, marker)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0, 12),
		Size = UDim2.new(1, -210, 0, 22),
		Text = string.upper(quest.title or "Quest"),
		TextColor3 = UI.Text,
		TextScaled = false,
		TextSize = 15,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, row)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0, 36),
		Size = UDim2.new(1, -210, 0, 18),
		Text = quest.description or "",
		TextColor3 = UI.Muted,
		TextScaled = false,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, row)

	local progressBack = make("Frame", {
		Position = UDim2.new(0, 68, 0, 64),
		Size = UDim2.new(1, -210, 0, 10),
		BackgroundColor3 = Color3.fromRGB(7, 10, 18),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, row)
	addCorner(progressBack, 5)

	local progressFill = make("Frame", {
		Size = UDim2.new(alpha, 0, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, progressBack)
	addCorner(progressFill, 5)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0, 76),
		Size = UDim2.new(1, -210, 0, 16),
		Text = tostring(progress) .. " / " .. tostring(target) .. "  |  " .. tostring(quest.rewardText or "Reward"),
		TextColor3 = Color3.fromRGB(212, 202, 174),
		TextScaled = false,
		TextSize = 10,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, row)

	local claimButton = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(126, 34),
		BackgroundColor3 = ready and Color3.fromRGB(40, 150, 78) or Color3.fromRGB(45, 48, 58),
		Text = claimed and "CLAIMED" or (ready and "CLAIM" or "IN PROGRESS"),
		TextColor3 = claimed and Color3.fromRGB(178, 232, 190) or UI.Text,
		TextScaled = false,
		TextSize = ready and 12 or 10,
		Font = Enum.Font.GothamBlack,
		Active = ready and not claimed,
		AutoButtonColor = ready and not claimed,
		ZIndex = 6,
	}, row)
	addCorner(claimButton, 10)

	claimButton.MouseButton1Click:Connect(function()
		if not ready or claimed or claimingQuestId then
			return
		end

		claimingQuestId = quest.id
		claimButton.Text = "CLAIMING..."
		claimButton.Active = false
		statusLabel.Text = "Claiming " .. tostring(quest.title or "quest") .. "..."

		local ok, result = pcall(function()
			return ClaimQuestFn:InvokeServer(quest.id)
		end)
		claimingQuestId = nil

		if ok and result and result.success then
			statusLabel.Text = "Reward claimed."
			questPayload = result.quests or questPayload
			renderQuestList()
		else
			statusLabel.Text = (ok and result and result.error) or "Quest claim failed."
			renderQuestList()
		end
	end)
end

renderQuestList = function()
	clearQuestRows()
	local payload = questPayload or { quests = {}, resetRemaining = 0, claimableCount = 0, completedCount = 0 }
	local quests = payload.quests or {}
	local total = #quests
	local completed = tonumber(payload.completedCount) or 0
	local claimable = tonumber(payload.claimableCount) or 0
	local visibleCount = 0

	summaryLabel.Text = tostring(claimable) .. " ready  |  " .. tostring(completed) .. " / " .. tostring(total) .. " claimed"
	timerLabel.Text = "Resets in " .. formatClock(payload.resetRemaining or 0)
	claimAllButton.Text = claimingQuestId == "__all" and "CLAIMING..." or "CLAIM ALL"
	claimAllButton.Active = claimable > 0 and not claimingQuestId
	claimAllButton.AutoButtonColor = claimable > 0 and not claimingQuestId
	claimAllButton.BackgroundColor3 = claimable > 0 and Color3.fromRGB(40, 150, 78) or Color3.fromRGB(45, 48, 58)
	claimAllButton.TextColor3 = claimable > 0 and UI.Text or Color3.fromRGB(180, 184, 196)
	updateFilterButtons()

	if total == 0 then
		local empty = make("Frame", {
			LayoutOrder = 1,
			Size = UDim2.new(1, -4, 0, 96),
			BackgroundColor3 = UI.PanelAlt,
			ZIndex = 5,
		}, scroll)
		addCorner(empty, 14)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "Quests are loading.",
			TextColor3 = UI.Muted,
			TextScaled = false,
			TextSize = 14,
			Font = Enum.Font.GothamBlack,
			ZIndex = 6,
		}, empty)
		return
	end

	for index, quest in ipairs(quests) do
		if matchesSelectedFilter(quest) then
			visibleCount += 1
			renderQuestRow(quest, index)
		end
	end

	if visibleCount == 0 then
		local empty = make("Frame", {
			LayoutOrder = 1,
			Size = UDim2.new(1, -4, 0, 96),
			BackgroundColor3 = UI.PanelAlt,
			ZIndex = 5,
		}, scroll)
		addCorner(empty, 14)
		addStroke(empty, Color3.fromRGB(205, 88, 255), 1.2, 0.72)
		make("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = selectedFilter == "ready" and "No rewards ready yet." or "No quests in this view.",
			TextColor3 = UI.Muted,
			TextScaled = false,
			TextSize = 14,
			Font = Enum.Font.GothamBlack,
			ZIndex = 6,
		}, empty)
	end
end

local function claimAllReadyQuests()
	if claimingQuestId or not questPayload then
		return
	end

	local readyQuests = {}
	for _, quest in ipairs(questPayload.quests or {}) do
		if quest.claimable == true and quest.claimed ~= true and type(quest.id) == "string" then
			table.insert(readyQuests, quest)
		end
	end

	if #readyQuests == 0 then
		statusLabel.Text = "No quest rewards ready."
		return
	end

	claimingQuestId = "__all"
	statusLabel.Text = "Claiming " .. tostring(#readyQuests) .. " quest reward" .. (#readyQuests == 1 and "..." or "s...")
	renderQuestList()

	task.spawn(function()
		local claimedCount = 0
		local lastError = nil

		for _, quest in ipairs(readyQuests) do
			local ok, result = pcall(function()
				return ClaimQuestFn:InvokeServer(quest.id)
			end)

			if ok and result and result.success then
				claimedCount += 1
				questPayload = result.quests or questPayload
			else
				lastError = (ok and result and result.error) or "Quest claim failed."
			end
		end

		claimingQuestId = nil
		if claimedCount > 0 then
			statusLabel.Text = "Claimed " .. tostring(claimedCount) .. " quest reward" .. (claimedCount == 1 and "." or "s.")
		else
			statusLabel.Text = lastError or "Quest claim failed."
		end
		renderQuestList()
	end)
end

local function applyQuestPayload(payload)
	if type(payload) ~= "table" then
		return
	end
	questPayload = payload
	renderQuestList()
end

local function refreshQuests()
	statusLabel.Text = ""
	local ok, payload = pcall(function()
		return GetQuestsFn:InvokeServer()
	end)
	if ok then
		applyQuestPayload(payload)
	else
		statusLabel.Text = "Could not load quests."
	end
end

local function openQuests()
	if isOpen then
		return
	end
	isOpen = true
	screenGui.Enabled = true
	panelScale.Scale = 0.92
	TweenService:Create(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
	refreshQuests()
end

local function closeQuests()
	if not isOpen then
		return
	end
	isOpen = false
	TweenService:Create(panelScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.92,
	}):Play()
	task.delay(0.12, function()
		if not isOpen then
			screenGui.Enabled = false
		end
	end)
end

toggleEvent.Event:Connect(function()
	if isOpen then
		closeQuests()
	else
		openQuests()
	end
end)

overlayButton.MouseButton1Click:Connect(closeQuests)
closeButton.MouseButton1Click:Connect(closeQuests)
claimAllButton.MouseButton1Click:Connect(claimAllReadyQuests)

QuestUpdatedEvent.OnClientEvent:Connect(function(payload)
	applyQuestPayload(payload)
end)

task.spawn(function()
	while true do
		task.wait(1)
		if isOpen and questPayload then
			questPayload.resetRemaining = math.max(0, (tonumber(questPayload.resetRemaining) or 0) - 1)
			timerLabel.Text = "Resets in " .. formatClock(questPayload.resetRemaining)
			if questPayload.resetRemaining <= 0 then
				refreshQuests()
			end
		end
	end
end)

renderQuestList()
