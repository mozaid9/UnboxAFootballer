-- CardDisplayAnimator.client.lua
-- Client-side: animates displayed cards (rotation, bob, income label pulse, rarity glow).
-- Runs entirely on the client so the server carries zero animation overhead.

local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

-- ── State ─────────────────────────────────────────────────────────────────────
-- [cardPart] = { basePos, lookVec, startTime, light, topPart }
local activeCards = {}
local heartbeatConn = nil

-- ── Heartbeat (single connection for ALL cards) ───────────────────────────────
local function ensureHeartbeat()
	if heartbeatConn then return end

	heartbeatConn = RunService.Heartbeat:Connect(function()
		local now = tick()

		for cardPart, data in pairs(activeCards) do
			if not cardPart.Parent then
				activeCards[cardPart] = nil
			else
				local elapsed = now - data.startTime

				-- Slow Y rotation: full revolution every 14 seconds
				local rot = elapsed * (2 * math.pi / 14)

				-- Gentle vertical bob: ±0.22 studs, 3.5 s period
				local bobY = math.sin(elapsed * (2 * math.pi / 3.5)) * 0.22

				cardPart.CFrame = CFrame.lookAt(
					data.basePos + Vector3.new(0, bobY, 0),
					data.basePos + Vector3.new(0, bobY, 0) + data.lookVec
				) * CFrame.Angles(0, rot, 0)

				-- Breathe the rarity point-light (0.15 → 0.30 → 0.15)
				if data.light and data.light.Parent then
					local pulse = (math.sin(elapsed * 3.5) + 1) * 0.5  -- 0–1
					data.light.Brightness = 0.14 + pulse * 0.18
				end

				-- Pulse the gold top-pad transparency (subtle)
				if data.topPart and data.topPart.Parent then
					local pulse2 = (math.sin(elapsed * 2.2 + 1) + 1) * 0.5
					data.topPart.Transparency = 0.46 + pulse2 * 0.18
				end
			end
		end
	end)
end

-- ── Income label float-up-fade cycle ─────────────────────────────────────────
local function startIncomeAnimation(cardPart)
	local incomeGui = cardPart:FindFirstChild("IncomeLabel")
	if not incomeGui then return end

	local label = incomeGui:FindFirstChildOfClass("TextLabel")
	if not label then return end

	local BASE_OFFSET = incomeGui.StudsOffset

	task.spawn(function()
		while incomeGui.Parent and cardPart.Parent do
			-- Reset to base position, fully visible
			incomeGui.StudsOffset = BASE_OFFSET
			label.TextTransparency = 0

			-- Float upward + fade out over 1.5 s
			local duration = 1.5
			local rise     = 1.8  -- studs to rise
			local startT   = tick()

			while cardPart.Parent and incomeGui.Parent do
				local t = math.min((tick() - startT) / duration, 1)
				-- ease-out: fast start, slow finish
				local eased = 1 - (1 - t) ^ 2
				incomeGui.StudsOffset = BASE_OFFSET + Vector3.new(0, eased * rise, 0)
				label.TextTransparency = math.clamp(t * 1.3, 0, 1)
				if t >= 1 then break end
				task.wait()
			end

			-- Brief pause before next cycle
			task.wait(0.7)
		end
	end)
end

-- ── Register a newly-seen CardPart ────────────────────────────────────────────
local function registerCardPart(instance)
	if instance.Name ~= "CardPart" then return end
	if activeCards[instance] then return end

	-- Defer one frame so the CFrame is fully replicated from server
	task.defer(function()
		if not instance.Parent then return end

		local slotModel = instance.Parent and instance.Parent.Parent  -- DisplaySlotX model
		local topPart   = slotModel and slotModel:FindFirstChild("Top")

		activeCards[instance] = {
			basePos  = instance.CFrame.Position,
			lookVec  = -instance.CFrame.LookVector,
			startTime = tick(),
			light    = instance:FindFirstChildOfClass("PointLight"),
			topPart  = topPart,
		}

		ensureHeartbeat()
		startIncomeAnimation(instance)
	end)
end

-- ── Bootstrap: wait for PlayerBases folder ────────────────────────────────────
task.spawn(function()
	local basesFolder = Workspace:WaitForChild("PlayerBases", 20)
	if not basesFolder then
		warn("[CardDisplayAnimator] PlayerBases not found within timeout.")
		return
	end

	local function watchModel(m)
		for _, desc in ipairs(m:GetDescendants()) do
			registerCardPart(desc)
		end
		m.DescendantAdded:Connect(registerCardPart)
	end

	for _, child in ipairs(basesFolder:GetChildren()) do
		watchModel(child)
	end

	basesFolder.ChildAdded:Connect(watchModel)
end)
