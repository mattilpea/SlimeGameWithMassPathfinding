local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer
local tool = script.Parent

local anims = tool:WaitForChild("Animations")
local cooldownVal = tool:WaitForChild("Cooldown")

local AimSystem = require(script.AimSystem)

local remote = tool:WaitForChild("SwordHit")

local DAMAGE = 50
local RANGE = 6
local WIDTH = 6
local HEIGHT = 5

local slashIndex = 1
local lastSwing = 0

local slashTracks = {}
local idleTrack

-- =========================
-- ANIMATIONS
-- =========================

local function getAnimator()
	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	return hum:WaitForChild("Animator")
end

local function loadAnimations()
	local animator = getAnimator()
	if not animator then return end

	table.clear(slashTracks)

	-- SLASHES
	for i = 1, 3 do
		local anim = anims:FindFirstChild("Slash" .. i)
		if anim then
			local track = animator:LoadAnimation(anim)
			track.Priority = Enum.AnimationPriority.Action2
			track.Looped = false
			slashTracks[i] = track
		end
	end

	-- IDLE
	local idleAnim = anims:FindFirstChild("Idle")
	if idleAnim then
		idleTrack = animator:LoadAnimation(idleAnim)
		idleTrack.Priority = Enum.AnimationPriority.Action
		idleTrack.Looped = true
	end
end

local equipped = false

tool.Equipped:Connect(function()
	loadAnimations()

	if idleTrack then
		idleTrack:Play()
	end
	
	AimSystem.LockPlayer(true)
	equipped = true
	
end)

tool.Unequipped:Connect(function()
	if idleTrack then
		idleTrack:Stop()
	end
	
	AimSystem.LockPlayer(false)
	equipped = false
end)

-- =========================
-- HITBOX
-- =========================
local function adoHitbox(showDebug)
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local SLASH_RADIUS = 7
	local HALF_ANGLE = math.rad(90) -- 180° total

	if showDebug then
		local segments = 20

		for i = 0, segments do
			local alpha = i / segments
			local angle = -HALF_ANGLE + (HALF_ANGLE * 2 * alpha)

			local offset =
				(CFrame.fromAxisAngle(Vector3.yAxis, angle).LookVector * SLASH_RADIUS)

			local p = Instance.new("Part")
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(0.5, 0.5, 0.5)
			p.Anchored = true
			p.CanCollide = false
			p.Material = Enum.Material.Neon
			p.Position =
				root.Position +
				Vector3.new(0, 1, 0) +
				root.CFrame:VectorToWorldSpace(offset)

			p.Parent = workspace
			Debris:AddItem(p, 0.2)
		end
	end

	local forward = Vector3.new(
		root.CFrame.LookVector.X,
		0,
		root.CFrame.LookVector.Z
	).Unit

	local COS_THRESHOLD = math.cos(HALF_ANGLE)

	local hitModels = {}

	for _, slime in ipairs(workspace.AllSlimes:GetChildren()) do
		local slimeRoot = slime:FindFirstChild("HumanoidRootPart")

		if slimeRoot then
			local offset = slimeRoot.Position - root.Position
			local flatOffset = Vector3.new(offset.X, 0, offset.Z)

			local distance = flatOffset.Magnitude

			if distance <= SLASH_RADIUS and distance > 0 then
				local dir = flatOffset.Unit

				if forward:Dot(dir) >= COS_THRESHOLD then
					hitModels[slime] = true
				end
			end
		end
	end

	if next(hitModels) then
		local list = {}

		for model in pairs(hitModels) do
			table.insert(list, model)
		end

		remote:FireServer(list)
	end
end

local function doHitbox(showDebug)
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- =========================
	-- CONFIG
	-- =========================
	local SLASH_RADIUS = 10
	local HALF_ANGLE = math.rad(80) -- 160° total (better than full 180°)
	local COS_THRESHOLD = math.cos(HALF_ANGLE)

	local forward = root.CFrame.LookVector

	-- =========================
	-- DEBUG VISUAL (3D CONE)
	-- =========================
	if showDebug then
		local yawSteps = 16
		local pitchSteps = 8

		for yaw = -HALF_ANGLE, HALF_ANGLE, (HALF_ANGLE * 2) / yawSteps do
			for pitch = -HALF_ANGLE/2, HALF_ANGLE/2, (HALF_ANGLE) / pitchSteps do

				local localDir = CFrame.Angles(-pitch, yaw, 0).LookVector
				local worldDir = root.CFrame:VectorToWorldSpace(localDir)

				local p = Instance.new("Part")
				p.Shape = Enum.PartType.Ball
				p.Size = Vector3.new(0.35, 0.35, 0.35)
				p.Anchored = true
				p.CanCollide = false
				p.Material = Enum.Material.Neon
				p.Color = Color3.fromRGB(255, 80, 80)

				p.Position = root.Position + worldDir * SLASH_RADIUS
				p.Parent = workspace

				game:GetService("Debris"):AddItem(p, 0.15)
			end
		end
	end

	-- =========================
	-- HIT DETECTION
	-- =========================
	local hitModels = {}

	for _, slime in ipairs(workspace.AllSlimes:GetChildren()) do
		local slimeRoot = slime:FindFirstChild("HumanoidRootPart")

		if slimeRoot then
			local offset = slimeRoot.Position - root.Position
			local dist = offset.Magnitude

			if dist > 0 and dist <= SLASH_RADIUS then
				local dir = offset.Unit

				-- closer targets = easier hit
				local strength = math.clamp(dist / SLASH_RADIUS, 0, 1)
				local adjustedThreshold = COS_THRESHOLD - (0.12 * strength)

				if forward:Dot(dir) >= adjustedThreshold then
					hitModels[slime] = true
				end
			end
		end
	end

	-- =========================
	-- SEND TO SERVER
	-- =========================
	if next(hitModels) then
		local list = {}

		for model in pairs(hitModels) do
			table.insert(list, model)
		end
		
		remote:FireServer(list)
	end
end

local function whenActivate()
	if equipped then
		local now = tick()
		if now - lastSwing < cooldownVal.Value then return end
		lastSwing = now

		-- play slash animation instantly
		local track = slashTracks[slashIndex]
		slashIndex = (slashIndex % 3) + 1

		if track then
			track:Play()
		end

		-- send hitbox to server
		doHitbox(true)
	end
end

-- =========================
-- ATTACK
-- =========================
tool.Activated:Connect(whenActivate)
player.PlayerGui.AimSytemGui.MobileFrame.Fire.Activated:Connect(whenActivate)