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

local FOOD_TYPES = {
	Popcorn = true,
	HotDog = true,
	Burger = true,
	Drink = true,
}
local STAND_TIERS = {
	{ zOffset = 24.2, surfaceY = 1.9 },
	{ zOffset = 27.1, surfaceY = 2.8 },
	{ zOffset = 30.0, surfaceY = 3.7 },
}

-- ── Stall queue system ─────────────────────────────────────────────
-- Each food stall has 4 queue slots (waypoints "Food<Stall>1"…"Food<Stall>4"
-- in BaseService).  When an NPC decides to visit a stall it claims the
-- lowest free slot, walks there, holds it through its food pause, then
-- releases it as it walks away.  This produces a real-looking line
-- instead of every NPC piling onto the same spot.
local QUEUE_SLOTS_PER_STALL = 4
local STALL_NAMES = { "Popcorn", "HotDogs", "Burgers", "Drinks" }

local STALL_FOOD_TYPE = {
	Popcorn = "Popcorn",
	HotDogs = "HotDog",
	Burgers = "Burger",
	Drinks  = "Drink",
}

-- World-space position of each stall's counter (matches BaseService).
-- Used as the lookAt target so queued NPCs face the worker, not the plaza.
local STALL_LOOK_AT = {
	Popcorn = Vector3.new(-36, STANDING_PIVOT_HEIGHT, -15),
	HotDogs = Vector3.new( 36, STANDING_PIVOT_HEIGHT, -15),
	Burgers = Vector3.new(-36, STANDING_PIVOT_HEIGHT,  15),
	Drinks  = Vector3.new( 36, STANDING_PIVOT_HEIGHT,  15),
}

-- Which stalls are reachable from each side of the main walkway.  A fan
-- with a negative laneOffset is on the west track and visits west stalls.
local WEST_STALLS = { "Popcorn", "Burgers" }
local EAST_STALLS = { "HotDogs", "Drinks" }

local stallQueueState = {}
for _, stallName in ipairs(STALL_NAMES) do
	local slots = table.create(QUEUE_SLOTS_PER_STALL, false)
	stallQueueState[stallName] = slots
end

-- Returns the lowest free slot index (1 = front of line) and marks it
-- taken, or nil if all slots are in use.
local function claimStallSlot(stallName)
	local state = stallQueueState[stallName]
	if not state then
		return nil
	end
	for i = 1, QUEUE_SLOTS_PER_STALL do
		if not state[i] then
			state[i] = true
			return i
		end
	end
	return nil
end

local function releaseStallSlot(stallName, slotIndex)
	local state = stallQueueState[stallName]
	if state and slotIndex and state[slotIndex] then
		state[slotIndex] = false
	end
