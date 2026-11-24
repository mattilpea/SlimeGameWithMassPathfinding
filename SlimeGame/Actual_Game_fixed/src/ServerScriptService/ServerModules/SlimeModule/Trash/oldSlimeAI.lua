--@mattilpea

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local SlimeInfo = require(script.Parent.SlimeInfo)

local AllSlimes = workspace.AllSlimes
local AllCharacters = workspace.AllCharacters

------------------------------------------------
-- SLIME DATA
------------------------------------------------

local SlimeAI = {}

------------------------------------------------
-- CLEAN RAYCAST SYSTEM (REWRITTEN)
------------------------------------------------

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function raycast(origin, direction, distance)
	rayParams.FilterDescendantsInstances = {
		AllSlimes,
		AllCharacters,
		workspace.rayVisuals
	}

	local dir = direction.Unit * distance
	return workspace:Raycast(origin, dir, rayParams)
end

local function canSee(a: Vector3, b: Vector3)
	local dir = b - a
	local result = raycast(a, dir, dir.Magnitude)
	return result == nil
end

------------------------------------------------
-- TARGET FINDER
------------------------------------------------

local function getNearestTarget(rootPos: Vector3)
	local nearest, dist = nil, math.huge

	for _, inst in ipairs(AllCharacters:GetChildren()) do
		local pos

		if inst:IsA("Model") and inst.PrimaryPart then
			pos = inst.PrimaryPart.Position
		elseif inst:IsA("BasePart") then
			pos = inst.Position
		end

		if pos then
			local d = (pos - rootPos).Magnitude
			if d < dist then
				dist = d
				nearest = pos
			end
		end
	end

	return nearest or rootPos
end

------------------------------------------------
-- NODE SYSTEM
------------------------------------------------

local function getNodePos(node)
	if node:IsA("BasePart") then
		return node.Position
	elseif node:IsA("Model") and node.PrimaryPart then
		return node.PrimaryPart.Position
	end
end

local currentMap = workspace.CurrentMap
local nodesFolder = currentMap:FindFirstChildOfClass("Model"):FindFirstChild("Nodes")
local nodes = nodesFolder:GetChildren()

local function nearestNode(pos)
	local best, bestDist = nil, math.huge

	for _, n in ipairs(nodes) do
		local p = getNodePos(n)
		if p then
			local d = (p - pos).Magnitude
			if d < bestDist then
				bestDist = d
				best = n
			end
		end
	end

	return best
end

------------------------------------------------
-- A* PATHFINDING
------------------------------------------------

local function heuristic(a, b)
	return (a - b).Magnitude
end

local function aStar(startPos, goalPos)
	local startNode = nearestNode(startPos)
	local goalNode = nearestNode(goalPos)

	if not startNode or not goalNode then return nil end

	local open = { startNode }
	local cameFrom = {}

	local g = {}
	local f = {}

	for _, n in ipairs(nodes) do
		g[n] = math.huge
		f[n] = math.huge
	end

	g[startNode] = 0
	f[startNode] = heuristic(getNodePos(startNode), goalPos)

	while #open > 0 do
		local bestIndex = 1

		for i, n in ipairs(open) do
			if f[n] < f[open[bestIndex]] then
				bestIndex = i
			end
		end

		local current = table.remove(open, bestIndex)

		if current == goalNode then
			local path = {}
			local temp = current

			while temp do
				table.insert(path, 1, getNodePos(temp))
				temp = cameFrom[temp]
			end

			table.insert(path, goalPos)
			return path
		end

		local curPos = getNodePos(current)

		for _, neighbor in ipairs(nodes) do
			if neighbor ~= current then
				local nPos = getNodePos(neighbor)

				if nPos and canSee(curPos, nPos) then
					local tentative = g[current] + (curPos - nPos).Magnitude

					if tentative < g[neighbor] then
						cameFrom[neighbor] = current
						g[neighbor] = tentative
						f[neighbor] = tentative + heuristic(nPos, goalPos)

						if not table.find(open, neighbor) then
							table.insert(open, neighbor)
						end
					end
				end
			end
		end
	end

	return nil
end

------------------------------------------------
-- SLIME SPAWN
------------------------------------------------

function SlimeAI:LoadSlime(SlimeName)
	local slimeData = SlimeInfo[SlimeName]
	local model = slimeData.SlimeModel:Clone()
	model.Parent = AllSlimes

	local root = model.PrimaryPart

	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = attachment
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = 1e6
	lv.Parent = root

	local ao = Instance.new("AlignOrientation")
	ao.Attachment0 = attachment
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.RigidityEnabled = true
	ao.Responsiveness = 100
	ao.MaxTorque = math.huge
	ao.Parent = root

	local gravity = -4

	------------------------------------------------
	-- PATH STATE
	------------------------------------------------
	local path
	local index = 1
	local repath = 0

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not root or not root:IsDescendantOf(workspace) then
			conn:Disconnect()
			return
		end

		local target = getNearestTarget(root.Position)

		------------------------------------------------
		-- A* REPATH
		------------------------------------------------
		repath += 1/30

		if repath > 0.5 or not path then
			path = aStar(root.Position, target)
			index = 1
			repath = 0
		end

		local moveTarget = target

		if path and path[index] then
			moveTarget = path[index]

			if (root.Position - moveTarget).Magnitude < 3 then
				index += 1
			end
		end

		local dir = moveTarget - root.Position
		if dir.Magnitude > 0 then
			dir = dir.Unit
		end

		lv.VectorVelocity = Vector3.new(
			dir.X * slimeData.Speed,
			gravity,
			dir.Z * slimeData.Speed
		)

		local lookDir = moveTarget - root.Position
		lookDir = Vector3.new(lookDir.X, 0, lookDir.Z)

		if lookDir.Magnitude > 0 then
			lookDir = lookDir.Unit
		end

		ao.CFrame = CFrame.lookAt(root.Position, root.Position + lookDir, Vector3.yAxis)
	end)

	return model
end

return SlimeAI