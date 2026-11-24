--!strict

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Projectile = {}

local MAX_TRAVEL_DISTANCE = 160
local PROJECTILE_SPEED = 90

local function getProjectileTemplate(tool: Tool): BasePart?
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("MeshPart") and string.find(descendant.Name, "Icosphere", 1, true) then
			return descendant
		end
	end
	return nil
end

local function getImpactPosition(tool: Tool, character: Model, aimPosition: Vector3): (Vector3, Vector3)
	local handle = tool:FindFirstChild("Handle")
	local origin = if handle and handle:IsA("BasePart")
		then handle.Position
		else character:GetPivot().Position

	local offset = aimPosition - origin
	if offset.Magnitude <= 0.01 then
		offset = character:GetPivot().LookVector
	end

	local distance = math.min(offset.Magnitude, MAX_TRAVEL_DISTANCE)
	local direction = offset.Unit * distance

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)
	return origin, if result then result.Position else origin + direction
end

local function createImpactEffect(position: Vector3, radius: number)
	local pulse = Instance.new("Part")
	pulse.Name = "FireballImpact"
	pulse.Shape = Enum.PartType.Ball
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanTouch = false
	pulse.CanQuery = false
	pulse.Material = Enum.Material.Neon
	pulse.Color = Color3.fromRGB(255, 95, 25)
	pulse.Transparency = 0.2
	pulse.Size = Vector3.new(1, 1, 1)
	pulse.Position = position
	pulse.Parent = workspace

	local targetSize = math.max(4, radius * 2)
	TweenService:Create(
		pulse,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(targetSize, targetSize, targetSize), Transparency = 1}
	):Play()
	Debris:AddItem(pulse, 0.3)
end

function Projectile.GetAOEHits(position: Vector3, radius: number): {Model}
	local allSlimes = workspace:FindFirstChild("AllSlimes")
	if not allSlimes then return {} end

	local hits = {}
	for _, slime in ipairs(allSlimes:GetChildren()) do
		if slime:IsA("Model") and slime.PrimaryPart
			and (slime.PrimaryPart.Position - position).Magnitude <= radius then
			table.insert(hits, slime)
		end
	end
	return hits
end

function Projectile.Launch(
	tool: Tool,
	character: Model,
	aimPosition: Vector3,
	impactRadius: number,
	onImpact: (Vector3) -> ()
): boolean
	local template = getProjectileTemplate(tool)
	if not template then
		warn("Projectile mesh not found in tool:", tool.Name)
		return false
	end

	local origin, impactPosition = getImpactPosition(tool, character, aimPosition)
	local projectile = template:Clone()
	projectile.Name = "FireballProjectile"
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CanTouch = false
	projectile.CanQuery = false
	projectile.Massless = true
	projectile.CFrame = CFrame.new(origin)
	projectile.Parent = workspace

	for _, descendant in ipairs(projectile:GetDescendants()) do
		if descendant:IsA("Trail") or descendant:IsA("Beam") then
			descendant.Enabled = true
		end
	end

	task.spawn(function()
		local distance = (impactPosition - origin).Magnitude
		local travelTime = math.clamp(distance / PROJECTILE_SPEED, 0.18, 1.5)
		local arcHeight = math.clamp(distance * 0.12, 2, 14)
		local elapsed = 0

		while projectile.Parent and elapsed < travelTime do
			elapsed += RunService.Heartbeat:Wait()
			local alpha = math.clamp(elapsed / travelTime, 0, 1)
			local horizontal = origin:Lerp(impactPosition, alpha)
			local arc = math.sin(alpha * math.pi) * arcHeight
			local position = horizontal + Vector3.new(0, arc, 0)

			local nextAlpha = math.min(alpha + 0.02, 1)
			local nextHorizontal = origin:Lerp(impactPosition, nextAlpha)
			local nextArc = math.sin(nextAlpha * math.pi) * arcHeight
			local nextPosition = nextHorizontal + Vector3.new(0, nextArc, 0)
			projectile.CFrame = CFrame.lookAt(position, nextPosition)
		end

		if not projectile.Parent then return end
		projectile.Position = impactPosition
		createImpactEffect(impactPosition, impactRadius)
		onImpact(impactPosition)
		projectile:Destroy()
	end)

	return true
end

return Projectile