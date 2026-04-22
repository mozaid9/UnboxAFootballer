local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

if ServerScriptService:GetAttribute("UnboxMainBooted") then
	warn("[UnboxAFootballer] Duplicate Main detected, skipping older copy")
	return
end
ServerScriptService:SetAttribute("UnboxMainBooted", true)

for _, child in ipairs(ServerScriptService:GetChildren()) do
	if child:IsA("Script") and child ~= script and child.Name == script.Name then
		child.Disabled = true
	end
end

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared:WaitForChild("Constants"))
local DataService = require(ServerScriptService:WaitForChild("DataService"))
local EconomyService = require(ServerScriptService:WaitForChild("EconomyService"))
local PackService = require(ServerScriptService:WaitForChild("PackService"))
local BaseService = require(ServerScriptService:WaitForChild("BaseService"))
local RebirthService = require(ServerScriptService:WaitForChild("RebirthService"))

local PackConfig = require(Shared:WaitForChild("PackConfig"))
local CardData = require(Shared:WaitForChild("CardData"))
local Utils = require(Shared:WaitForChild("Utils"))

local existingRemotes = ReplicatedStorage:FindFirstChild("Remotes")
if existingRemotes then
	existingRemotes:Destroy()
end

local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local function makeEvent(name)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = Remotes
	return event
end

local function makeFunction(name)
	local fn = Instance.new("RemoteFunction")
	fn.Name = name
	fn.Parent = Remotes
	return fn
end

local UpdateCoinsEvent = makeEvent("UpdateCoins")
local PackOpenedEvent = makeEvent("PackOpened")
local PackOpenFailedEvent = makeEvent("PackOpenFailed")
local PromptPackShopEvent = makeEvent("PromptPackShop")
local RequestPitchforkHitEvent = makeEvent("RequestPitchforkHit")

local GetPlayerDataFn = makeFunction("GetPlayerData")
local OpenPackFn = makeFunction("OpenPack")
local SellCardFn = makeFunction("SellCard")
local SellAllCardsFn = makeFunction("SellAllCards")
local GetInventoryFn = makeFunction("GetInventory")

PackService.Init(DataService, EconomyService, {
	UpdateCoins = UpdateCoinsEvent,
	PackOpened = PackOpenedEvent,
	PackOpenFailed = PackOpenFailedEvent,
})
EconomyService.Init(DataService)
RebirthService.Init(DataService)

BaseService.BuildBaseMap()

local swingCooldowns = {}

local function makeToolPart(name, size, color, cframe, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Anchored = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function weldParts(part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
end

local function createPitchforkTool()
	local tool = Instance.new("Tool")
	tool.Name = "Pitchfork"
	tool.ToolTip = "Swing at the pack on your red pad."
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -1.4, -0.9) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(-18))

	local handle = makeToolPart("Handle", Vector3.new(0.3, 4.4, 0.3), Color3.fromRGB(122, 84, 50), CFrame.new(), tool)
	local collar = makeToolPart("Collar", Vector3.new(0.8, 0.18, 0.8), Color3.fromRGB(70, 74, 82), handle.CFrame * CFrame.new(0, 1.9, 0), tool)
	local tineLeft = makeToolPart("TineLeft", Vector3.new(0.12, 1.3, 0.12), Color3.fromRGB(180, 182, 188), handle.CFrame * CFrame.new(-0.22, 2.45, 0), tool)
	local tineMiddle = makeToolPart("TineMiddle", Vector3.new(0.12, 1.45, 0.12), Color3.fromRGB(205, 208, 214), handle.CFrame * CFrame.new(0, 2.52, 0), tool)
	local tineRight = makeToolPart("TineRight", Vector3.new(0.12, 1.3, 0.12), Color3.fromRGB(180, 182, 188), handle.CFrame * CFrame.new(0.22, 2.45, 0), tool)
	local crossbar = makeToolPart("Crossbar", Vector3.new(0.72, 0.12, 0.12), Color3.fromRGB(160, 162, 168), handle.CFrame * CFrame.new(0, 1.95, 0), tool)

	weldParts(handle, collar)
	weldParts(handle, tineLeft)
	weldParts(handle, tineMiddle)
	weldParts(handle, tineRight)
	weldParts(handle, crossbar)

	return tool
end

local function ensurePitchfork(player)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	local character = player.Character

	local hasEquipped = character and character:FindFirstChild("Pitchfork")
	if backpack and not hasEquipped and not backpack:FindFirstChild("Pitchfork") then
		createPitchforkTool().Parent = backpack
	end
