local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)

local CrowdService = {}

local BaseService
local DataService
local fanFolder
local running = false

local plazaConfig = Constants.FanPlaza
local layout = Constants.BaseLayout

local shirtColors = {
	Color3.fromRGB(18, 23, 34),
	Color3.fromRGB(32, 96, 62),
	Color3.fromRGB(120, 72, 38),
	Color3.fromRGB(38, 72, 120),
	Color3.fromRGB(118, 92, 28),
	Color3.fromRGB(92, 46, 120),
}

local skinColors = {
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(199, 142, 91),
	Color3.fromRGB(141, 85, 54),
	Color3.fromRGB(246, 215, 176),
}

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function getWaypoint(name)
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	local plaza = basesFolder and basesFolder:FindFirstChild("FanPlaza")
	local waypoints = plaza and plaza:FindFirstChild("Waypoints")
	return waypoints and waypoints:FindFirstChild(name)
end

local function getPoint(name)
	local waypoint = getWaypoint(name)
	return waypoint and waypoint.Position
end

local function createFanNpc(index)
	local model = make("Model", {
		Name = "FanNPC" .. index,
	}, fanFolder)

	local shirtColor = shirtColors[math.random(1, #shirtColors)]
	local skinColor = skinColors[math.random(1, #skinColors)]

	local root = make("Part", {
		Name = "Root",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
		CFrame = CFrame.new(0, 2.2, 0),
	}, model)
	model.PrimaryPart = root

	make("Part", {
		Name = "Torso",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = shirtColor,
		Size = Vector3.new(1.15, 1.25, 0.55),
		CFrame = CFrame.new(0, 2.25, 0),
	}, model)

	make("Part", {
		Name = "Head",
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(0.82, 0.82, 0.82),
		CFrame = CFrame.new(0, 3.15, 0),
	}, model)

	make("Part", {
		Name = "LeftLeg",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(26, 28, 34),
		Size = Vector3.new(0.42, 0.85, 0.42),
		CFrame = CFrame.new(-0.28, 1.22, 0),
	}, model)

	make("Part", {
		Name = "RightLeg",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(26, 28, 34),
		Size = Vector3.new(0.42, 0.85, 0.42),
		CFrame = CFrame.new(0.28, 1.22, 0),
	}, model)

	make("Part", {
		Name = "LeftArm",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(0.3, 0.9, 0.3),
		CFrame = CFrame.new(-0.78, 2.2, 0),
	}, model)

	make("Part", {
		Name = "RightArm",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(0.3, 0.9, 0.3),
		CFrame = CFrame.new(0.78, 2.2, 0),
	}, model)

	return model
end

local function getPlotEntrancePoint(plot)
	local floorPosition = plot.floor.Position
	local frontX = floorPosition.X + (plot.facingDirection * ((layout.PlotSize.X / 2) + 7))
	return Vector3.new(frontX, 2.2, floorPosition.Z)
end

local function getPlotWeight(plot)
	if not plot.ownerPlayer or not DataService then
		return 0
	end

	local fans = DataService.GetCoins(plot.ownerPlayer)
	local visibleFromFans = math.floor((fans or 0) / plazaConfig.FansPerVisibleNpc)
	local capacity = math.min(plazaConfig.MaxStadiumVisitors, plazaConfig.BaseStadiumCapacity + math.floor((fans or 0) / 500000))
	return math.clamp(visibleFromFans, 0, capacity)
end

local function chooseVisitorPlot()
	if not BaseService then
		return nil
	end

	local weightedPlots = {}
	local totalWeight = 0
	for _, plot in ipairs(BaseService.GetPlots()) do
		local weight = getPlotWeight(plot)
		if weight > 0 then
			totalWeight += weight
			table.insert(weightedPlots, {
				plot = plot,
				weight = weight,
			})
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(weightedPlots) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.plot
		end
	end

	return weightedPlots[#weightedPlots].plot
end

local function makeRoute()
	local northGate = getPoint("NorthGate")
	local southGate = getPoint("SouthGate")
	local center = getPoint("Center")
	local westLoop = getPoint("WestLoop")
	local eastLoop = getPoint("EastLoop")
	if not northGate or not southGate or not center or not westLoop or not eastLoop then
		return nil
	end

	local startPoint = math.random(1, 2) == 1 and northGate or southGate
	local endPoint = startPoint == northGate and southGate or northGate
	local loopPoint = math.random(1, 2) == 1 and westLoop or eastLoop
	local route = { startPoint, center, loopPoint }

	if math.random() < plazaConfig.VisitorRouteChance then
		local plot = chooseVisitorPlot()
		if plot then
			table.insert(route, Vector3.new(0, 2.2, plot.floor.Position.Z))
			table.insert(route, getPlotEntrancePoint(plot))
			table.insert(route, Vector3.new(0, 2.2, plot.floor.Position.Z))
		end
	end

	table.insert(route, center)
	table.insert(route, endPoint)
	return route
end

local function moveModelTo(model, targetPosition)
	if not model.Parent or not model.PrimaryPart then
		return false
	end

	local current = model:GetPivot()
	local currentPosition = current.Position
	local flatTarget = Vector3.new(targetPosition.X, currentPosition.Y, targetPosition.Z)
	local distance = (flatTarget - currentPosition).Magnitude
	if distance < 0.05 then
		return true
	end

	local direction = flatTarget - currentPosition
	local targetCFrame = CFrame.lookAt(flatTarget, flatTarget + direction.Unit)
	local duration = math.max(0.35, distance / plazaConfig.NpcWalkSpeed)

	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Value = current
	local connection = cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(cframeValue.Value)
		end
	end)

	local tween = TweenService:Create(cframeValue, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Value = targetCFrame,
	})
	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	cframeValue:Destroy()

	return model.Parent ~= nil
end

local function runFan(model)
	task.spawn(function()
		task.wait(math.random() * 2)
		while running and model.Parent do
			local route = makeRoute()
			if route and #route >= 2 then
				model:PivotTo(CFrame.lookAt(route[1], route[2]))
				for index = 2, #route do
					if not moveModelTo(model, route[index]) then
						return
					end
					task.wait(math.random(8, 22) / 100)
				end
			else
				task.wait(1)
			end
		end
	end)
end

function CrowdService.Init(baseService, dataService)
	if running then
		return
	end

	BaseService = baseService
	DataService = dataService
	running = true

	task.spawn(function()
		local basesFolder = Workspace:WaitForChild("PlayerBases", 10)
		if not basesFolder then
			return
		end

		if fanFolder and fanFolder.Parent then
			fanFolder:Destroy()
		end

		fanFolder = make("Folder", {
			Name = "FanCrowd",
		}, basesFolder)

		for index = 1, plazaConfig.CrowdNpcCount do
			local fan = createFanNpc(index)
			runFan(fan)
		end
	end)
end

function CrowdService.Stop()
	running = false
	if fanFolder then
		fanFolder:Destroy()
		fanFolder = nil
	end
end

return CrowdService
