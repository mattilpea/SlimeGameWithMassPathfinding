--@mattilpea

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")

local SlimeInfo = require(script.Parent.SlimeInfo)
local NoobPath = require(ServerScriptService.Libraries.NoobPath)

local AllSlimes = workspace.AllSlimes
local AllCharacters = workspace.AllCharacters

local Animations = ServerStorage.SlimeAnimations

local SlimeAI = {}

-- =========================
-- SHARED TARGET CACHE (IMPORTANT)
-- =========================
local cachedTarget = {}
local targetTimer = 0

local function getNearest(pos)
	local best, bestChar
	local dist = math.huge

	for _, c in ipairs(AllCharacters:GetChildren()) do
		local root = c.PrimaryPart
		if root then
			local d = (root.Position - pos).Magnitude
			if d < dist then
				dist = d
				best = root
				bestChar = c
			end
		end
	end

	return best, bestChar
end

-- update target cache globally (NOT per slime spam)
RunService.Heartbeat:Connect(function(dt)
	targetTimer += dt
	if targetTimer < 0.25 then return end
	targetTimer = 0

	local slimes = AllSlimes:GetChildren()

	for i = 1, #slimes do
		local slime = slimes[i]
		local root = slime.PrimaryPart

		if root then
			local target = getNearest(root.Position)
			cachedTarget[slime] = target
		end
	end
end)

-- =========================
-- MAIN SPAWN FUNCTION
-- =========================
function SlimeAI:LoadSlime(name)

	local data = SlimeInfo[name]
	local model = data.SlimeModel:Clone()
	model.Parent = AllSlimes

	local root = model.PrimaryPart

	-- movement setup
	local att = Instance.new("Attachment")
	att.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = math.huge
	lv.Parent = root

	local ao = Instance.new("AlignOrientation")
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.RigidityEnabled = true
	ao.MaxTorque = math.huge
	ao.Responsiveness = 80
	ao.Parent = root

	-- health
	local health = Instance.new("IntValue")
	health.Value = 100
	health.Parent = model

	-- lock Y rotation helper
	local function lockY(pos)
		local dir = pos - root.Position
		dir = Vector3.new(dir.X, 0, dir.Z)

		if dir.Magnitude > 0.01 then
			ao.CFrame = CFrame.lookAt(Vector3.zero, dir.Unit)
		end
	end

	-- NoobPath
	local jumpEvent = Instance.new("BindableEvent")
	local moveEvent = Instance.new("BindableEvent")

	local slime = NoobPath.new(
		model,
		{WaypointSpacing = 5, AgentCanJump = true},

		function(pos)
			if not model.Parent then return end

			local offset = pos - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)

			if flat.Magnitude > 0 then
				local dir = flat.Unit

				lv.VectorVelocity = Vector3.new(
					dir.X * data.Speed,
					-4,
					dir.Z * data.Speed
				)

				lockY(pos)
			end
		end,

		function()
			jumpEvent:Fire()
		end,

		jumpEvent.Event,
		moveEvent.Event
	)

	-- =========================
	-- SINGLE UPDATE LOOP PER SLIME (THROTTLED)
	-- =========================
	local cooldown = 0

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not model.Parent then
			conn:Disconnect()
			return
		end

		cooldown -= dt
		if cooldown > 0 then return end
		cooldown = 0.35 -- IMPORTANT: performance limiter

		local target = cachedTarget[model]
		if not target then return end

		slime:Run(target.Position)
	end)

	return model
end

return SlimeAI