end

local function sendHint(player, message)
	if player and player.Parent then
		PromptPackShopEvent:FireClient(player, {
			message = message,
		})
	end
end

local function getPitchforkDamage(player)
	local data = DataService.GetData(player)
	return math.max(Constants.Pitchfork.BaseDamage, data and data.pitchforkPower or Constants.Pitchfork.BaseDamage)
end

local function getHitsLabel(remaining)
	if remaining == 1 then
		return "1 hit to crack"
	end

	return string.format("%d hits to crack", remaining)
end

local function createSurfaceLabel(face, title, subtitle, color, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 0
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(22, 18, 8)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 247, 191)),
		ColorSequenceKeypoint.new(0.35, color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(96, 66, 10)),
	})
	gradient.Rotation = 25
	gradient.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(31, 24, 10)
	stroke.Thickness = 3
	stroke.Parent = frame

	local top = Instance.new("TextLabel")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(0.42, 0, 0.28, 0)
	top.Position = UDim2.new(0.06, 0, 0.06, 0)
	top.Text = title
	top.TextColor3 = Color3.fromRGB(20, 15, 8)
	top.TextScaled = true
	top.Font = Enum.Font.GothamBlack
	top.TextXAlignment = Enum.TextXAlignment.Left
	top.Parent = frame

	local middle = Instance.new("TextLabel")
	middle.BackgroundTransparency = 1
	middle.Size = UDim2.new(0.84, 0, 0.22, 0)
	middle.Position = UDim2.new(0.08, 0, 0.61, 0)
	middle.Text = subtitle
	middle.TextColor3 = Color3.fromRGB(48, 38, 14)
	middle.TextScaled = true
	middle.Font = Enum.Font.GothamBold
	middle.Parent = frame

	local stripes = Instance.new("Frame")
	stripes.BackgroundTransparency = 0.8
	stripes.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	stripes.Size = UDim2.new(0.52, 0, 0.62, 0)
	stripes.Position = UDim2.new(0.42, 0, 0.08, 0)
	stripes.Rotation = -18
	stripes.BorderSizePixel = 0
	stripes.Parent = frame

	local stripeGradient = Instance.new("UIGradient")
	stripeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.8, 0.9),
		NumberSequenceKeypoint.new(1, 1),
	})
	stripeGradient.Rotation = 90
	stripeGradient.Parent = stripes
end

local function rollPadPackForPlayer(_player)
	local weights = {}
	for _, packDef in ipairs(PackConfig.PadSpawnOrder) do
		table.insert(weights, packDef.padWeight or 1)
	end

	local chosenIndex = Utils.WeightedRandom(weights)
	return PackConfig.PadSpawnOrder[chosenIndex]
end

local function clearPlotPack(plot)
	if plot.activePackModel and plot.activePackModel.Parent then
		plot.activePackModel:Destroy()
	end
	plot.activePackModel = nil
	plot.activePackDef = nil
	plot.activePackBody = nil
	plot.activePackLight = nil
	plot.activePackHitsRemaining = nil
	plot.activePackMaxHits = nil
	plot.isOpeningPack = nil
end

