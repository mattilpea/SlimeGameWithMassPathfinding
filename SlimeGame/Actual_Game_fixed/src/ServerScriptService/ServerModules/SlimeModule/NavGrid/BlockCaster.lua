local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local BlockCaster = {}

--// Debug toggle
local DEBUG = true

local function VisualizeBlock(cf: CFrame, size: Vector3, color: Color3?)
	if not DEBUG then return end

	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	p.Transparency = 0.6
	p.Color = color or Color3.fromRGB(0, 170, 255)

	p.Size = size
	p.CFrame = cf
	p.Parent = workspace.castVisuals

	Debris:AddItem(p, 0.1)
end

local function CastBlock(part: BasePart, direction: Vector3, rayParams: RaycastParams?)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {part, workspace.mapVisuals, part.Parent}

	if rayParams then
		params = rayParams
	end

	-- visualize start
	--VisualizeBlock(part.CFrame, part.Size, Color3.fromRGB(0, 170, 255))

	local result = workspace:Blockcast(
		part.CFrame,
		part.Size,
		direction,
		params
	)

	-- visualize end
	--VisualizeBlock(part.CFrame + direction, part.Size, Color3.fromRGB(255, 80, 80))

	return result
end



function BlockCaster:Register(part : BasePart, cell)
	part.Anchored = true
	local touchingParts = part:GetTouchingParts()
	
	if #touchingParts > 0 then
		cell.Casted = true
		part:Destroy()
	end
end

function BlockCaster:Cast(part: BasePart, cell)
	if not part or not part:IsA("BasePart") then
		warn(part)
		return
	end
	
	part.Anchored = false
	
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not part or not part.Parent then
			conn:Disconnect()
			return
		end

		local direction = -part.CFrame.UpVector --* (part.Size.Y / 3)
		local hit = CastBlock(part, direction)

		if hit and hit.Instance then
			part.Anchored = true
			cell["Casted"] = true
			--print("done")
			conn:Disconnect()
		end
		
	end)
end

return BlockCaster