end

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
local function setFoodProp(model, foodType)
	local existing = model:FindFirstChild("FoodProp")
	if existing then
		existing:Destroy()
	end
	if not foodType or not model.Parent then
		return
	end

	local selectedType = FOOD_TYPES[foodType] and foodType or "Drink"
	local pivot = model:GetPivot()
	local propModel = make("Model", {
		Name = "FoodProp",
	}, model)
	-- Front is local -Z for CFrame.lookAt. Keep the prop high, bright, and
	-- slightly in front of the right hand so it reads clearly from gameplay view.
	local propCFrame = pivot * CFrame.new(1.72, -0.05, -0.95)

	local function prop(partName, size, offset, color, material, shape)
		return make("Part", {
			Name = partName,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = material or Enum.Material.SmoothPlastic,
			Color = color,
			Shape = shape or Enum.PartType.Block,
			Size = size,
			CFrame = propCFrame * offset,
		}, propModel)
	end

	if selectedType == "Popcorn" then
		prop("PopcornBucket", Vector3.new(0.78, 0.72, 0.58), CFrame.new(), Color3.fromRGB(245, 238, 220))
		prop("RedStripeL", Vector3.new(0.10, 0.74, 0.60), CFrame.new(-0.20, 0, 0), Color3.fromRGB(205, 40, 32))
		prop("RedStripeR", Vector3.new(0.10, 0.74, 0.60), CFrame.new(0.20, 0, 0), Color3.fromRGB(205, 40, 32))
		for i = 1, 5 do
			local xOffset = ((i - 3) * 0.12)
			local zOffset = (i % 2 == 0) and 0.10 or -0.08
			prop("Kernel" .. i, Vector3.new(0.16, 0.16, 0.16), CFrame.new(xOffset, 0.45, zOffset), Color3.fromRGB(255, 232, 135), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
	elseif selectedType == "HotDog" then
		prop("Tray", Vector3.new(0.96, 0.08, 0.52), CFrame.new(0, -0.20, 0), Color3.fromRGB(235, 226, 190))
		prop("Bun", Vector3.new(0.86, 0.22, 0.42), CFrame.new(0, -0.02, 0), Color3.fromRGB(221, 160, 83))
		prop("Sausage", Vector3.new(0.74, 0.16, 0.18), CFrame.new(0, 0.11, 0), Color3.fromRGB(185, 48, 34))
		prop("Mustard", Vector3.new(0.56, 0.05, 0.08), CFrame.new(0, 0.22, 0), Color3.fromRGB(255, 216, 42), Enum.Material.Neon)
	elseif selectedType == "Burger" then
		prop("BottomBun", Vector3.new(0.72, 0.16, 0.54), CFrame.new(0, -0.20, 0), Color3.fromRGB(221, 160, 83))
		prop("Patty", Vector3.new(0.78, 0.14, 0.58), CFrame.new(0, -0.06, 0), Color3.fromRGB(92, 46, 24))
		prop("Lettuce", Vector3.new(0.86, 0.08, 0.64), CFrame.new(0, 0.04, 0), Color3.fromRGB(78, 180, 68))
		prop("TopBun", Vector3.new(0.70, 0.18, 0.52), CFrame.new(0, 0.18, 0), Color3.fromRGB(234, 176, 92))
	else
		prop("DrinkCup", Vector3.new(0.58, 0.86, 0.58), CFrame.new(0, 0, 0), Color3.fromRGB(58, 180, 235))
		prop("DrinkLabel", Vector3.new(0.60, 0.22, 0.06), CFrame.new(0, 0.04, -0.30), Color3.fromRGB(255, 238, 130))
		prop("Lid", Vector3.new(0.66, 0.10, 0.66), CFrame.new(0, 0.49, 0), Color3.fromRGB(245, 245, 245))
		prop("Straw", Vector3.new(0.08, 0.74, 0.08), CFrame.new(0.16, 0.78, -0.05) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(245, 245, 245))
	end
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

-- laneXOffset / laneZOffset: 2-D nudge (studs) so each NPC walks a unique
-- diagonal track through the plaza rather than converging on the centre line.
local function makeRoute(laneXOffset, laneZOffset)
	laneXOffset = laneXOffset or 0
	laneZOffset = laneZOffset or 0

	local northGate = getPoint("NorthGate")
	local southGate = getPoint("SouthGate")
	local center = getPoint("Center")
	local westLoop = getPoint("WestLoop")
	local eastLoop = getPoint("EastLoop")
	if not northGate or not southGate or not center or not westLoop or not eastLoop then
		return nil
	end

	-- Apply both offsets to all main-walkway positions (not stadium sub-paths).
	local function lane(pos)
		return Vector3.new(pos.X + laneXOffset, pos.Y, pos.Z + laneZOffset)
	end

	local rawStart = math.random(1, 2) == 1 and northGate or southGate
	local rawEnd   = rawStart == northGate and southGate or northGate
	local rawLoop  = math.random(1, 2) == 1 and westLoop or eastLoop

	-- Route: gate → trophy-bypass → loop → gate
	-- The bypass point is always ≥18 studs from the centre trophy on the NPC's
	-- own side, so even a very large base can't be clipped by a straight line.
	local TROPHY_CLEAR = 18
	local side = laneXOffset >= 0 and 1 or -1   -- derive sign locally; laneSign is in runFan scope
	local bypassX = center.X + side * math.max(TROPHY_CLEAR, math.abs(laneXOffset))
	local trophyBypass = Vector3.new(bypassX, center.Y, center.Z + laneZOffset)

	local route = {
		{ position = lane(rawStart) },
		{ position = trophyBypass },
		{ position = lane(rawLoop) },
	}

	-- Configured chance: detour to a real food stall counter.
	-- isFood + foodType tells runFan which prop to put in the NPC's hand.
	-- The fan claims a queue slot up-front (1 = front of line, 4 = back),
	-- holds it through its pause, then releases it as it walks away.  If
	-- both stalls on this side are full (4×2 = 8 fans queued), skip food.
	if math.random() < (plazaConfig.FoodStopChance or 0.30) then
		local sideStalls = (laneXOffset < 0) and WEST_STALLS or EAST_STALLS

		-- Try the two stalls on this side in random order so the same
		-- one isn't always preferred when both have room.
		local stallOrder = { sideStalls[1], sideStalls[2] }
		if math.random(1, 2) == 1 then
			stallOrder[1], stallOrder[2] = stallOrder[2], stallOrder[1]
		end

		for _, stallName in ipairs(stallOrder) do
			local slot = claimStallSlot(stallName)
			if slot then
				local waypointPos = getPoint("Food" .. stallName .. slot)
				if waypointPos then
					table.insert(route, 3, {
						position = waypointPos,
						-- Front of queue lingers longer (being served);
						-- back of queue moves on sooner so the line shifts.
						pause = (slot == 1) and math.random(10, 18) or math.random(4, 9),
						isFood = (slot == 1),  -- only the front fan receives food
						foodType = STALL_FOOD_TYPE[stallName],
						lookAt = STALL_LOOK_AT[stallName],
						stallName = stallName,
						stallSlot = slot,
					})
					break
				else
					-- Waypoint missing for some reason; release slot and try other stall.
					releaseStallSlot(stallName, slot)
				end
			end
		end
	end

	if math.random() < plazaConfig.VisitorRouteChance then
		local plot = chooseVisitorPlot()
		if plot then
			-- Stadium sub-path: carry the NPC's 2-D lane offset into the approach point
			local stadiumPathPoint = Vector3.new(laneXOffset, STANDING_PIVOT_HEIGHT, plot.floor.Position.Z + laneZOffset)
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

	table.insert(route, { position = lane(rawEnd) })
	return route
end

local function getStepPosition(step)
	return typeof(step) == "Vector3" and step or step.position
end

local function moveModelTo(model, targetPosition, npcSpeed)
	if not model.Parent or not model.PrimaryPart then
		return false
	end

	local currentCFrame = model:GetPivot()
	local currentPosition = currentCFrame.Position
	local distance = (targetPosition - currentPosition).Magnitude
	if distance < 0.05 then
		return true
	end

	local direction = targetPosition - currentPosition
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
	local startCFrame, targetCFrame
	if horizontalDirection.Magnitude > 0.05 then
		-- Snap facing direction immediately so the NPC never slides sideways
		startCFrame  = CFrame.lookAt(currentPosition, currentPosition + horizontalDirection.Unit)
		targetCFrame = CFrame.lookAt(targetPosition,  targetPosition  + horizontalDirection.Unit)
		model:PivotTo(startCFrame)
	else
		startCFrame  = currentCFrame
		targetCFrame = CFrame.new(targetPosition) * (currentCFrame - currentPosition)
	end

	local duration = math.max(0.35, distance / (npcSpeed or plazaConfig.NpcWalkSpeed))

	-- Walk animation: swing arms and legs for the full duration of movement
	local walkActive = true
	task.spawn(function()
		local t = 0
		while walkActive and model.Parent do
			t += task.wait(0.04)
			if not walkActive or not model.Parent then
				break
			end
			-- Natural gait: left arm forward ↔ right leg forward, right arm forward ↔ left leg forward
			local swing = math.sin(t * math.pi * 4.5) * math.rad(28)
			setPartLocal(model, "Left Arm",  CFrame.new(-1.5,  0,     0) * CFrame.Angles( swing,       0, 0))
			setPartLocal(model, "Right Arm", CFrame.new( 1.5,  0,     0) * CFrame.Angles(-swing,       0, 0))
			setPartLocal(model, "Left Leg",  CFrame.new(-0.5, -1.62,  0) * CFrame.Angles(-swing * 0.75, 0, 0))
			setPartLocal(model, "Right Leg", CFrame.new( 0.5, -1.62,  0) * CFrame.Angles( swing * 0.75, 0, 0))
		end
	end)

	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Value = startCFrame
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
	walkActive = false

	return model.Parent ~= nil
end

local function runFan(model)
	-- Each NPC gets fixed 2-D lane offsets for its lifetime so it walks a
	-- unique diagonal through the plaza.
	-- X: ±8–13 studs left/right so NPCs clear the centre trophy.
	-- Z: ±0–5 studs front/back so NPCs spread across the full plaza width
	--    and don't all queue up on the same Z line.
	-- Speed: ±18 % variation so fast NPCs naturally overtake slow ones and
	--        the crowd looks alive rather than a synchronised march.
	local laneSign   = math.random(1, 2) == 1 and 1 or -1
	local laneXOffset = laneSign * (math.random(80, 130) / 10)          -- 8.0 – 13.0 studs
	local laneZOffset = (math.random(-50, 50) / 10)                      -- ±5.0 studs
	local mySpeed     = plazaConfig.NpcWalkSpeed * (0.82 + math.random() * 0.36)  -- ×0.82 – ×1.18

	task.spawn(function()
		task.wait(math.random() * 7)    -- longer stagger so NPCs don't all depart at once
		while running and model.Parent do
			local route = makeRoute(laneXOffset, laneZOffset)
			if route and #route >= 2 then
				setFanPose(model, "standing")
				local startPoint = getStepPosition(route[1])
				local nextPoint = getStepPosition(route[2])
				model:PivotTo(CFrame.lookAt(startPoint, nextPoint))
				setFanPose(model, "standing")

				local hasFood = false
				local heldStallName, heldStallSlot = nil, nil
				local function releaseHeldSlot()
					if heldStallName and heldStallSlot then
						releaseStallSlot(heldStallName, heldStallSlot)
						heldStallName, heldStallSlot = nil, nil
					end
				end

				for index = 2, #route do
					local step = route[index]
					local targetPosition = getStepPosition(step)

					if typeof(step) ~= "table" or step.pose ~= "seated" then
						setFanPose(model, "standing")
					end

					if not moveModelTo(model, targetPosition, mySpeed) then
						releaseHeldSlot()
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

					-- Track this NPC's reserved queue slot (if any) so we can
					-- release it after the pause — and via the safety net if
					-- the model gets destroyed mid-pause.
					if typeof(step) == "table" and step.stallName and step.stallSlot then
						heldStallName = step.stallName
						heldStallSlot = step.stallSlot
					end

					-- Hand the NPC a prop BEFORE the pause so they hold it while
					-- waiting at the kiosk (looks like they received their order)
					if typeof(step) == "table" and step.isFood and not hasFood then
						setFoodProp(model, step.foodType)
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

					-- NPC has finished their stall stop — free the queue slot
					-- so the next fan can move up.
					releaseHeldSlot()

					task.wait(math.random(8, 22) / 100)
				end

				-- Safety: route loop exited normally — make sure no slot is left held.
				releaseHeldSlot()

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