local function spawnPackForPlot(plot)
	if not plot or not plot.ownerPlayer then
		return
	end

	clearPlotPack(plot)

	local packDef = rollPadPackForPlayer(plot.ownerPlayer)
	if not packDef then
		return
	end

	local model = Instance.new("Model")
	model.Name = packDef.id
	model.Parent = plot.model

	local basePosition = plot.packPad.Position + Vector3.new(0, 5.4, 0)
	local lookDirection = Vector3.new(plot.facingDirection, 0, 0)
	local rootCFrame = CFrame.lookAt(basePosition, basePosition + lookDirection)

	local cardBody = Instance.new("Part")
	cardBody.Name = "PackBody"
	cardBody.Anchored = true
	cardBody.Material = Enum.Material.SmoothPlastic
	cardBody.Color = Color3.fromRGB(28, 22, 8)
	cardBody.Size = Vector3.new(0.3, 8, 5.4)
	cardBody.CFrame = rootCFrame
	cardBody.Parent = model

	local topCap = Instance.new("WedgePart")
	topCap.Name = "TopCap"
	topCap.Anchored = true
	topCap.Material = Enum.Material.SmoothPlastic
	topCap.Color = Color3.fromRGB(28, 22, 8)
	topCap.Size = Vector3.new(0.3, 1.4, 5.4)
	topCap.CFrame = cardBody.CFrame * CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.rad(180))
	topCap.Parent = model

	local bottomCap = Instance.new("WedgePart")
	bottomCap.Name = "BottomCap"
	bottomCap.Anchored = true
	bottomCap.Material = Enum.Material.SmoothPlastic
	bottomCap.Color = Color3.fromRGB(20, 16, 6)
	bottomCap.Size = Vector3.new(0.3, 1.6, 5.4)
	bottomCap.CFrame = cardBody.CFrame * CFrame.new(0, -4.8, 0)
	bottomCap.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = packDef.color
	glow.Range = 18
	glow.Brightness = 2.8
	glow.Parent = cardBody

	createSurfaceLabel(Enum.NormalId.Front, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)
	createSurfaceLabel(Enum.NormalId.Back, tostring(packDef.displayRating), packDef.displayName, packDef.color, cardBody)

	local floatTween = TweenService:Create(cardBody, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		CFrame = cardBody.CFrame * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, math.rad(4), 0),
	})
	floatTween:Play()

	plot.activePackModel = model
	plot.activePackDef = packDef
	plot.activePackBody = cardBody
	plot.activePackLight = glow
	plot.activePackMaxHits = packDef.hitsRequired or 3
	plot.activePackHitsRemaining = plot.activePackMaxHits

	BaseService.SetPlotPadStatus(plot, packDef.displayName, getHitsLabel(plot.activePackHitsRemaining), packDef.color)
	sendHint(plot.ownerPlayer, string.format("%s spawned on your red pad. Equip your pitchfork and swing %d time%s.", packDef.displayName, plot.activePackHitsRemaining, plot.activePackHitsRemaining == 1 and "" or "s"))
end

for _, plot in ipairs(BaseService.GetPlots()) do
	BaseService.SetPlotPadStatus(plot, "Pack Pad", "Waiting for owner", Color3.fromRGB(255, 85, 85))
end

RequestPitchforkHitEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	local lastSwing = swingCooldowns[player]
	if lastSwing and (now - lastSwing) < Constants.Pitchfork.SwingCooldown then
		return
	end
	swingCooldowns[player] = now

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local equippedTool = character and character:FindFirstChildOfClass("Tool")
	if not humanoid or not rootPart or not equippedTool or equippedTool.Name ~= "Pitchfork" then
		PackOpenFailedEvent:FireClient(player, {
			error = "Equip your pitchfork first.",
		})
		return
	end

	local plot = BaseService.GetPlot(player)
	if not plot or not plot.activePackDef or not plot.activePackBody or plot.isOpeningPack then
		PackOpenFailedEvent:FireClient(player, {
			error = "Your next pack is still spawning.",
		})
		return
	end

	if (rootPart.Position - plot.activePackBody.Position).Magnitude > Constants.Pitchfork.HitRange then
		PackOpenFailedEvent:FireClient(player, {
			error = "Move closer to the pack on your red pad.",
		})
		return
	end

	local damage = getPitchforkDamage(player)
	plot.activePackHitsRemaining = math.max(0, (plot.activePackHitsRemaining or plot.activePackMaxHits or 1) - damage)

	if plot.activePackLight then
		plot.activePackLight.Brightness = 2.4 + ((plot.activePackMaxHits - plot.activePackHitsRemaining) * 0.65)
	end

	if plot.activePackHitsRemaining > 0 then
		BaseService.SetPlotPadStatus(plot, plot.activePackDef.displayName, getHitsLabel(plot.activePackHitsRemaining), plot.activePackDef.color)
		sendHint(player, string.format("%s: %d hit%s left.", plot.activePackDef.displayName, plot.activePackHitsRemaining, plot.activePackHitsRemaining == 1 and "" or "s"))
		return
	end

	plot.isOpeningPack = true
	BaseService.SetPlotPadStatus(plot, "Pack Cracked", "Revealing your cards", plot.activePackDef.color)
	sendHint(player, plot.activePackDef.displayName .. " cracked open.")

	local openedPackId = plot.activePackDef.id
	local openedPackColor = plot.activePackDef.color
	humanoid:UnequipTools()

	local ok, result = PackService.OpenPack(player, openedPackId, {
		ignoreCost = true,
		source = "pitchfork",
	})

	if ok then
		PackOpenedEvent:FireClient(player, result)
		clearPlotPack(plot)
		BaseService.SetPlotPadStatus(plot, "Rolling Next Pack", "Another free pack is spawning", openedPackColor)
		task.delay(1.1, function()
			if plot.ownerPlayer == player then
				spawnPackForPlot(plot)
			end
		end)
	else
		plot.isOpeningPack = nil
		plot.activePackHitsRemaining = math.max(1, plot.activePackHitsRemaining or 1)
		BaseService.SetPlotPadStatus(plot, plot.activePackDef.displayName, getHitsLabel(plot.activePackHitsRemaining), plot.activePackDef.color)
		PackOpenFailedEvent:FireClient(player, result)
	end
