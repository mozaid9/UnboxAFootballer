local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)

local CrowdService = {}

local BaseService
local DataService
local fanFolder
local running = false

local plazaConfig = Constants.FanZone
local layout = Constants.BaseLayout

-- Football jersey palette — bright, varied, instantly readable as a crowd
local shirtColors = {
	Color3.fromRGB(192, 26, 26),    -- red (Arsenal / Man Utd)
	Color3.fromRGB(24, 78, 170),    -- royal blue (Chelsea)
	Color3.fromRGB(108, 174, 228),  -- sky blue (Man City)
	Color3.fromRGB(20, 110, 48),    -- green (Celtic / Forest)
	Color3.fromRGB(230, 186, 28),   -- yellow (Dortmund / Brazil)
	Color3.fromRGB(148, 20, 148),   -- purple (Fiorentina)
	Color3.fromRGB(224, 88, 24),    -- orange (Netherlands)
	Color3.fromRGB(236, 236, 236),  -- white (Real Madrid)
	Color3.fromRGB(16, 26, 86),     -- dark navy (Everton)
	Color3.fromRGB(164, 12, 58),    -- claret (Aston Villa)
	Color3.fromRGB(28, 28, 28),     -- black (Juventus)
	Color3.fromRGB(32, 96, 62),     -- dark green
	Color3.fromRGB(120, 72, 38),    -- brown / amber
}

local skinColors = {
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(199, 142, 91),
	Color3.fromRGB(141, 85, 54),
	Color3.fromRGB(246, 215, 176),
}

local STANDING_PIVOT_HEIGHT = 3.1

