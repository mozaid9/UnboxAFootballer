local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local RequestPitchforkHit = Remotes:WaitForChild("RequestPitchforkHit")

local boundTools = {}
local localSwingLocked = false

local function bindPitchfork(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Pitchfork" or boundTools[tool] then
		return
	end

	boundTools[tool] = true
	tool.Activated:Connect(function()
		if localSwingLocked then
			return
		end

		localSwingLocked = true
		RequestPitchforkHit:FireServer()
		task.delay(0.1, function()
			localSwingLocked = false
		end)
	end)
end

local function watchContainer(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		bindPitchfork(child)
	end

	container.ChildAdded:Connect(function(child)
		bindPitchfork(child)
	end)
end

watchContainer(player:WaitForChild("Backpack"))

if player.Character then
	watchContainer(player.Character)
end

player.CharacterAdded:Connect(function(character)
	watchContainer(character)
end)
