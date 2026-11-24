--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local WeaponsModule = require(ServerScriptService.ServerModules.WeaponsModule)
local Melee = require(ServerScriptService.ServerModules.WeaponsModule.Tool.Melee)
local Projectile = require(ServerScriptService.ServerModules.WeaponsModule.Tool.Projectile)
local SlimeCombat = require(ServerScriptService.ServerModules.SlimeModule.SlimeCombat)

local attackRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("WeaponAttack") :: RemoteEvent
local lastAttacks: {[Player]: {[string]: number}} = {}

local function getEquippedTool(player: Player, weaponName: string): Tool?
	local character = player.Character
	if not character then return nil end

	local tool = character:FindFirstChild(weaponName)
	if tool and tool:IsA("Tool") and tool:GetAttribute("WeaponName") == weaponName then
		return tool
	end
	return nil
end

local function playHitSound(tool: Tool)
	local handle = tool:FindFirstChild("Handle")
	local sound = handle and handle:FindFirstChild("HitSound")
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

attackRemote.OnServerEvent:Connect(function(player: Player, weaponName: any, aimPosition: any)
	if typeof(weaponName) ~= "string" then return end

	local info = WeaponsModule:GetInfo(weaponName)
	local tool = getEquippedTool(player, weaponName)
	if not info or not tool or not WeaponsModule:IsSelected(player, weaponName) then return end

	local now = os.clock()
	local cooldowns = lastAttacks[player]
	if not cooldowns then
		cooldowns = {}
		lastAttacks[player] = cooldowns
	end
	if now - (cooldowns[weaponName] or 0) < info.Cooldown then return end
	cooldowns[weaponName] = now

	local character = player.Character
	if not character then return end

	if info.Type == "Melee" then
		local hitSomething = false
		for _, slime in ipairs(Melee.GetHits(character, info.Range, info.Radians)) do
			if SlimeCombat.Damage(slime, info.Damage) then
				hitSomething = true
			end
		end
		if hitSomething then
			playHitSound(tool)
		end
	elseif info.Type == "Projectile" and typeof(aimPosition) == "Vector3" then
		Projectile.Launch(tool, character, aimPosition, info.Range, function(impactPosition)
			local hitSomething = false
			for _, slime in ipairs(Projectile.GetAOEHits(impactPosition, info.Range)) do
				if SlimeCombat.Damage(slime, info.Damage) then
					hitSomething = true
				end
			end
			if hitSomething and tool.Parent then
				playHitSound(tool)
			end
		end)
	end
end)

local function loadWeapons(player: Player)
	task.spawn(function()
		WeaponsModule:LoadSelectedTools(player)
	end)
end

local function playerAdded(player: Player)
	loadWeapons(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		loadWeapons(player)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
	lastAttacks[player] = nil
end)
