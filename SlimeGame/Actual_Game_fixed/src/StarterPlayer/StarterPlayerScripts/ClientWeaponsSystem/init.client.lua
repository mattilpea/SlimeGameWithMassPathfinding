--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local AimSystem = require(script.AimSystem)

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local attackRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("WeaponAttack")
local initialized: {[Tool]: boolean} = {}

local function setTrails(tool: Tool, enabled: boolean)
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("Trail") and descendant.Name == "AttackTrail" then
			descendant.Enabled = enabled
		end
	end
end

local function initializeTool(tool: Tool)
	if initialized[tool] or not tool:GetAttribute("WeaponName") then return end
	initialized[tool] = true
	setTrails(tool, false)

	local equipped = false
	local coolingDown = false
	local slashIndex = 1
	local slashTracks = {}
	local idleTrack = nil

	local function loadAnimations()
		table.clear(slashTracks)
		idleTrack = nil

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		local animations = tool:FindFirstChild("Animations")
		if not animator or not animations then return end

		local animationAssets = {}
		for _, child in ipairs(animations:GetChildren()) do
			if child:IsA("Animation") then
				table.insert(animationAssets, child)
			end
		end
		pcall(function()
			ContentProvider:PreloadAsync(animationAssets)
		end)

		local idle = animations:FindFirstChild("Idle")
		if idle and idle:IsA("Animation") then
			idleTrack = animator:LoadAnimation(idle)
			idleTrack.Priority = Enum.AnimationPriority.Action
			idleTrack.Looped = true
		end

		for index = 1, 3 do
			local slash = animations:FindFirstChild("Slash" .. index)
			if slash and slash:IsA("Animation") then
				local track = animator:LoadAnimation(slash)
				track.Priority = Enum.AnimationPriority.Action2
				track.Looped = false
				slashTracks[index] = track
			end
		end
	end

	local function attack()
		if not equipped or coolingDown then return end
		coolingDown = true

		if not next(slashTracks) then
			loadAnimations()
		end
		local track = slashTracks[slashIndex]
		slashIndex = (slashIndex % 3) + 1
		if track then track:Play(0.05) end

		setTrails(tool, true)
		local weaponName = tool:GetAttribute("WeaponName")
		local aimPosition = player:GetMouse().Hit.Position
		attackRemote:FireServer(weaponName, aimPosition)

		task.delay(0.25, function()
			if tool.Parent then setTrails(tool, false) end
		end)
		task.delay(tool:GetAttribute("Cooldown") or 1, function()
			coolingDown = false
		end)
	end

	tool.Equipped:Connect(function()
		equipped = true
		task.defer(function()
			if not equipped then return end
			loadAnimations()
			if idleTrack then idleTrack:Play(0.15) end
		end)
		AimSystem:LockPlayer(true, attack)
	end)

	tool.Unequipped:Connect(function()
		equipped = false
		if idleTrack then idleTrack:Stop(0.15) end
		for _, track in pairs(slashTracks) do
			track:Stop(0.1)
		end
		setTrails(tool, false)
		AimSystem:LockPlayer(false)
	end)

	tool.Activated:Connect(attack)
	tool.Destroying:Connect(function()
		initialized[tool] = nil
	end)
end

for _, child in ipairs(backpack:GetChildren()) do
	if child:IsA("Tool") then initializeTool(child) end
end

backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then initializeTool(child) end
end)
