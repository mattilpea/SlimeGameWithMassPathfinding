local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local SlimeDirector = require(ServerScriptService.ServerModules.SlimeModule.SlimeDirector)

local map = ServerStorage.Maps.MapName.Map1
map.Parent = workspace.CurrentMap

local FLOWFIELD_REFRESH_RATE = 0.5
local ARRIVAL_RADIUS = 1

local Targets = {
	--workspace.Targets.Target1,
	--workspace.Targets.Target2,
	--workspace.Targets.Target3,
}

local PlayerTargets = {}

local function addPlayerTarget(player: Player)
	local function onCharacterAdded(character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 5)

		if root then
			PlayerTargets[player] = root
			table.insert(Targets, root)
		end
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
end

local function removePlayerTarget(player: Player)
	local targetPart = PlayerTargets[player]

	if targetPart then
		local index = table.find(Targets, targetPart)

		if index then
			table.remove(Targets, index)
		end
	end

	PlayerTargets[player] = nil
end

for _, player in ipairs(Players:GetPlayers()) do
	addPlayerTarget(player)
end

Players.PlayerAdded:Connect(addPlayerTarget)
Players.PlayerRemoving:Connect(removePlayerTarget)

local director = SlimeDirector.new()

director:AddGroup(
	map,
	ServerStorage.Maps.MapName.NavGrids.Normal_Slime,
	Targets,
	{
		"Fire Slime",
		"Normal Slime",
	},
	FLOWFIELD_REFRESH_RATE,
	ARRIVAL_RADIUS
)

director:Start()

director:SpawnSlimesEqually("Fire Slime", 100, workspace.point.Position)
director:SpawnSlimesEqually("Normal Slime", 100, workspace.point.Position)