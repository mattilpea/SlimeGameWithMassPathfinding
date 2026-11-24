--!strict

local SlimeCombat = {}

function SlimeCombat.Damage(model: Model, amount: number): boolean
	if amount <= 0 or amount ~= amount then return false end

	local allSlimes = workspace:FindFirstChild("AllSlimes")
	if not allSlimes or not model:IsDescendantOf(allSlimes) then return false end

	local damageEvent = model:FindFirstChild("TakeDamage")
	if not damageEvent or not damageEvent:IsA("BindableEvent") then return false end
	damageEvent:Fire(amount)
	return true
end

return SlimeCombat