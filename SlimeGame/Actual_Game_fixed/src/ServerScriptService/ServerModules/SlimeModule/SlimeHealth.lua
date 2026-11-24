--!strict

local SlimeHealth = {}

function SlimeHealth.Setup(slimeState)
	local health = slimeState.Slime.Data.Health or slimeState.Slime.Data.health or 1

	slimeState.Health = health
	slimeState.MaxHealth = health
	slimeState.Dead = false
end

function SlimeHealth.TakeDamage(slimeState, damage: number)
	if slimeState.Dead then
		return
	end

	slimeState.Health -= damage

	if slimeState.Health <= 0 then
		slimeState.Dead = true

		if slimeState.Animator then
			slimeState.Animator:Play("Death")
		end

		task.delay(1, function()
			if slimeState.Slime and slimeState.Slime.Model then
				slimeState.Slime.Model:Destroy()
			end
		end)

		return
	end

	if slimeState.Animator then
		slimeState.Animator:Play("Hit")
	end
end

return SlimeHealth