local npc = script.Parent
local hrpOfNPC = npc:WaitForChild("HumanoidRootPart")

local plrsHit = {}

local maxDistance = math.huge

-- 🧠 Disable collisions on death
local function disableCollisions()
	for _, obj in ipairs(npc:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
		end
	end
end

-- 💀 Death handler
npc.Humanoid.Died:Connect(function()
	print("[Slime] Died -> disabling collisions")
	disableCollisions()
	task.wait(1)
	npc:Destroy()
end)

-- 👊 Damage on touch
npc.Humanoid.Touched:Connect(function(touch)
	local plr = game.Players:GetPlayerFromCharacter(touch.Parent)

	if plr and not plrsHit[plr] then
		plrsHit[plr] = true

		touch.Parent.Humanoid:TakeDamage(20)

		task.wait(1)

		plrsHit[plr] = nil
	end
end)

-- 🤖 Chase nearest player
while task.wait() do
	local plrs = game.Players:GetPlayers()

	local closestHRP

	for _, plr in pairs(plrs) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 then

			local hrp = plr.Character.HumanoidRootPart
			local distanceBetween = (hrpOfNPC.Position - hrp.Position).Magnitude

			if not closestHRP then
				closestHRP = hrp
			end

			if (hrpOfNPC.Position - closestHRP.Position).Magnitude > distanceBetween then
				closestHRP = hrp
			end
		end
	end

	if closestHRP and (hrpOfNPC.Position - closestHRP.Position).Magnitude <= maxDistance then
		npc.Humanoid:MoveTo(closestHRP.Position)
	end
end