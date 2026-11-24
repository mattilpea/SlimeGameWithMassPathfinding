local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local weaponsInfo = require(ServerScriptService.ServerModules.WeaponsInfo)

local remote = script.Parent.SwordHit

local DAMAGE = weaponsInfo[1].Damage
local RANGE = 14

local AllSlimes = workspace:WaitForChild("AllSlimes")

local function isValid(playerRoot, slime)
	local slimeRoot = slime.PrimaryPart
	if not slimeRoot then return false end

	return (slimeRoot.Position - playerRoot.Position).Magnitude <= RANGE
end

remote.OnServerEvent:Connect(function(player, hitList)
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local hitModels = {}

	for _, slime in ipairs(hitList) do
		if typeof(slime) == "Instance"
			and slime:IsDescendantOf(AllSlimes)
			and not hitModels[slime] then

			if isValid(root, slime) then
				local health = slime:FindFirstChild("Health")
				if health and health:IsA("IntValue") then
					health.Value = math.max(0, health.Value - DAMAGE)
				end
			end

			hitModels[slime] = true
		end
	end
end)