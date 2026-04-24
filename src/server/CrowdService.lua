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

local STANDING_PIVOT_HEIGHT = 2.8
local STAND_TIERS = {
	{ zOffset = 24.2, surfaceY = 1.9 },
	{ zOffset = 27.1, surfaceY = 2.8 },
	{ zOffset = 30.0, surfaceY = 3.7 },
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

-- True R6-style character. Pivot (HumanoidRootPart) at Y=2.8 (waist) matches plaza waypoints.
-- Humanoid + R6 part names + SpecialMesh Head + face Decal make Roblox treat this as a real player.
local function createFanNpc(index)
	local model = make("Model", {
		Name = "FanNPC" .. index,
	}, fanFolder)

	local shirtColor = shirtColors[math.random(1, #shirtColors)]
	local skinColor = skinColors[math.random(1, #skinColors)]
	-- Randomise pants so each NPC looks distinct
	local pantsColor = Color3.fromRGB(
		math.random(42, 95),
		math.random(45, 95),
		math.random(48, 105)
	)

	-- ── HumanoidRootPart ────────────────────────────────────────────
	-- Invisible waist-level anchor; PivotTo drives the whole model.
	local hrp = make("Part", {
		Name = "HumanoidRootPart",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(2, 2, 1),
		CFrame = CFrame.new(0, STANDING_PIVOT_HEIGHT, 0),
	}, model)
	model.PrimaryPart = hrp

	-- ── Humanoid ─────────────────────────────────────────────────────
	-- Tells Roblox's renderer this is a character; suppresses health bar.
	make("Humanoid", {
		DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None,
		HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff,
		MaxHealth = 100,
		Health = 100,
	}, model)

	-- ── Torso ────────────────────────────────────────────────────────
	-- Classic R6 2×2×1, shirt colour, sits at waist (same Y as HRP).
	make("Part", {
		Name = "Torso",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = shirtColor,
		Size = Vector3.new(2, 2, 1),
		CFrame = CFrame.new(0, STANDING_PIVOT_HEIGHT, 0),
	}, model)

	-- ── Head ─────────────────────────────────────────────────────────
	-- 2×1×1 Part with the classic MeshType.Head (rounded block shape)
	-- and the default Roblox face decal — this is what makes NPCs read
	-- as real players instead of coloured boxes.
	local head = make("Part", {
		Name = "Head",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(2, 1, 1),
		CFrame = CFrame.new(0, STANDING_PIVOT_HEIGHT + 1.7, 0),
	}, model)

	make("SpecialMesh", {
		MeshType = Enum.MeshType.Head,
		Scale = Vector3.new(1.25, 1.25, 1.25),
	}, head)

	make("Decal", {
		Texture = "rbxasset://textures/face.png",
		Face = Enum.NormalId.Front,
	}, head)

	-- ── Arms ─────────────────────────────────────────────────────────
	-- R6 names use a space ("Left Arm") — Roblox requires this spelling.
	make("Part", {
		Name = "Left Arm",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(1, 2, 1),
		CFrame = CFrame.new(-1.5, STANDING_PIVOT_HEIGHT, 0),
	}, model)

	make("Part", {
		Name = "Right Arm",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = skinColor,
		Size = Vector3.new(1, 2, 1),
		CFrame = CFrame.new(1.5, STANDING_PIVOT_HEIGHT, 0),
	}, model)

	-- ── Legs ─────────────────────────────────────────────────────────
	-- Legs overlap the torso slightly so they stay visible on every plaza material.
	make("Part", {
		Name = "Left Leg",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = pantsColor,
		Size = Vector3.new(0.95, 2.25, 0.95),
		CFrame = CFrame.new(-0.5, 1.18, 0),
	}, model)

	make("Part", {
		Name = "Right Leg",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = pantsColor,
		Size = Vector3.new(0.95, 2.25, 0.95),
		CFrame = CFrame.new(0.5, 1.18, 0),
	}, model)

	return model
end

local function setPartLocal(model, partName, localCFrame, size)
	local part = model:FindFirstChild(partName)
	if not part or not part:IsA("BasePart") then
		return
	end

	if size then
		part.Size = size
	end
	part.CFrame = model:GetPivot() * localCFrame
end

local function setFanPose(model, pose)
	if not model.Parent then
		return
	end

	if pose == "seated" then
		setPartLocal(model, "Torso", CFrame.new(0, 0, 0), Vector3.new(2, 1.65, 1))
		setPartLocal(model, "Head", CFrame.new(0, 1.35, -0.03), Vector3.new(2, 1, 1))
		setPartLocal(model, "Left Arm", CFrame.new(-1.45, -0.1, -0.05) * CFrame.Angles(math.rad(-8), 0, 0), Vector3.new(1, 1.65, 1))
		setPartLocal(model, "Right Arm", CFrame.new(1.45, -0.1, -0.05) * CFrame.Angles(math.rad(-8), 0, 0), Vector3.new(1, 1.65, 1))
		setPartLocal(model, "Left Leg", CFrame.new(-0.5, -0.68, -0.75) * CFrame.Angles(math.rad(82), 0, 0), Vector3.new(0.9, 1.75, 0.9))
		setPartLocal(model, "Right Leg", CFrame.new(0.5, -0.68, -0.75) * CFrame.Angles(math.rad(82), 0, 0), Vector3.new(0.9, 1.75, 0.9))
		return
	end

	setPartLocal(model, "Torso", CFrame.new(0, 0, 0), Vector3.new(2, 2, 1))
	setPartLocal(model, "Head", CFrame.new(0, 1.7, 0), Vector3.new(2, 1, 1))
	setPartLocal(model, "Left Arm", CFrame.new(-1.5, 0, 0), Vector3.new(1, 2, 1))
	setPartLocal(model, "Right Arm", CFrame.new(1.5, 0, 0), Vector3.new(1, 2, 1))
	setPartLocal(model, "Left Leg", CFrame.new(-0.5, -1.62, 0), Vector3.new(0.95, 2.25, 0.95))
	setPartLocal(model, "Right Leg", CFrame.new(0.5, -1.62, 0), Vector3.new(0.95, 2.25, 0.95))
end

local function getPlotEntrancePoint(plot)
	local floorPosition = plot.floor.Position
	local frontX = floorPosition.X + (plot.facingDirection * ((layout.PlotSize.X / 2) + 7))
	return Vector3.new(frontX, STANDING_PIVOT_HEIGHT, floorPosition.Z)
end

local function getPlotSeatPoint(plot)
	local floorPosition = plot.floor.Position
	local tier = STAND_TIERS[math.random(1, #STAND_TIERS)]
	local sideZ = math.random(1, 2) == 1 and -1 or 1
	local xSpread = math.random(-18, 18)
	local x = floorPosition.X + (xSpread * plot.facingDirection)
	local z = floorPosition.Z + (sideZ * tier.zOffset)
	local pivotY = tier.surfaceY + 1.25
	return Vector3.new(x, pivotY, z)
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
	local route = {
		{ position = startPoint },
		{ position = center },
		{ position = loopPoint },
	}

	if math.random() < plazaConfig.VisitorRouteChance then
		local plot = chooseVisitorPlot()
		if plot then
			local stadiumPathPoint = Vector3.new(0, STANDING_PIVOT_HEIGHT, plot.floor.Position.Z)
			table.insert(route, { position = stadiumPathPoint })
			table.insert(route, { position = getPlotEntrancePoint(plot), pause = 0.35 })
			table.insert(route, {
				position = getPlotSeatPoint(plot),
				pause = math.random(plazaConfig.StadiumVisitPauseMin, plazaConfig.StadiumVisitPauseMax),
				-- After arriving, pivot to face the pitch centre so fans watch the game.
				lookAt = plot.floor.Position,
				pose = "seated",
			})
			table.insert(route, { position = getPlotEntrancePoint(plot), pause = 0.2 })
			table.insert(route, { position = stadiumPathPoint })
		end
	end

	table.insert(route, { position = center })
	table.insert(route, { position = endPoint })
	return route
end

local function getStepPosition(step)
	return typeof(step) == "Vector3" and step or step.position
end

local function moveModelTo(model, targetPosition)
	if not model.Parent or not model.PrimaryPart then
		return false
	end

	local current = model:GetPivot()
	local currentPosition = current.Position
	local distance = (targetPosition - currentPosition).Magnitude
	if distance < 0.05 then
		return true
	end

	local direction = targetPosition - currentPosition
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
	local targetCFrame
	if horizontalDirection.Magnitude > 0.05 then
		targetCFrame = CFrame.lookAt(targetPosition, targetPosition + horizontalDirection.Unit)
	else
		targetCFrame = CFrame.new(targetPosition) * (current - currentPosition)
	end
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
				setFanPose(model, "standing")
				local startPoint = getStepPosition(route[1])
				local nextPoint = getStepPosition(route[2])
				model:PivotTo(CFrame.lookAt(startPoint, nextPoint))
				setFanPose(model, "standing")
				for index = 2, #route do
					local step = route[index]
					local targetPosition = getStepPosition(step)
					if typeof(step) ~= "table" or step.pose ~= "seated" then
						setFanPose(model, "standing")
					end
					if not moveModelTo(model, targetPosition) then
						return
					end
					-- If this step has a look-at target (e.g. fans facing the pitch while seated),
					-- snap the pivot to face that point before the pause begins.
					if typeof(step) == "table" and step.lookAt and model.Parent then
						local pivot = model:GetPivot()
						local flatLookAt = Vector3.new(step.lookAt.X, pivot.Position.Y, step.lookAt.Z)
						local delta = flatLookAt - pivot.Position
						if delta.Magnitude > 0.5 then
							model:PivotTo(CFrame.lookAt(pivot.Position, flatLookAt))
						end
					end
					if typeof(step) == "table" and step.pose == "seated" then
						setFanPose(model, "seated")
					end
					if typeof(step) == "table" and step.pause and step.pause > 0 then
						task.wait(step.pause)
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