-- Colours for the small food/drink prop NPCs carry after a kiosk stop
local FOOD_COLORS = {
	Color3.fromRGB(255, 200, 70),   -- yellow (hot dog / chips)
	Color3.fromRGB(200, 55, 30),    -- red (drink cup)
	Color3.fromRGB(255, 140, 40),   -- orange (fanta)
	Color3.fromRGB(235, 235, 235),  -- white (popcorn)
}
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
	local plaza = basesFolder and basesFolder:FindFirstChild("FanZone")
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
		CFrame = CFrame.new(-0.5, 1.48, 0),
	}, model)

	make("Part", {
		Name = "Right Leg",
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = pantsColor,
		Size = Vector3.new(0.95, 2.25, 0.95),
		CFrame = CFrame.new(0.5, 1.48, 0),
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

-- Attaches or removes a small food/drink prop near the NPC's right hand.
-- Because all parts are anchored and moved via PivotTo, the prop stays at a
-- fixed offset from the model pivot — right arm area — automatically.
local function setFoodProp(model, enabled)
	local existing = model:FindFirstChild("FoodProp")
	if existing then
		existing:Destroy()
	end
	if not enabled or not model.Parent then
		return
	end
	local pivot = model:GetPivot()
	local propModel = make("Model", {
		Name = "FoodProp",
	}, model)
	-- Front is local -Z for CFrame.lookAt. Keep the prop high, bright, and
	-- slightly in front of the right hand so it reads clearly from gameplay view.
	local propCFrame = pivot * CFrame.new(1.72, -0.05, -0.95)
	local propColor = FOOD_COLORS[math.random(1, #FOOD_COLORS)]

	local cup = make("Part", {
		Name = "Cup",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = propColor,
		Size = Vector3.new(0.72, 0.92, 0.72),
		CFrame = propCFrame,
	}, propModel)

	make("PointLight", {
		Name = "CupGlow",
		Color = propColor,
		Range = 5,
		Brightness = 0.35,
		Shadows = false,
	}, cup)

	make("Part", {
		Name = "Lid",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 235, 160),
		Size = Vector3.new(0.80, 0.10, 0.80),
		CFrame = propCFrame * CFrame.new(0, 0.51, 0),
	}, propModel)

	make("Part", {
		Name = "Straw",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(245, 245, 245),
		Size = Vector3.new(0.10, 0.82, 0.10),
		CFrame = propCFrame * CFrame.new(0.20, 0.86, -0.06) * CFrame.Angles(0, 0, math.rad(12)),
	}, propModel)
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

-- laneOffset: X-axis nudge (studs) so each NPC walks a slightly different
-- track through the plaza — prevents them all overlapping on the centre line.
local function makeRoute(laneOffset)
	laneOffset = laneOffset or 0

	local northGate = getPoint("NorthGate")
	local southGate = getPoint("SouthGate")
	local center = getPoint("Center")
	local westLoop = getPoint("WestLoop")
	local eastLoop = getPoint("EastLoop")
	local foodCenterWest = getPoint("FoodCenterWest")
	local foodCenterEast = getPoint("FoodCenterEast")
	if not northGate or not southGate or not center or not westLoop or not eastLoop then
		return nil
	end

	-- Apply lane offset to all main-walkway positions (not stadium sub-paths).
	local function lane(pos)
		return Vector3.new(pos.X + laneOffset, pos.Y, pos.Z)
	end

	local rawStart = math.random(1, 2) == 1 and northGate or southGate
	local rawEnd   = rawStart == northGate and southGate or northGate
	local rawLoop  = math.random(1, 2) == 1 and westLoop or eastLoop

	local route = {
		{ position = lane(rawStart) },
		{ position = lane(center) },
		{ position = lane(rawLoop) },
	}

	-- Configured chance: detour to the food kiosk cluster at the centre.
	-- NPCs step toward the kiosk on their lane side, hold a prop, pause,
	-- then continue toward their loop waypoint.
	-- isFood = true tells runFan to hand a prop to the NPC before the pause.
	if math.random() < (plazaConfig.FoodStopChance or 0.30) then
		local westSide = laneOffset < 0
		local rawFood = westSide and foodCenterWest or foodCenterEast
		rawFood = rawFood or foodCenterWest or foodCenterEast  -- fallback

		if rawFood then
			local kioskSideX = westSide and -36 or 36
			-- Insert between "center" and "loop" steps so NPC passes the
			-- kiosk area naturally in the middle of their plaza walk.
			table.insert(route, 3, {
				position = rawFood,
				pause = math.random(8, 18),
				isFood = true,
				lookAt = Vector3.new(kioskSideX, rawFood.Y, 0),
			})
		end
	end

	if math.random() < plazaConfig.VisitorRouteChance then
		local plot = chooseVisitorPlot()
		if plot then
			-- Stadium sub-path: use laneOffset on the central-Z approach only
			local stadiumPathPoint = Vector3.new(laneOffset, STANDING_PIVOT_HEIGHT, plot.floor.Position.Z)
			table.insert(route, { position = stadiumPathPoint })
			table.insert(route, { position = getPlotEntrancePoint(plot), pause = 0.35 })
			table.insert(route, {
				position = getPlotSeatPoint(plot),
				pause = math.random(plazaConfig.StadiumVisitPauseMin, plazaConfig.StadiumVisitPauseMax),
				lookAt = plot.floor.Position,
				pose = "seated",
				clearFood = true,   -- drop food prop before sitting
			})
			table.insert(route, { position = getPlotEntrancePoint(plot), pause = 0.2 })
			table.insert(route, { position = stadiumPathPoint })
		end
	end

	table.insert(route, { position = lane(center) })
	table.insert(route, { position = lane(rawEnd) })
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
	-- Each NPC gets a fixed lane offset for its lifetime so it always walks
	-- a consistent track through the plaza rather than drifting to the centre.
	-- Range: ±8 studs; avoid the very centre (±1) so there's a visible gap.
	local laneSign = math.random(1, 2) == 1 and 1 or -1
	local laneOffset = laneSign * (math.random(15, 80) / 10)   -- 1.5 – 8.0 studs

	task.spawn(function()
		task.wait(math.random() * 2)
		while running and model.Parent do
			local route = makeRoute(laneOffset)
			if route and #route >= 2 then
				setFanPose(model, "standing")
				local startPoint = getStepPosition(route[1])
				local nextPoint = getStepPosition(route[2])
				model:PivotTo(CFrame.lookAt(startPoint, nextPoint))
				setFanPose(model, "standing")

				local hasFood = false

				for index = 2, #route do
					local step = route[index]
					local targetPosition = getStepPosition(step)

					if typeof(step) ~= "table" or step.pose ~= "seated" then
						setFanPose(model, "standing")
					end

					if not moveModelTo(model, targetPosition) then
						return
					end

					-- Face look-at target before pause (e.g. seated fans face the pitch)
					if typeof(step) == "table" and step.lookAt and model.Parent then
						local pivot = model:GetPivot()
						local flatLookAt = Vector3.new(step.lookAt.X, pivot.Position.Y, step.lookAt.Z)
						local delta = flatLookAt - pivot.Position
						if delta.Magnitude > 0.5 then
							model:PivotTo(CFrame.lookAt(pivot.Position, flatLookAt))
						end
					end

					-- Seated pose
					if typeof(step) == "table" and step.pose == "seated" then
						setFanPose(model, "seated")
					end

					-- Hand the NPC a prop BEFORE the pause so they hold it while
					-- waiting at the kiosk (looks like they received their order)
					if typeof(step) == "table" and step.isFood and not hasFood then
						setFoodProp(model, true)
						hasFood = true
					end

					-- Drop food prop before sitting so it doesn't float oddly
					if typeof(step) == "table" and step.clearFood and hasFood then
						setFoodProp(model, false)
						hasFood = false
					end

					if typeof(step) == "table" and step.pause and step.pause > 0 then
						task.wait(step.pause)
					end

					task.wait(math.random(8, 22) / 100)
				end

				-- Clear prop at end of route
				if hasFood then
					setFoodProp(model, false)
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