end)

Players.PlayerAdded:Connect(function(player)
	local data = DataService.LoadPlayer(player)
	local plot = BaseService.AssignPlot(player)
	EconomyService.EnsureStarterCoins(player)
	EconomyService.TryGrantDailyReward(player)
	ensurePitchfork(player)

	if player.Character then
		task.defer(function()
			if player.Parent then
				BaseService.PlaceCharacterAtPlot(player, player.Character)
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		task.delay(0.15, function()
			if player.Parent and character.Parent then
				BaseService.PlaceCharacterAtPlot(player, character)
				ensurePitchfork(player)
			end
		end)
	end)

	if plot then
		spawnPackForPlot(plot)
	end

	task.defer(function()
		if player.Parent then
			UpdateCoinsEvent:FireClient(player, DataService.GetCoins(player))
			sendHint(player, plot and "Equip your pitchfork and crack the random pack on your red pad." or "This server's bases are full right now.")
		end
	end)

	return data
end)

Players.PlayerRemoving:Connect(function(player)
	swingCooldowns[player] = nil
	DataService.SavePlayer(player)
	DataService.UnloadPlayer(player)
	BaseService.ReleasePlot(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
	task.wait(2)
end)

GetPlayerDataFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return nil
	end

	return {
		coins = data.coins,
		gems = data.gems or 0,
		rebirthTier = data.rebirthTier or 0,
		totalCardsOpened = data.totalCardsOpened or 0,
		canClaimFreePack = EconomyService.CanClaimFreePack(player),
		freePackRemaining = EconomyService.GetFreePackRemaining(player),
		inventoryCounts = data.inventory,
	}
end

GetInventoryFn.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return {}
	end

	local inventory = {}
	for key, amount in pairs(data.inventory) do
		local cardId = tonumber(key)
		local card = cardId and CardData.ById[cardId]
		if card and amount > 0 then
			table.insert(inventory, {
				id = card.id,
				name = card.name,
				nation = card.nation,
				position = card.position,
				rating = card.rating,
				rarity = card.rarity,
				quantity = amount,
				sellValue = Utils.GetSellValue(card.rating),
			})
		end
	end

	table.sort(inventory, function(a, b)
		if a.rating == b.rating then
			return a.name < b.name
		end
		return a.rating > b.rating
	end)

	return inventory
end

OpenPackFn.OnServerInvoke = function(player, packId)
	return {
		success = false,
		error = "Use your pitchfork on the pack at your red pad.",
	}
end

SellCardFn.OnServerInvoke = function(player, cardId)
	if type(cardId) ~= "number" then
		return { success = false, error = "Invalid card" }
	end

	local card = CardData.ById[cardId]
	if not card then
		return { success = false, error = "Unknown card" }
	end

	if not DataService.RemoveCard(player, cardId) then
		return { success = false, error = "Card not owned" }
	end

	local earned = Utils.GetSellValue(card.rating)
	EconomyService.AddCoins(player, earned)

	return {
		success = true,
		coinsEarned = earned,
		newCoins = DataService.GetCoins(player),
	}
end

SellAllCardsFn.OnServerInvoke = function(player, cardIds)
	if type(cardIds) ~= "table" then
		return { success = false, error = "Invalid payload" }
	end

	local total = 0
	for _, cardId in ipairs(cardIds) do
		if type(cardId) == "number" then
			local card = CardData.ById[cardId]
			if card and DataService.RemoveCard(player, cardId) then
				total += Utils.GetSellValue(card.rating)
			end
		end
	end

	if total > 0 then
		EconomyService.AddCoins(player, total)
	end

	return {
		success = true,
		coinsEarned = total,
		newCoins = DataService.GetCoins(player),
	}
end

print("[UnboxAFootballer] Pack systems ready")
