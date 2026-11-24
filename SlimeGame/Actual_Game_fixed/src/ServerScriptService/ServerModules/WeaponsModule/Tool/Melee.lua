--!strict

local Melee = {}

function Melee.GetHits(character: Model, range: number, radians: number): {Model}
	local root = character:FindFirstChild("HumanoidRootPart")
	local allSlimes = workspace:FindFirstChild("AllSlimes")
	if not root or not root:IsA("BasePart") or not allSlimes then
		return {}
	end

	local flatForward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if flatForward.Magnitude <= 0 then return {} end
	flatForward = flatForward.Unit

	local halfAngle = math.rad(math.clamp(radians, 1, 360) / 2)
	local threshold = math.cos(halfAngle)
	local hits = {}

	for _, slime in ipairs(allSlimes:GetChildren()) do
		if slime:IsA("Model") and slime.PrimaryPart then
			local offset = slime.PrimaryPart.Position - root.Position
			local flatOffset = Vector3.new(offset.X, 0, offset.Z)
			if flatOffset.Magnitude > 0
				and flatOffset.Magnitude <= range
				and flatForward:Dot(flatOffset.Unit) >= threshold then
				table.insert(hits, slime)
			end
		end
	end

	return hits
end

return Melee