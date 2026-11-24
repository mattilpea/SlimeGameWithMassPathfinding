--!strict

local SlimeMover = {}

function SlimeMover.Step(slimeState, dt: number)
	local slime = slimeState.Slime

	if not slimeState.Moving then
		return
	end

	slimeState.Alpha += dt / slimeState.TravelTime

	local t = math.clamp(slimeState.Alpha, 0, 1)
	local pos = slimeState.FromCF.Position:Lerp(slimeState.ToCF.Position, t)

	local moveDir = slimeState.ToCF.Position - slimeState.FromCF.Position
	moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)

	if moveDir.Magnitude > 0 then
		local lookCF = CFrame.lookAt(pos, pos + moveDir.Unit)
		slime.Model:PivotTo(lookCF)
	else
		slime.Model:PivotTo(CFrame.new(pos))
	end

	if t >= 1 then
		slimeState.CurrentCell = slimeState.NextCell
		slimeState.NextCell = nil
		slimeState.Moving = false
	end
end

return SlimeMover